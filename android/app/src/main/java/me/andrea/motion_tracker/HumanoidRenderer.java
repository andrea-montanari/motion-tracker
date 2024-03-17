package me.andrea.motion_tracker;

import static android.opengl.GLES11.glDrawElements;
import static android.opengl.GLES20.GL_ARRAY_BUFFER;
import static android.opengl.GLES20.GL_BACK;
import static android.opengl.GLES20.GL_CCW;
import static android.opengl.GLES20.GL_COLOR_BUFFER_BIT;
import static android.opengl.GLES20.GL_CULL_FACE;
import static android.opengl.GLES20.GL_DEPTH_BUFFER_BIT;
import static android.opengl.GLES20.GL_DEPTH_TEST;
import static android.opengl.GLES20.GL_ELEMENT_ARRAY_BUFFER;
import static android.opengl.GLES20.GL_FLOAT;
import static android.opengl.GLES20.GL_INT;
import static android.opengl.GLES20.GL_LEQUAL;
import static android.opengl.GLES20.GL_STATIC_DRAW;
import static android.opengl.GLES20.GL_TRIANGLES;
import static android.opengl.GLES20.GL_UNSIGNED_INT;
import static android.opengl.GLES20.glBindBuffer;
import static android.opengl.GLES20.glBufferData;
import static android.opengl.GLES20.glClear;
import static android.opengl.GLES20.glClearColor;
import static android.opengl.GLES20.glCullFace;
import static android.opengl.GLES20.glDepthFunc;
import static android.opengl.GLES20.glEnable;
import static android.opengl.GLES20.glEnableVertexAttribArray;
import static android.opengl.GLES20.glFrontFace;
import static android.opengl.GLES20.glGenBuffers;
import static android.opengl.GLES20.glGetBufferParameteriv;
import static android.opengl.GLES20.glGetUniformLocation;
import static android.opengl.GLES20.glUniform1fv;
import static android.opengl.GLES20.glUniform3fv;
import static android.opengl.GLES20.glUniform4fv;
import static android.opengl.GLES20.glUniformMatrix4fv;
import static android.opengl.GLES20.glUseProgram;
import static android.opengl.GLES20.glVertexAttribPointer;
import static android.opengl.GLES30.glVertexAttribIPointer;

import static me.andrea.motion_tracker.opengl_animation.Animation.loaders.AnimatedModelLoader.createJoints;

import android.annotation.SuppressLint;
import android.opengl.GLES30;
import android.opengl.Matrix;
import android.os.Build;
import android.util.Log;

import me.andrea.motion_tracker.opengl_animation.Animation.animatedModel.AnimatedModel;
import me.andrea.motion_tracker.opengl_animation.Animation.animatedModel.Joint;
import me.andrea.motion_tracker.opengl_animation.Animation.animation.Animation;
import me.andrea.motion_tracker.opengl_animation.Animation.loaders.AnimationLoader;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.colladaLoader.ColladaLoader;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.AnimatedModelData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.SkeletonData;
import me.andrea.motion_tracker.opengl_animation.main.GeneralSettings;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.util.ArrayList;
import java.util.List;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;


public class HumanoidRenderer extends BasicRenderer {
    private boolean UNBIND_VAO = false;
    private boolean UNBIND_PROGRAM = false;

    private int MAX_JOINTS = 50;

    private static String TAG;
    private int VAO[];
    private Vao vao;
    private int VBO[];
    private int shaderHandle;
    private int MVPloc;
    private int umodelM;
    private int uJointTransforms;
    private int uProjectionViewMatrix;

    private static final boolean USE_VAO = true;
    private int countFacesToElement;
    private float angle;

    private float[] viewM;
    private float[] modelM;
    private float[] projM;

    private float[] lightPos;
    private int uLightPos;
    private int uInverseModel;
    private float[][] jointTransforms = null;
    private float[] eyePos;
    private int uEyePos;

    private float MVP[];
    private float temp[];
    private float inverseModel[];

    private AnimatedModelData humanoidModel;
    private AnimatedModel humanoidAnimatedModel;
    private Animation animationRightLeg;
    private Animation animationLeftLeg;
    private boolean animate;


    public HumanoidRenderer() {
        super();
        TAG = this.getClass().getSimpleName();

        viewM = new float[16];
        modelM = new float[16];
        projM = new float[16];
        MVP = new float[16];
        temp = new float[16];
        eyePos = new float[]{0f,0f,45f};
        lightPos = new float[]{0f,15f,20f};
        inverseModel = new float[16];
        jointTransforms = new float[MAX_JOINTS][16];
        Matrix.setIdentityM(inverseModel, 0);
        Matrix.setIdentityM(viewM, 0);
        Matrix.setIdentityM(modelM, 0);
        Matrix.setIdentityM(projM, 0);
        Matrix.setIdentityM(temp, 0);
    }

