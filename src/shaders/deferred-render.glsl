#version 300 es
precision highp float;

#define EPS 0.0001
#define PI 3.1415962

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_gb0;
uniform sampler2D u_gb1;
uniform sampler2D u_gb2;

uniform float u_Time;

uniform mat4 u_View;
uniform vec4 u_CamPos;   


void main() { 
	// read from GBuffers
	vec3 lightdir = vec3(1,1,0);
	lightdir = normalize(lightdir);

	vec4 gb0 = texture(u_gb0, fs_UV);
	vec4 gb1 = texture(u_gb1, fs_UV);
	vec4 gb2 = texture(u_gb2, fs_UV);

	float mesh = 0.0;
	if(gb1[3] == 0.0) {
		mesh = 1.0;
	}

	vec3 diffuse = gb2.xyz;
	vec3 normal = gb0.xyz;

	float diffuse_term = clamp(dot(normal,lightdir), 0.0, 1.0);

	diffuse_term += 0.1 * mesh;

	diffuse_term = clamp(diffuse_term, 0.0, 1.0);

	vec3 col = diffuse * diffuse_term;
	

	out_Col = vec4((col.xyz), 1.0);
}