package me.andrea.motion_tracker.opengl_animation.Engine.openglObjects;

import static android.opengl.GLES20.GL_ARRAY_BUFFER;
import static android.opengl.GLES20.GL_ELEMENT_ARRAY_BUFFER;
import static android.opengl.GLES20.GL_INT;
import static android.opengl.GLES20.glDisableVertexAttribArray;
import static android.opengl.GLES20.glEnableVertexAttribArray;
import static android.opengl.GLES20.glVertexAttribPointer;
import static android.opengl.GLES30.glBindVertexArray;
import static android.opengl.GLES30.glDeleteVertexArrays;
import static android.opengl.GLES30.glVertexAttribIPointer;

import android.opengl.GLES30;

import java.util.ArrayList;
import java.util.List;

import javax.microedition.khronos.opengles.GL11;

public class Vao {
	
	private static final int BYTES_PER_FLOAT = 4;
	private static final int BYTES_PER_INT = 4;
	public final int[] id;
	private List<Vbo> dataVbos = new ArrayList<Vbo>();
	private Vbo indexVbo;
	private int indexCount;

	public static Vao create() {
		int[] vaoId = new int[1];
		GLES30.glGenVertexArrays(1, vaoId, 0);
		return new Vao(vaoId);
	}

	private Vao(int[] id) {
		this.id = id;
	}
	
	public int getIndexCount(){
		return indexCount;
	}

	public void bind(int... attributes){
		bind();
		for (int i : attributes) {
			glEnableVertexAttribArray(i);
		}
	}

	public void unbind(int... attributes){
		for (int i : attributes) {
			glDisableVertexAttribArray(i);
		}
		unbind();
	}
	
	public void createIndexBuffer(int[] indices){
		this.indexVbo = Vbo.create(GL_ELEMENT_ARRAY_BUFFER);
		indexVbo.bind();
		indexVbo.storeData(indices);
		this.indexCount = indices.length;
	}

	public void createAttribute(int attribute, float[] data, int attrSize){
		Vbo dataVbo = Vbo.create(GL_ARRAY_BUFFER);
		dataVbo.bind();
		dataVbo.storeData(data);
		glVertexAttribPointer(attribute, attrSize, GL11.GL_FLOAT, false, attrSize * BYTES_PER_FLOAT, 0);
		dataVbo.unbind();
		dataVbos.add(dataVbo);
	}
	
	public void createIntAttribute(int attribute, int[] data, int attrSize){
		Vbo dataVbo = Vbo.create(GL_ARRAY_BUFFER);
		dataVbo.bind();
		dataVbo.storeData(data);
		glVertexAttribIPointer(attribute, attrSize, GL_INT, attrSize * BYTES_PER_INT, 0);
		dataVbo.unbind();
		dataVbos.add(dataVbo);
	}
	
	public void delete() {
		glDeleteVertexArrays(1, id, 0);
		for(Vbo vbo : dataVbos){
			vbo.delete();
		}
		indexVbo.delete();
	}

	private void bind() {
		glBindVertexArray(id[0]);
	}

	private void unbind() {
		glBindVertexArray(0);
	}

}
