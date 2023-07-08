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

// By Morgan McGuire @morgan3d, http://graphicscodex.com
// Reuse permitted under the BSD license.
// https://www.shadertoy.com/view/4dS3Wd
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.13);
	p3 += dot(p3, p3.yzx + 3.333);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
	//			mix(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

vec2 noise2D(in vec2 st) {
	return vec2(noise(st), noise(st + vec2(1.0, 1.0))) * 2.0 - 1.0;
}

void main() {
	float instanceTime = ubo.time * ubo.plane_orbitSpeed + gl_InstanceIndex * PI/2;
	vec2 offset = vec2(
		0.5f * cos(instanceTime * -2.0f),
		0.5f * sin(instanceTime * -2.0f)
	);

	vec2 noise = noise2D((inPosition.xy + ubo.time * ubo.noise_speed)*ubo.noise_scale) * ubo.noise_intensity;

	vec4 pos = vec4(inPosition, 1);
	vec4 pos_timeOffset = vec4(offset, 0, 0);
	vec4 pos_noiseOffset = vec4(noise, 0, 0);
	gl_Position = pos + pos_timeOffset + pos_noiseOffset;

	fragColour = inColour;
	fragUV = inUV;
	fragInstanceIndex = gl_InstanceIndex;
}
