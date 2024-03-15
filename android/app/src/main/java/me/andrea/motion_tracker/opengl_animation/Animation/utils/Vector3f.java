package me.andrea.motion_tracker.opengl_animation.Animation.utils;

public class Vector3f {
    public float x;
    public float y;
    public float z;

    public Vector3f(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public final float length()
    {
        return (float)
                Math.sqrt(this.x*this.x + this.y*this.y + this.z*this.z);
    }

    public static void add(Vector3f result, Vector3f vector1, Vector3f vector2) {
        result.x = vector1.x + vector2.x;
        result.y = vector1.y + vector2.y;
        result.z = vector1.z + vector2.z;
    }

    public void normalise() {
        float length = (float) Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);

        if (length != 0) {
            this.x /= length;
            this.y /= length;
            this.z /= length;
        }
    }
}
