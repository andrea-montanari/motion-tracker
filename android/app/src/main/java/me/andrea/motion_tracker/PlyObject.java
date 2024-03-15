package me.andrea.motion_tracker;

import android.util.Log;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class PlyObject {

    private float vertices[];
    private int faces[];
    private int countVertices;
    private int countFaces;
    private InputStream inputStream;
    private Map<Integer,String> mapProperties;

    public PlyObject(InputStream inputStream){
        mapProperties = new HashMap<Integer,String>();
        this.inputStream = inputStream;
    }

    public void parse() throws IOException, NumberFormatException {

        BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
        Iterator<String> it = reader.lines().iterator();
        String s;
        String propLines[];

        countVertices = 0;
        countFaces = 0;
        int countProperties = 0;
        boolean doneHeader = false;

        int progressVertices = 0;
        int progressFaces = 0;

        while(it.hasNext()){

            s = it.next();

            if(s.startsWith("comment"))
                continue;

            if(s.contains("element vertex")){
                int index1=s.lastIndexOf("element vertex ");
                if(index1==-1)
                    continue;
                index1+=("element vertex ").length();
                countVertices = Integer.parseInt(s.substring(index1).trim());
                Log.v("PLY_PARSER", "Found " + countVertices + " vertices");
            }
            else if(s.startsWith("property") && countFaces==0){
                propLines = s.split(" ");

                if(propLines[1].contains("list")) //TODO: fix this
                    continue;

                mapProperties.put(countProperties,propLines[2]);
                countProperties++;
            }
            else if(s.contains("element face")){

                if(mapProperties.size()>0){
                    for(int k : mapProperties.keySet())
                        Log.d("PLY_PARSER",
                                "Prop num " + k + " name " + mapProperties.get(k));
                }

                int index1=s.lastIndexOf("element face ");
                if(index1==-1)
                    continue;
                index1+=("element face ").length();;
                countFaces = Integer.parseInt(s.substring(index1).trim());
                Log.v("PLY_PARSER","Found " + countFaces + " faces/triangles");
                faces = new int[countFaces*3]; //we assume triangles
            }
            else if(s.startsWith("end_header")){
                doneHeader = true;
                vertices = new float[countProperties*countVertices];
                continue;
            }

            if(doneHeader){

                propLines = s.split(" ");

                //I am only expecting numbers from now on...
                if(Character.isLetter(propLines[0].charAt(0)))
                    continue;

                if(progressVertices<(countVertices*mapProperties.size())){

                    for(int i=0; i<propLines.length; i++) {
                        vertices[progressVertices+i] = Float.parseFloat(propLines[i]);
                    }
                    progressVertices+=mapProperties.size();
                }
                else if(progressFaces<(countFaces*3)){ //assume always triangles

                    faces[progressFaces] = Integer.parseInt(propLines[1]);
                    faces[progressFaces+1] = Integer.parseInt(propLines[2]);
                    faces[progressFaces+2] = Integer.parseInt(propLines[3]);
                    progressFaces+=3;
                }

            }

        }

        reader.close();
        inputStream.close();

    }

    @Override
    public String toString(){ //still assuming faces must be triangles
        StringBuilder out;

        if(vertices==null || faces==null)
            out = new StringBuilder("Nothing parsed");
        else {
            out = new StringBuilder("\nPrinting Vertices " + countVertices + "->" + vertices.length);
            out.append("\n");

            for (int i = 0; i < vertices.length; i++) {

                if((i%mapProperties.size())==0 )
                    out.append("\n");

                out.append(" "+vertices[i]+" ");

            }

            out.append("\n" + "Printing faces " + countFaces + "->" + faces.length);
            out.append("\n");

            for (int i = 0; i < faces.length; i++) {

                if((i%3)==0)
                    out.append("\n");

                out.append(" "+faces[i]+" ");
            }
        }
        return out.toString();
    }

    public float[] getVertices(){
        return vertices;
    }

    public int[] getIndices() {
        return faces;
    }

    public Map<Integer,String> getMapProperties(){
        return mapProperties;
    }

}
