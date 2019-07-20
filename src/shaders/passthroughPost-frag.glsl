#version 300 es
precision highp float;

#define NUM_ROWS 200.0
#define NUM_COLS 400.0

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform sampler2D u_gb0;
uniform sampler2D u_gb1;
uniform sampler2D u_gb2;
uniform float u_Time;

// Interpolation between color and greyscale over time on left half of screen
void main() {
	vec3 color = texture(u_frame, fs_UV).xyz;

	out_Col = vec4(color, 1.0);
}
