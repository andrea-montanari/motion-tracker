package me.andrea.motion_tracker.opengl_animation.Animation.utils;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;

public class BufferUtils {
    public static FloatBuffer allocFloatBuffer(float[] data) {
        FloatBuffer fbData = ByteBuffer.allocateDirect(data.length * Float.BYTES).
                order(ByteOrder.nativeOrder())
                .asFloatBuffer();

        fbData.put(data);
        fbData.position(0);
        return fbData;
    }

    public static IntBuffer allocIntBuffer(int[] data) {
        IntBuffer intData =
                ByteBuffer.allocateDirect(data.length * Integer.BYTES)
                        .order(ByteOrder.nativeOrder())
                        .asIntBuffer();
        intData.put(data);
        intData.position(0);
        return intData;
    }
}
