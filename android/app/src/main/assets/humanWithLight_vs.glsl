#version 300 es

const int MAX_JOINTS = 50;//max joints allowed in a skeleton
const int MAX_WEIGHTS = 3;//max number of joints that can affect a vertex

layout(location = 1) in vec3 inPosition;
layout(location = 2) in vec3 in_normal;
layout(location = 3) in vec3 aColor;
layout(location = 4) in ivec3 in_jointIndices;
layout(location = 5) in vec3 in_weights;
uniform mat4 MVP;
uniform mat4 modelMatrix;
uniform mat4 inverseModel;
uniform mat4 jointTransforms[MAX_JOINTS];
//uniform mat4 projectionViewMatrix;
out vec3 fragModel;
out vec3 transfNormal;
out vec4 color;

void main() {

    vec4 totalLocalPos = vec4(0.0);
    vec4 totalNormal = vec4(0.0);

    color = vec4(aColor, 1);
     //transf normal
    fragModel = vec3(modelMatrix * vec4(inPosition,1)); //transf vertex pos

    for(int i=0;i<MAX_WEIGHTS;i++){
        mat4 jointTransform = jointTransforms[in_jointIndices[i]];
        vec4 posePosition = jointTransform * vec4(inPosition, 1.0);
//        totalLocalPos += posePosition * in_weights[i];
        totalLocalPos += posePosition * 0.1;

        vec4 worldNormal = jointTransform * vec4(in_normal, 0.0);
        totalNormal += worldNormal * in_weights[i];
    }

//    gl_Position = MVP * vec4(inPosition,1);
//    gl_Position = projectionViewMatrix * totalLocalPos * MVP;
    transfNormal = vec3(inverseModel * vec4(totalNormal.xyz, 1));
    gl_Position = MVP * totalLocalPos;
}
