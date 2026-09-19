shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 tex = texture(TEXTURE,UV);
	// Lift foliage values at game scale; keep low-alpha ground shadows subdued.
	float leaf = smoothstep(0.45,0.95,tex.a);
	vec3 lifted = clamp(tex.rgb*1.65+vec3(0.075,0.13,0.025),0.0,1.0);
	COLOR = vec4(mix(tex.rgb,lifted,leaf),tex.a);
}
