#version 300 es

precision mediump float;
uniform vec3 lightPos;
uniform vec3 eyePos;
in vec4 color;
in vec3 fragModel;
in vec3 transfNormal;
out vec4 fragColor;

void main() {
    vec4 specComponent = vec4(0.15,0.15,0.15,1); //Ks
    vec4 diffuseComponent = vec4(0.02,0.02,0.02,1); //Kd
    vec4 ambientComponent = color; //Ka
    vec3 eyeDir = normalize (eyePos-fragModel);
    vec3 lightDir = normalize (lightPos-fragModel);
    float diff = max(dot(lightDir,transfNormal), 0.0);
    vec3 refl = reflect(-lightDir,transfNormal);
    float spec = pow( max(dot(eyeDir,refl), 0.0), 5.0);
    fragColor = ambientComponent + diff*diffuseComponent + spec*specComponent;
}