package me.andrea.motion_tracker.opengl_animation.Animation.utils;

public class FrameManager {
    private static Long lastFrameTime = null;
    private static float delta;
    public static void update() {
        if (lastFrameTime == null) {
            lastFrameTime = System.currentTimeMillis();
        }
        long currentFrameTime = System.currentTimeMillis();
        delta = (currentFrameTime - lastFrameTime) / 1000f;
        lastFrameTime = currentFrameTime;
    }

    public static float getFrameTime() {
        return delta;
    }
}
