#version 450

#define PI 3.1415926535897932384626433832795

layout(binding = 0) uniform UniformBufferOvject {
	float time;
	vec2 mouse;
	vec2 windowSize;

	float plane_orbitSpeed;

	float noise_scale;
	float noise_intensity;
	float noise_speed;

	vec2 checker_scale;
	float checker_rotationSpeed;

	int radial_slices;

	float light_radiusFactor;
	float light_falloff;
	float light_strength;
	float light_minimum;
} ubo;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColour;
layout(location = 2) in vec2 inUV;

layout(location = 0) out vec3 fragColour;
layout(location = 1) out vec2 fragUV;
layout(location = 2) out int fragInstanceIndex;

void main() {
	float instanceTime = ubo.time * ubo.plane_orbitSpeed + gl_InstanceIndex * PI/2;
	vec2 offset = vec2(
		0.5f * cos(instanceTime * -2.0f),
		0.5f * sin(instanceTime * -2.0f)
	);

	vec4 pos = vec4(inPosition, 1);
	vec4 pos_timeOffset = vec4(offset, 0, 0);
	gl_Position = pos + pos_timeOffset;

	fragColour = inColour;
	fragUV = inUV;
	fragInstanceIndex = gl_InstanceIndex;
}
