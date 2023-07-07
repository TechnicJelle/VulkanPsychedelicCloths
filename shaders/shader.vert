#version 450

layout(binding = 0) uniform UniformBufferOvject {
	mat4 model;
	mat4 view;
	mat4 proj;
} ubo;

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec3 inColour;

layout(location = 0) out vec3 fragColour;

void main() {
	vec2 pos = inPosition + vec2(0, gl_InstanceIndex * 2 - 1);
	gl_Position = ubo.proj * ubo.view * ubo.model * vec4(pos, 0.0, 1.0);
	fragColour = inColour;
}
