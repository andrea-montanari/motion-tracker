package me.andrea.motion_tracker.opengl_animation.ColladaParser.colladaLoader;

import android.opengl.Matrix;
import android.util.Log;

import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.AnimationData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.JointTransformData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.KeyFrameData;

import java.util.Arrays;
import java.util.List;

import me.andrea.motion_tracker.opengl_animation.ColladaParser.xmlParser.XmlNode;

public class AnimationLoader {
	private static final int rotationAngle = -90;
	private static float[] CORRECTION = new float[16];
	
	private XmlNode animationData;
	private XmlNode jointHierarchy;
	
	public AnimationLoader(XmlNode animationData, XmlNode jointHierarchy){
		this.animationData = animationData;
		this.jointHierarchy = jointHierarchy;
		// Set matrix to correct rotation from Blender coordinate system to Android's
		Matrix.setIdentityM(CORRECTION, 0);
		Matrix.rotateM(CORRECTION, 0, rotationAngle, 1, 0, 0);
	}
	
	public AnimationData extractAnimation(){
		String rootNode = findRootJointName();
		float[] times = getKeyTimes();
		float duration = times[times.length-1];
		KeyFrameData[] keyFrames = initKeyFrames(times);
		List<XmlNode> animationNodes = animationData.getChild("animation").getChildren("animation");
		for(XmlNode jointNode : animationNodes){
			loadJointTransforms(keyFrames, jointNode, rootNode);
		}
		return new AnimationData(duration, keyFrames);
	}
	
	private float[] getKeyTimes(){
		XmlNode timeData = animationData.getChild("animation").getChild("animation").getChild("source").getChild("float_array");
		String[] rawTimes = timeData.getData().split(" ");
		float[] times = new float[rawTimes.length];
		for(int i=0;i<times.length;i++){
			times[i] = Float.parseFloat(rawTimes[i]);
		}
		return times;
	}
	
	private KeyFrameData[] initKeyFrames(float[] times){
		KeyFrameData[] frames = new KeyFrameData[times.length];
		for(int i=0;i<frames.length;i++){
			frames[i] = new KeyFrameData(times[i]);
		}
		return frames;
	}
	
	private void loadJointTransforms(KeyFrameData[] frames, XmlNode jointData, String rootNodeId){
		String jointNameId = getJointName(jointData);
		String dataId = getDataId(jointData);
		XmlNode transformData = jointData.getChildWithAttribute("source", "id", dataId);
		String[] rawData = transformData.getChild("float_array").getData().split(" ");
		Log.v("AnimationLoader", "Joint id: " + jointNameId);
		Log.v("AnimationLoader", "Joint data id: " + dataId);
		Log.v("AnimationLoader", "Joint animation output: " + Arrays.toString(rawData));
		processTransforms(jointNameId, rawData, frames, jointNameId.equals(rootNodeId));
	}
	
	private String getDataId(XmlNode jointData){
		XmlNode node = jointData.getChild("sampler").getChildWithAttribute("input", "semantic", "OUTPUT");
		return node.getAttribute("source").substring(1);
	}
	
	private String getJointName(XmlNode jointData){
		XmlNode channelNode = jointData.getChild("channel");
		String data = channelNode.getAttribute("target");
		return data.split("/")[0];
	}
	
	private void processTransforms(String jointName, String[] rawData, KeyFrameData[] keyFrames, boolean root){
		float[] matrixData = new float[16];
		for(int i=0;i<keyFrames.length;i++){
			for(int j=0;j<16;j++){
				matrixData[j] = Float.parseFloat(rawData[i*16 + j]);
			}
			float[] transform = new float[16];
			Log.v("AnimationLoader", "MatrixData: " + Arrays.toString(matrixData));
			Matrix.transposeM(transform, 0, matrixData, 0);
			float[] transformCorrectionResult = Arrays.copyOf(transform, transform.length);
			if(root){
				//because up axis in Blender is different to up axis in game
				Matrix.multiplyMM(transformCorrectionResult, 0, CORRECTION, 0, transform, 0);
			}
			keyFrames[i].addJointTransform(new JointTransformData(jointName, transformCorrectionResult));
		}
	}

//	private void processTransforms(String jointName, String[] rawData, KeyFrameData[] keyFrames, boolean root){
//		FloatBuffer buffer = ByteBuffer.allocateDirect(16 * Float.BYTES).
//				order(ByteOrder.nativeOrder())
//				.asFloatBuffer();
//		float[] matrixData = new float[16];
//		for(int i=0;i<keyFrames.length;i++){
//			for(int j=0;j<16;j++){
//				matrixData[j] = Float.parseFloat(rawData[i*16 + j]);
//			}
//			Log.v("AnimationLoader", "MatrixData: " + Arrays.toString(matrixData));
//			buffer.clear();
//			buffer.put(matrixData);
//			buffer.flip();
//			float[] transform = new float[16];
//			buffer.get(transform);
//			Matrix.transposeM(transform, 0, matrixData, 0);
//			if(root){
//				//because up axis in Blender is different to up axis in game
//				Matrix.multiplyMM(transform, 0, CORRECTION, 0, transform, 0);
//			}
//			keyFrames[i].addJointTransform(new JointTransformData(jointName, transform));
//		}
//	}
	
	private String findRootJointName(){
		XmlNode skeleton = jointHierarchy.getChild("visual_scene").getChildWithAttribute("node", "id", "Armature");
		return skeleton.getChild("node").getAttribute("id");
	}


}
