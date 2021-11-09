#version 330 core
out vec3 vColor;

layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inCol;

void main() {
    gl_Position = vec4(inPos, 1.0);
    vColor = inCol;
}