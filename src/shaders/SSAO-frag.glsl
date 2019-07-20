#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform sampler2D u_gb0;
uniform sampler2D u_gb1;
uniform sampler2D u_gb2;
uniform float u_Time;

#define BIAS 0.7
#define COUNT 32
#define RADIUS 0.1

//main reference https://www.shadertoy.com/view/4ltSz2

vec3 noise_gen3D(vec3 pos) {
    float x = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(12.9898, 78.233, 78.156))) * 43758.5453);
    float y = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(2.332, 14.5512, 170.112))) * 78458.1093);
    float z = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(400.12, 90.5467, 10.222))) * 90458.7764);
    return 2.0 * (vec3(x,y,z) - 0.5);
}

// Render R, G, and B channels individually
void main() {

	vec4 wnorm = texture(u_gb0, fs_UV);
	vec4 vnorm = texture(u_gb1, fs_UV);
	vec4 gb2 = texture(u_gb2, fs_UV);

	// out_Col = vec4(texture(u_frame, fs_UV + vec2(0.33, 0.0)).r,
	// 							 texture(u_frame, fs_UV + vec2(0.0, -0.33)).g,
	// 							 texture(u_frame, fs_UV + vec2(-0.33, 0.0)).b,
	// 							 1.0);
	float ao = 0.0;
	vec2 uv = vec2(0.0);

	float width = gl_FragCoord.x / fs_UV.x;
	for(int i = 0; i < COUNT; i++) {
		vec2 randUv = (fs_UV + noise_gen3D(vec3(fs_UV + vec2(i, i + 100), fs_UV.x * float(i))).xy / width * 10.0 );
		uv = randUv - fs_UV;
		vec4 randNorm = texture(u_gb1, randUv);
		if(dot(vnorm.xyz, randNorm.xyz) < 0.0)
            randNorm *= -1.0;
		vec2 off = randNorm.xy * RADIUS;
		out_Col.rgb = texture(u_frame, fs_UV).xyz;

		if(texture(u_gb1,fs_UV + off).w == 1.0) {
			ao += 1.0;
			continue;
		}

		float depth_delta = wnorm.w - texture(u_gb0,fs_UV + off).w;

		vec3 sampleDir = vec3(randNorm.xy * RADIUS, depth_delta * 100.0);
		float occ = max(0.0, dot(normalize(vnorm.xyz), normalize(sampleDir)) - BIAS) / (length(sampleDir) + 1.0);
		ao += 1.0 - occ;
	}
	ao /= float(COUNT);

	 out_Col = vec4(texture(u_frame, fs_UV).xyz * (ao) ,1.0);
	 //out_Col = vec4(vec3(ao) ,1.0);
}
