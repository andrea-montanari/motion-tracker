package me.andrea.motion_tracker.opengl_animation.main;

import me.andrea.motion_tracker.opengl_animation.Animation.utils.MyFile;
import me.andrea.motion_tracker.opengl_animation.Animation.utils.Vector3f;

/**
 * Just some configs. File locations mostly.
 * 
 * @author Karl
 *
 */
public class GeneralSettings {
	
	public static final MyFile RES_FOLDER = new MyFile("res");
	public static final MyFile ASSETS_FOLDER = new MyFile("assets");
	public static final String MODEL_FILE = "humanoid_rigged.dae";
	public static final String ANIM_FILE = "humanoid_rigged.dae";
	public static final String DIFFUSE_FILE = "diffuse.png";
	
	public static final int MAX_WEIGHTS = 3;
	
	public static final Vector3f LIGHT_DIR = new Vector3f(0.2f, -0.3f, -0.8f);
	
}
