package me.andrea.motion_tracker.utils;

import me.andrea.motion_tracker.opengl_animation.Animation.utils.MyFile;
import me.andrea.motion_tracker.opengl_animation.Animation.utils.Vector3f;

/**
 * Just some configs. File locations mostly.
 * 
 * @author Karl
 *
 */
public class GeneralSettings {
	
	public static final String MODEL_FILE = "humanoid_rigged.dae";
	public static final String ANIM_LEFT_LEG_FILE = "humanoid_anim_left_leg.dae";
	public static final String ANIM_RIGHT_LEG_FILE = "humanoid_anim_right_leg.dae";
	public static final String VERTEX_SHADER = "humanWithLight_vs.glsl";
	public static final String FRAGMENT_SHADER = "humanWithLight_fs.glsl";

	public static final int MAX_WEIGHTS = 3;
	
	public static final Vector3f LIGHT_DIR = new Vector3f(0.2f, -0.3f, -0.8f);
	
}