    private FloatBuffer allocFloatBuffer(float[] data) {
        FloatBuffer fbData = ByteBuffer.allocateDirect(data.length * Float.BYTES).
                order(ByteOrder.nativeOrder())
                .asFloatBuffer();

        fbData.put(data);
        fbData.position(0);
        return fbData;
    }

    private IntBuffer allocIntBuffer(int[] data) {
        IntBuffer fbData = ByteBuffer.allocateDirect(data.length * Integer.BYTES).
                order(ByteOrder.nativeOrder())
                .asIntBuffer();

        fbData.put(data);
        fbData.position(0);
        return fbData;
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public void onSurfaceCreated(GL10 gl10, EGLConfig eglConfig) {

        super.onSurfaceCreated(gl10, eglConfig);
        InputStream isV;
        InputStream isF;

        try {
            isV = context.getAssets().open("humanWithLight_vs.glsl");
            isF = context.getAssets().open("humanWithLight_fs.glsl");
            shaderHandle = ShaderCompiler.createProgram(isV, isF);
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(-1);
        }

        if (shaderHandle == -1)
            System.exit(-1);



        humanoidModel = null;
        try {
            humanoidModel = ColladaLoader.loadColladaModel("humanoid_rigged.dae", GeneralSettings.MAX_WEIGHTS, context);
            // Load animation data
            animationRightLeg = AnimationLoader.loadAnimation("humanoid_anim_right_leg.dae", context);
            animationLeftLeg = AnimationLoader.loadAnimation("humanoid_anim_left_leg.dae", context);
        } catch (Exception ex) {
            Log.e(TAG, "Error in Collada file loading: " + ex);
        }

        IntBuffer indexData =
                ByteBuffer.allocateDirect(humanoidModel.getMeshData().getIndices().length * Integer.BYTES)
                        .order(ByteOrder.nativeOrder())
                        .asIntBuffer();
        indexData.put(humanoidModel.getMeshData().getIndices());
        indexData.position(0);
        countFacesToElement = indexData.capacity();

        float[] colors = new float[humanoidModel.getMeshData().getVertices().length];
        for (int i=0; i<humanoidModel.getMeshData().getVertices().length; i++) {
            colors[i] = 0.0f;
        }

        FloatBuffer colorData = allocFloatBuffer(colors);
        FloatBuffer vertexData = allocFloatBuffer(humanoidModel.getMeshData().getVertices());
        FloatBuffer normalsData = allocFloatBuffer(humanoidModel.getMeshData().getNormals());
        IntBuffer jointIds = allocIntBuffer(humanoidModel.getMeshData().getJointIds());
        FloatBuffer vertexWeights = allocFloatBuffer(humanoidModel.getMeshData().getVertexWeights());

        MVPloc = glGetUniformLocation(shaderHandle, "MVP");
        umodelM = glGetUniformLocation(shaderHandle, "modelMatrix");
        uInverseModel = glGetUniformLocation(shaderHandle,"inverseModel");
        uLightPos = glGetUniformLocation(shaderHandle,"lightPos");
        uEyePos = glGetUniformLocation(shaderHandle,"eyePos");
        uJointTransforms = glGetUniformLocation(shaderHandle,"jointTransforms");
        uProjectionViewMatrix = glGetUniformLocation(shaderHandle,"projectionViewMatrix");

        int[] vertices2 = humanoidModel.getMeshData().getJointIds();

        VBO = new int[6];
        glGenBuffers(6, VBO, 0);

        vao = new Vao();
        vao.bind();

        glBindBuffer(GL_ARRAY_BUFFER, VBO[0]);
        glBufferData(GL_ARRAY_BUFFER, Float.BYTES * vertexData.capacity(),
                vertexData, GL_STATIC_DRAW);
        glVertexAttribPointer(1, 3, GL_FLOAT, false, 3*Float.BYTES, 0); // vPos
        glEnableVertexAttribArray(1);

        glBindBuffer(GL_ARRAY_BUFFER, VBO[1]);
        glBufferData(GL_ARRAY_BUFFER, Float.BYTES * normalsData.capacity(),
                normalsData, GL_STATIC_DRAW);
        glVertexAttribPointer(2, 3, GL_FLOAT, false, 3*Float.BYTES, 0); // normals
        glEnableVertexAttribArray(2);

        glBindBuffer(GL_ARRAY_BUFFER, VBO[2]);
        glBufferData(GL_ARRAY_BUFFER, Float.BYTES * colorData.capacity(),
                colorData, GL_STATIC_DRAW);
        glVertexAttribPointer(3, 3, GL_FLOAT, false, 3*Float.BYTES, 0);
        glEnableVertexAttribArray(3);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, VBO[3]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, Integer.BYTES * indexData.capacity(), indexData,
                GL_STATIC_DRAW);

        glBindBuffer(GL_ARRAY_BUFFER, VBO[4]);
        glBufferData(GL_ARRAY_BUFFER, Integer.BYTES * jointIds.capacity(),
                jointIds, GL_STATIC_DRAW);
        glVertexAttribIPointer(4, 3, GL_INT, 3*Integer.BYTES, 0);
        glEnableVertexAttribArray(4);

        glBindBuffer(GL_ARRAY_BUFFER, VBO[5]);
        glBufferData(GL_ARRAY_BUFFER, Float.BYTES * vertexWeights.capacity(),
                vertexWeights, GL_STATIC_DRAW);
        glVertexAttribPointer(5, 3, GL_FLOAT, false, 3*Float.BYTES, 0);
        glEnableVertexAttribArray(5);

        glBindBuffer(GL_ARRAY_BUFFER,0);
        vao.unbind();


        // Create Animated Model
        SkeletonData skeletonData = humanoidModel.getJointsData();
        Joint headJoint = createJoints(skeletonData.headJoint);
        humanoidAnimatedModel = new AnimatedModel(
                vao,
                headJoint,
                skeletonData.jointCount
        );
        jointTransforms = humanoidAnimatedModel.getJointTransforms();


        // Pre load uniform values
        glUseProgram(shaderHandle);
        glUniform3fv(uLightPos,1,lightPos,0);
        glUniform3fv(uEyePos,1,eyePos,0);
        glUseProgram(0);

        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);

