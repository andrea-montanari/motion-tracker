package me.andrea.motion_tracker.opengl_animation.Engine.openglObjects;

import static android.opengl.GLES20.GL_STATIC_DRAW;
import static android.opengl.GLES20.glBindBuffer;
import static android.opengl.GLES20.glBufferData;
import static android.opengl.GLES20.glGenBuffers;
import static android.opengl.GLES30.glDeleteVertexArrays;

import me.andrea.motion_tracker.opengl_animation.Animation.utils.BufferUtils;

import java.nio.FloatBuffer;
import java.nio.IntBuffer;

public class Vbo {
	
	private final int[] vboId;
	private final int type;
	
	private Vbo(int[] vboId, int type){
		this.vboId = vboId;
		this.type = type;
	}
	
	public static Vbo create(int type){
		int[] bufferId = new int[1];
		glGenBuffers(1, bufferId, 0);
		return new Vbo(bufferId, type);
	}
	
	public void bind(){
		glBindBuffer(type, vboId[0]);
	}
	
	public void unbind(){
		glBindBuffer(type, 0);
	}

	public void storeData(float[] data){
		FloatBuffer buffer = BufferUtils.allocFloatBuffer(data);
		storeData(buffer);
	}

	public void storeData(int[] data){
		IntBuffer buffer = BufferUtils.allocIntBuffer(data);
		storeData(buffer);
	}
	
	public void storeData(IntBuffer data){
		glBufferData(type, Integer.BYTES * data.capacity(),
				data, GL_STATIC_DRAW);
	}
	
	public void storeData(FloatBuffer data){
		glBufferData(type, Float.BYTES * data.capacity(),
				data, GL_STATIC_DRAW);
	}

	public void delete(){
		glDeleteVertexArrays(1, vboId, 0);;
	}

}
