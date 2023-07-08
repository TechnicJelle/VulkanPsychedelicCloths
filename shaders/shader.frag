#version 450

#define PI 3.1415926535897932384626433832795

layout(binding = 0) uniform UniformBufferOvject {
	float time;
	vec2 mouse;
	vec2 windowSize;

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

layout(location = 0) in vec3 fragColour;
layout(location = 1) in vec2 fragUV;
layout(location = 2) flat in int fragInstanceIndex;

layout(location = 0) out vec4 outColour;

vec2 rotateUV(vec2 uv, float rotation, vec2 mid)
{
	return vec2(
		cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x,
		cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y
	);
}

float map(float val, float inLow, float inHigh, float outLow, float outHigh)
{
	return outLow + (outHigh - outLow) * ((val - inLow) / (inHigh - inLow));
}

float periodicTime(float speed) {
	return map(sin(ubo.time * speed), -1.0, 1.0, 0.0, 1.0);
}

vec3 checkers() {
	vec2 rotatedUV = rotateUV(fragUV, ubo.time * ubo.checker_rotationSpeed, vec2(0.5));
	float timeScale = map(periodicTime(ubo.checker_rotationSpeed), 0, 1, ubo.checker_scale.x, ubo.checker_scale.y);
	float timeOffset = -timeScale / 2;
	float x = rotatedUV.x * timeScale + timeOffset;
	float y = rotatedUV.y * timeScale + timeOffset;

	int total = int(floor(x) + floor(y));
	bool isEven = mod(total+1, 2) == 0;

	vec3 col1 = vec3(0.0, 0.0, 0.0);
	vec3 col2 = vec3(1.0, 1.0, 1.0);

	return (isEven) ? col1 : col2;
}

vec2 st = gl_FragCoord.xy / ubo.windowSize;
float lighting() {
	vec2 toMouse = ubo.mouse.xy / ubo.windowSize - st;
	return length(toMouse);
}

void main() {
	vec3 checker = checkers();
	float light = (1-pow(lighting() / ubo.light_radiusFactor, ubo.light_falloff)) * ubo.light_strength;

	outColour = vec4(fragColour + checker * clamp(light, ubo.light_minimum, 1.0), 1);
}
