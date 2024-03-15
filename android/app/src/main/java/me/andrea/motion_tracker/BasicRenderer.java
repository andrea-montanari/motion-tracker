package me.andrea.motion_tracker;

import static android.opengl.GLES10.*;

import android.content.Context;
import android.graphics.Point;
import android.opengl.GLSurfaceView;
import android.os.Build;
import android.util.Log;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class BasicRenderer implements GLSurfaceView.Renderer {

    protected float clearScreen[];
    protected Point currentScreen;
    protected Context context;
    protected GLSurfaceView surface;
    protected static String TAG;

    public BasicRenderer() {
        this(0,0,0);
    }

    public BasicRenderer(float r, float g, float b) {
        this(r,g,b,1);
    }
    public BasicRenderer(float r, float g, float b, float a) {
        TAG = getClass().getSimpleName();
        clearScreen = new float[] {r,g,b,a};
        currentScreen = new Point(0,0);
    }

    public void setContextAndSurface(Context context, GLSurfaceView surface) {
        this.context = context;
        this.surface = surface;
    }

    public Context getContext() {
        return context;
    }

    public GLSurfaceView getSurface() {
        return surface;
    }

    @Override
    public void onSurfaceCreated(GL10 gl10, EGLConfig eglConfig) {
        glClearColor(clearScreen[0], clearScreen[1], clearScreen[2], clearScreen[3]);
        Log.v(TAG,"onSurfaceCreated " + Thread. currentThread().getName());
        Log.v(TAG,glGetString(GL_VERSION));
    }

    @Override
    public void onSurfaceChanged(GL10 gl10, int w, int h) {
        Log. v(TAG,"onSurfaceChanged " + Thread. currentThread().getName() );
        glViewport(0,0,w,h);
        currentScreen.x = w;
        currentScreen.y = h;
    }

    @Override
    public void onDrawFrame(GL10 gl10) {
        glClear(GL_COLOR_BUFFER_BIT);
    }
}
