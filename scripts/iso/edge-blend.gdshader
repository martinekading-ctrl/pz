shader_type canvas_item;

void fragment() {
	vec4 sampled = texture(TEXTURE, UV);
	vec2 pixels = min(UV, vec2(1.0)-UV) / TEXTURE_PIXEL_SIZE;
	float edge = min(pixels.x, pixels.y);
	sampled.a *= smoothstep(0.0, 64.0, edge);
	COLOR = sampled;
}
