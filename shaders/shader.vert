#version 450

layout(binding = 0) uniform UniformBufferOvject {
	mat4 model;
	mat4 view;
	mat4 proj;
} ubo;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColour;
layout(location = 2) in vec2 inUV;

layout(location = 0) out vec3 fragColour;
layout(location = 1) out vec2 fragUV;

void main() {
	vec3 pos = inPosition + vec3(gl_InstanceIndex * 2 - 1, 0.0, 0.0);
	gl_Position = ubo.proj * ubo.view * ubo.model * vec4(pos, 1.0);
	fragColour = inColour;
	fragUV = inUV;
}
