package me.andrea.motion_tracker;

import android.opengl.GLES31;
import android.util.Log;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Iterator;

import static android.opengl.GLES20.GL_COMPILE_STATUS;
import static android.opengl.GLES20.GL_FRAGMENT_SHADER;
import static android.opengl.GLES20.GL_LINK_STATUS;
import static android.opengl.GLES20.GL_VERTEX_SHADER;
import static android.opengl.GLES20.glAttachShader;
import static android.opengl.GLES20.glCompileShader;
import static android.opengl.GLES20.glCreateProgram;
import static android.opengl.GLES20.glCreateShader;
import static android.opengl.GLES20.glDeleteProgram;
import static android.opengl.GLES20.glDeleteShader;
import static android.opengl.GLES20.glDetachShader;
import static android.opengl.GLES20.glGetProgramInfoLog;
import static android.opengl.GLES20.glGetProgramiv;
import static android.opengl.GLES20.glGetShaderInfoLog;
import static android.opengl.GLES20.glGetShaderiv;
import static android.opengl.GLES20.glLinkProgram;
import static android.opengl.GLES20.glShaderSource;


public abstract class ShaderCompiler {

    private static final String TAG = "SHADER_COMPILER";

    public static int createComputeProgram(String src){
        int res = -1;
        final int[] compileStatus = new int[1];

        int handle = compileComputeShader(GLES31.GL_COMPUTE_SHADER,src,compileStatus);

        if(handle<0)
            return res;

        res = GLES31.glCreateProgram();

        GLES31.glAttachShader(res, handle);
        GLES31.glLinkProgram(res);

        int[] linkStatus = new int[1];
        GLES31.glGetProgramiv(res, GL_LINK_STATUS, linkStatus, 0);

        if (linkStatus[0] == 0)
        {
            Log.e(TAG, "Linking error: " + GLES31.glGetProgramInfoLog(res));
            GLES31.glDeleteProgram(res);
            res = 0;
        }

        if(res!=0) {
            Log.v(TAG, "Program compiled and linked successfully in handle " + res);
            GLES31.glDetachShader(res,handle);
            GLES31.glDeleteShader(handle);
        }

        return res;
    }

    public static int createProgram(InputStream isV, InputStream isF) throws IOException {

        BufferedReader reader = new BufferedReader(new InputStreamReader(isV));
        StringBuffer vsSrc = new StringBuffer();

        Iterator<String> it = reader.lines().iterator();
        while( it.hasNext() )
            vsSrc.append(it.next()+"\n");

        isV.close();
        reader.close();

        reader = new BufferedReader(new InputStreamReader(isF));
        StringBuffer fsSrc = new StringBuffer();
        it = reader.lines().iterator();

        while(it.hasNext())
            fsSrc.append(it.next()+"\n");

        isF.close();
        reader.close();

        return createProgram(vsSrc.toString(), fsSrc.toString());

    }

    public static int createProgram(String vertexShader, String fragmentShader){

        int res = -1; //risultato della creazione del programma. E' un handle
        int hVS; //handle del vertex shader
        int hFS; //handle del fragment shader

        final int[] compileStatus = new int[1];

        hVS = compileShader(GL_VERTEX_SHADER, vertexShader, compileStatus);
        if(hVS==-1)
            return res;
        hFS = compileShader(GL_FRAGMENT_SHADER,fragmentShader,compileStatus);
        if(hFS==-1)
            return res;

        res = glCreateProgram();

        if(res!=0){
            glAttachShader(res,hVS);
            glAttachShader(res,hFS);
            glLinkProgram(res);

            int[] linkStatus = new int[1];
            glGetProgramiv(res, GL_LINK_STATUS, linkStatus, 0);

            if (linkStatus[0] == 0)
            {
                Log.e(TAG, "Errore nel linking: " + glGetProgramInfoLog(res));
                glDeleteProgram(res);
                res = 0;
            }
        }

        if(res!=0) {
            Log.v(TAG, "Program compiled successfully in handle " + res);
            glDetachShader(res,hVS);
            glDetachShader(res,hFS);
            glDeleteShader(hVS);
            glDeleteShader(hFS);
        }

        return res;
    }

    private static int compileComputeShader(int shaderStage, String src, int[] compileStatus){
        int handle;

        handle = GLES31.glCreateShader(shaderStage);

        if (handle != 0)
        {

            GLES31.glShaderSource(handle, src);
            GLES31.glCompileShader(handle);

            GLES31.glGetShaderiv(handle, GL_COMPILE_STATUS, compileStatus, 0);

            String shaderType = "Vertex";

            if(shaderStage==GL_FRAGMENT_SHADER)
                shaderType = "Fragment";
            else if(shaderStage==GLES31.GL_COMPUTE_SHADER)
                shaderType = "Compute";

            if (compileStatus[0] == 0)
            {
                Log.e(TAG, "Error in " +
                        shaderType + " shader : "
                        + GLES31.glGetShaderInfoLog(handle));
                GLES31.glDeleteShader(handle);
                return -1;
            }
        }

        return handle;

    }

    private static int compileShader(int shaderStage, String src, int[] compileStatus) {
        int handle;

        handle = glCreateShader(shaderStage);

        if (handle != 0)
        {

            glShaderSource(handle, src);
            glCompileShader(handle);

            glGetShaderiv(handle, GL_COMPILE_STATUS, compileStatus, 0);

            String shaderType = "Vertex";

            if(shaderStage==GL_FRAGMENT_SHADER)
                shaderType = "Fragment";
            else if(shaderStage==GLES31.GL_COMPUTE_SHADER)
                shaderType = "Compute";

            if (compileStatus[0] == 0)
            {
                Log.e(TAG, "Error in " +
                        shaderType + " shader : "
                        + glGetShaderInfoLog(handle));
                glDeleteShader(handle);
                return -1;
            }
        }

        return handle;
    }
}
