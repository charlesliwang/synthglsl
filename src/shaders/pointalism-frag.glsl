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


vec3 noise_gen3D(vec3 pos) {
    float x = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(12.9898, 78.233, 78.156))) * 43758.5453);
    float y = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(2.332, 14.5512, 170.112))) * 78458.1093);
    float z = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(400.12, 90.5467, 10.222))) * 90458.7764);
    return 2.0 * (vec3(x,y,z) - 0.5);
}

// Interpolation between color and greyscale over time on left half of screen
void main() {
	vec3 color = texture(u_frame, fs_UV).xyz;
	vec3 color2 = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
	float t = sin(3.14 * u_Time) * 0.5 + 0.5;
	t *= 1.0 - step(0.5, fs_UV.x);
	color = mix(color, color2, smoothstep(0.0, 1.0, t));

	color = vec3(1.0);
	for(int i = 0; i < 2; i++) {
		for(int j = 0; j < 2; j++) {
			float u = float(int(fs_UV.x * NUM_COLS) + i )/NUM_COLS;
			float v = float(int(fs_UV.y * NUM_ROWS) + j )/NUM_ROWS;

			u += noise_gen3D(vec3(u,v,u + v)).x * 0.5/NUM_COLS;
			v += noise_gen3D(vec3(u,v,u + v)).y * 0.5/NUM_ROWS;


			vec3 rgb = texture(u_frame, vec2(u,v)).xyz;
			float luminance = 0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b + 0.08;

			float max_dist = length(vec2(1.0/NUM_COLS,1.0/NUM_ROWS)) / 2.0;
			float dist = distance(fs_UV,vec2(u,v)) / max_dist;
			
			if(dist < 1.0/(luminance * 10.0)) {
				color = vec3(0.0);
			}
		}
	}


	out_Col = vec4(color, 1.0);
}
