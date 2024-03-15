package me.andrea.motion_tracker.opengl_animation.ColladaParser.colladaLoader;

import android.opengl.Matrix;
import android.util.Log;

import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.JointData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.SkeletonData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.xmlParser.XmlNode;

import java.util.Arrays;
import java.util.List;


public class SkeletonLoader {

	private XmlNode armatureData;
	
	private List<String> boneOrder;
	
	private int jointCount = 0;

	private static final int rotationAngle = -90;
	private static float[] CORRECTION = new float[16];

	public SkeletonLoader(XmlNode visualSceneNode, List<String> boneOrder) {
		this.armatureData = visualSceneNode.getChild("visual_scene").getChildWithAttribute("node", "id", "Armature");
		this.boneOrder = boneOrder;
		// Set matrix to correct rotation from Blender coordinate system to Android's
		Matrix.setIdentityM(CORRECTION, 0);
		Matrix.rotateM(CORRECTION, 0, rotationAngle, 1, 0, 0);
	}
	
	public SkeletonData extractBoneData(){
		XmlNode headNode = armatureData.getChild("node");
		JointData headJoint = loadJointData(headNode, true);
		Log.v("SkeletonLoader", "Head joint name: " + headJoint.nameId);
		return new SkeletonData(jointCount, headJoint);
	}
	
	private JointData loadJointData(XmlNode jointNode, boolean isRoot){
		JointData joint = extractMainJointData(jointNode, isRoot);
		for(XmlNode childNode : jointNode.getChildren("node")){
			joint.addChild(loadJointData(childNode, false));
		}
		return joint;
	}
	
	private JointData extractMainJointData(XmlNode jointNode, boolean isRoot){
		String nameId = jointNode.getAttribute("id");
		String name = nameId.replace("Armature_", "");
		int index = boneOrder.indexOf(name);
		Log.v("SkeletonLoader", "boneOrder length: " + boneOrder.size());
		Log.v("SkeletonLoader", "boneOrder length: " + boneOrder);
		Log.v("SkeletonLoader", "nameId: " + nameId);
		Log.v("SkeletonLoader", "index: " + index);
		String[] matrixData = jointNode.getChild("matrix").getData().split(" ");
		float[] matrix = convertData(matrixData);
		float[] matrixResult = Arrays.copyOf(matrix, matrix.length);
		Matrix.transposeM(matrix, 0, matrix, 0);
		if(isRoot){
			//because in Blender z is up, but in our game y is up.
			Matrix.multiplyMM(matrixResult, 0, CORRECTION, 0, matrix, 0);
		}
		jointCount++;
		Log.v("SkeletonLoader", "jointCount: " + jointCount);
		return new JointData(index, nameId, matrixResult);
	}
	
	private float[] convertData(String[] rawData){
		float[] matrixData = new float[16];
		for(int i=0;i<matrixData.length;i++){
			matrixData[i] = Float.parseFloat(rawData[i]);
		}
		return matrixData;
	}

}
