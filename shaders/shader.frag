#version 450

layout(location = 0) in vec3 fragColour;
layout(location = 1) in vec2 fragUV;

layout(location = 0) out vec4 outColour;

void main() {
	outColour = vec4(fragColour.r + fragUV.x, fragColour.g + fragUV.y, fragColour.b, 1.0);
}
