package me.andrea.motion_tracker.opengl_animation.Animation.loaders;

import android.content.Context;

import me.andrea.motion_tracker.opengl_animation.Animation.animation.Animation;
import me.andrea.motion_tracker.opengl_animation.Animation.animation.JointTransform;
import me.andrea.motion_tracker.opengl_animation.Animation.animation.KeyFrame;
import me.andrea.motion_tracker.opengl_animation.Animation.animation.Quaternion;
import me.andrea.motion_tracker.opengl_animation.Animation.utils.Vector3f;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.colladaLoader.ColladaLoader;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.AnimationData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.JointTransformData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.KeyFrameData;

import java.util.HashMap;
import java.util.Map;

/**
 * This class loads up an animation collada file, gets the information from it,
 * and then creates and returns an {@link Animation} from the extracted data.
 * 
 * @author Karl
 *
 */
public class AnimationLoader {

	/**
	 * Loads up a collada animation file, and returns and animation created from
	 * the extracted animation data from the file.
	 * 
	 * @param colladaFile
	 *            - the collada file containing data about the desired
	 *            animation.
	 * @return The animation made from the data in the file.
	 */
	public static Animation loadAnimation(String colladaFile, Context context) {
		AnimationData animationData = ColladaLoader.loadColladaAnimation(colladaFile, context);
		KeyFrame[] frames = new KeyFrame[animationData.keyFrames.length];
		for (int i = 0; i < frames.length; i++) {
			frames[i] = createKeyFrame(animationData.keyFrames[i]);
		}
		return new Animation(animationData.lengthSeconds, frames);
	}

	/**
	 * Creates a keyframe from the data extracted from the collada file.
	 * 
	 * @param data
	 *            - the data about the keyframe that was extracted from the
	 *            collada file.
	 * @return The keyframe.
	 */
	private static KeyFrame createKeyFrame(KeyFrameData data) {
		Map<String, JointTransform> map = new HashMap<String, JointTransform>();
		for (JointTransformData jointData : data.jointTransforms) {
			JointTransform jointTransform = createTransform(jointData);
			map.put(jointData.jointNameId, jointTransform);
		}
		return new KeyFrame(data.time, map);
	}

	/**
	 * Creates a joint transform from the data extracted from the collada file.
	 * 
	 * @param data
	 *            - the data from the collada file.
	 * @return The joint transform.
	 */
	private static JointTransform createTransform(JointTransformData data) {
		float[] mat = data.jointLocalTransform;
		Vector3f translation = new Vector3f(mat[12], mat[13], mat[14]);
		Quaternion rotation = Quaternion.fromMatrix(mat);
		return new JointTransform(translation, rotation);
	}

}
