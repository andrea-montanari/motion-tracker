package me.andrea.motion_tracker;

import android.opengl.GLES30;

public class Vao {
    private int[] VAO;

    public Vao() {
        VAO = new int[1];
    }

    public void bind() {
        GLES30.glBindVertexArray(VAO[0]);
    }

    public void unbind() {
        GLES30.glBindVertexArray(0);
    }
}
