#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform sampler2D u_gb0;
uniform sampler2D u_gb1;
uniform sampler2D u_gb2;
uniform float u_Time;
uniform vec4 u_MousePos;
uniform float u_Beat;

#define BIAS 0.7
#define COUNT 32
#define RADIUS 0.1

#define PI 3.1415926


float fade (float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); 
}

vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq ){
	float unit = 1000.0/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*noise(p, f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}

vec2 snoiseVec2( vec2 x ){

  float s  = pNoise(vec2( x ), 2);
  float s1 = pNoise(vec2( x.y - 19.1 , x.x + 47.2 ), 2);
  vec2 c = vec2( s , s1 );
  return c;
}
vec2 curlNoise( vec2 p ){
  
  const float e = 5.0;
  vec2 dx = vec2( e   , 0.0);
  vec2 dy = vec2( 0.0 , e  );

  float p_x0 = snoise( p - dx );
  float p_x1 = snoise( p + dx );
  float p_y0 = snoise( p - dy );
  float p_y1 = snoise( p + dy );

  const float divisor = 1.0 / ( 2.0 * e );
  return vec2( p_x1 - p_x0 , p_y0 - p_y1) * divisor;

}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

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

	vec3 cols[6];
	cols[0] = vec3(255,113,206); 
	cols[1] = vec3(1,205,254);
	cols[2] = vec3(5,255,161);
	cols[3] = vec3(185,103,255);
	cols[4] = vec3(0,0,255);
	// out_Col = vec4(texture(u_frame, fs_UV + vec2(0.33, 0.0)).r,
	// 							 texture(u_frame, fs_UV + vec2(0.0, -0.33)).g,
	// 							 texture(u_frame, fs_UV + vec2(-0.33, 0.0)).b,
	// 							 1.0);
	vec2 offset = vec2(0.01,0.01);
	vec3 color = texture(u_frame, fs_UV + offset).xyz;
	vec3 vaporCol = texture(u_frame, fs_UV).xyz;
	vec3 basehsv = rgb2hsv(vaporCol);
	float min_dist = 100000.0;
	float luminance = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b + 0.08;
	
	if(texture(u_gb1, fs_UV).w != 1.0) {
	for(int i = 0; i < 5; i++) {
		vec3 pal_col =cols[i]/255.0;
		vec3 hsv_vapor = rgb2hsv(pal_col);
		float dist = abs(hsv_vapor.r - basehsv.r);
		//dist = distance(basecol,pal_col);
		if(dist < min_dist) {
			min_dist = dist;
			vaporCol = mix(vaporCol,cols[i]/255.0,1.0-dist);
			//color =cols[i]/255.0;
		}
	}
	}
	
	luminance = luminance*(1.0/(1.0+luminance)) * 3.0;
	color = vec3(luminance);

	float t = clamp(snoise(vec2(fs_UV.x - float(int(u_Time * 8.0)) * 0.2, fs_UV.y * 3.0 )* 5.0),0.0,1.0 );

	t *= clamp(fade(snoise(vec2(fs_UV.x, fs_UV.y * 3.0 + float(int(u_Time * 8.0)) ) * 100.0)),0.0,1.0 );
	color = mix(color, vaporCol, 1.0 - t );
	//color = vaporCol;
	if(vnorm.w == 1.0) {
		if( mod(fs_UV.x * 10.0, 1.0) < 0.05  ) {
			color = vec3(191,185,255)/255.0;
		}
		if( mod(fs_UV.y * 10.0, 1.0) < 0.05  ) {
			color = vec3(191,185,255)/255.0;
		}
	}

	 out_Col = vec4(color ,1.0);
	 out_Col = vec4(u_MousePos[0],0, 0,0);
	 //out_Col = vec4(vec3(ao) ,1.0);
}
