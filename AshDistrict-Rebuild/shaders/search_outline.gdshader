shader_type canvas_item;

uniform float glow : hint_range(0.0,1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.78,0.95,0.57,0.82);
uniform float desaturate : hint_range(0.0,1.0) = 0.0;
uniform vec4 color_grade : source_color = vec4(1.0);

void fragment() {
	vec4 base = texture(TEXTURE,UV);
	float value = dot(base.rgb,vec3(0.299,0.587,0.114));
	base.rgb = mix(base.rgb,vec3(value),desaturate)*color_grade.rgb;
	float nearby = 0.0;
	vec2 px = TEXTURE_PIXEL_SIZE * 10.0;
	nearby = max(nearby,texture(TEXTURE,UV+vec2(px.x,0.0)).a);
	nearby = max(nearby,texture(TEXTURE,UV-vec2(px.x,0.0)).a);
	nearby = max(nearby,texture(TEXTURE,UV+vec2(0.0,px.y)).a);
	nearby = max(nearby,texture(TEXTURE,UV-vec2(0.0,px.y)).a);
	float edge = smoothstep(0.08,0.42,nearby) * (1.0-smoothstep(0.02,0.18,base.a));
	float inner = min(min(texture(TEXTURE,UV+vec2(px.x,0.0)).a,texture(TEXTURE,UV-vec2(px.x,0.0)).a),min(texture(TEXTURE,UV+vec2(0.0,px.y)).a,texture(TEXTURE,UV-vec2(0.0,px.y)).a));
	edge = max(edge,base.a*(1.0-inner));
	COLOR = vec4(mix(base.rgb,glow_color.rgb,edge*glow),max(base.a,edge*glow*glow_color.a))*COLOR;
}
