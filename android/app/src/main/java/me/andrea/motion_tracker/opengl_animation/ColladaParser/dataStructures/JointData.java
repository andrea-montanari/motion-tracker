package me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures;

import java.util.ArrayList;
import java.util.List;

/**
 * Contains the extracted data for a single joint in the model. This stores the
 * joint's index, name, and local bind transform.
 * 
 * @author Karl
 *
 */
public class JointData {

	public final int index;
	public final String nameId;
	public final float[] bindLocalTransform;

	public final List<JointData> children = new ArrayList<JointData>();

	public JointData(int index, String nameId, float[] bindLocalTransform) {
		this.index = index;
		this.nameId = nameId;
		this.bindLocalTransform = bindLocalTransform;
	}

	public void addChild(JointData child) {
		children.add(child);
	}

}