        glEnable(GL_CULL_FACE);
        glCullFace(GL_BACK);
        glFrontFace(GL_CCW);

    }

    public void activateAnimation(String animationName) {
        if (!humanoidAnimatedModel.isAnimating()) {
            switch (animationName) {
                case "left ankle":
                    humanoidAnimatedModel.doAnimation(animationLeftLeg);
                    break;
                case "right ankle":
                    humanoidAnimatedModel.doAnimation(animationRightLeg);
                    break;
            }
        }
    }

    @Override
    public void onSurfaceChanged(GL10 gl10, int w, int h) {
        super.onSurfaceChanged(gl10, w, h);

        // View Space
        float aspect = ((float) w) / ((float) (h == 0 ? 1 : h));
        Matrix.perspectiveM(projM, 0, 4f, aspect, 0.1f, 100f);
        Matrix.setLookAtM(viewM, 0, eyePos[0], eyePos[1], eyePos[2],
                0, 0, 0,
                0, 1, 0);

        // World/Model Space
        Matrix.translateM(modelM, 0, 0, -1, 0);
        Matrix.multiplyMM(temp, 0, projM, 0, viewM, 0);
        Matrix.multiplyMM(MVP, 0, temp, 0, modelM, 0);

        // Lighting
        Matrix.invertM(inverseModel, 0,modelM,0);
    }

    @Override
    public void onDrawFrame(GL10 gl10) {
        glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glUseProgram(shaderHandle);
        vao.bind();

        humanoidAnimatedModel.update();

        // Send MVP and lighting transformations
        glUniformMatrix4fv(MVPloc, 1, false, MVP, 0);
        glUniformMatrix4fv(uInverseModel,1,true,inverseModel,0);

        // Retrieve and send joint transformations for animation
        jointTransforms = humanoidAnimatedModel.getJointTransforms();
        int jointsNumber = humanoidModel.getJointsData().jointCount;
        float[] flattenedArray = new float[jointsNumber * 16]; // Assuming each transform is 4x4 matrix
        for (int i = 0; i < jointsNumber; i++) {
            for (int j = 0; j < 16; j++) {
                flattenedArray[i * 16 + j] = jointTransforms[i][j];
            }
        }
        glUniformMatrix4fv(uJointTransforms,jointsNumber,false, flattenedArray,0);

        // Drawcall
        glDrawElements(GL_TRIANGLES, countFacesToElement,  GL_UNSIGNED_INT, 0);

        if (UNBIND_VAO) {
            vao.unbind();
        }
        if (UNBIND_PROGRAM) {
            glUseProgram(0);
        }
    }
}
