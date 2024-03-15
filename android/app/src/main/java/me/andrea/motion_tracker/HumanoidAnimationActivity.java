package me.andrea.motion_tracker;

import androidx.appcompat.app.AppCompatActivity;

import android.app.ActivityManager;
import android.content.Context;
import android.content.pm.ConfigurationInfo;
import android.opengl.GLSurfaceView;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

public class HumanoidAnimationActivity extends AppCompatActivity {

    private static String TAG;
    private GLSurfaceView surface;
    private boolean isSurfaceCreated;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        TAG = getClass().getSimpleName();

        // GLES get version
        final ActivityManager activityManager =
                (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        final ConfigurationInfo configurationInfo = activityManager.getDeviceConfigurationInfo();
        int supported = 1;
        if (configurationInfo.reqGlEsVersion >= 0x30000)
            supported = 3;
        else if (configurationInfo.reqGlEsVersion >= 0x20000)
            supported = 2;

        Log.d(TAG, "Opengl ES supported >= " + supported +
                " (" + Integer.toHexString(configurationInfo.reqGlEsVersion) + " " +
                configurationInfo.getGlEsVersion() + ")");

        // GLES context creation
        surface = new GLSurfaceView(this);
        surface.setEGLContextClientVersion(supported);
        surface.setPreserveEGLContextOnPause(true);
//        GLSurfaceView.Renderer renderer = new BasicRenderer(1,0,0);
//        GLSurfaceView.Renderer renderer = new ScissorRenderer();
//        GLSurfaceView.Renderer renderer = new VBOVAORenderer();
        GLSurfaceView.Renderer renderer = new HumanoidRenderer();

        setContentView(surface);
        ((BasicRenderer) renderer).setContextAndSurface(this, surface);
        surface.setRenderer(renderer);
        isSurfaceCreated = true;

//        setContentView(R.layout.activity_main);
    }
}