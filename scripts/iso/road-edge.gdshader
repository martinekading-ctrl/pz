shader_type canvas_item;
uniform vec2 road_points[4];
uniform int road_count = 2;
uniform float half_width = 70.0;
varying vec2 ground_position;

void vertex() { ground_position = VERTEX; }
void fragment() {
	float distance_to_road = 100000.0;
	for (int i=0; i<3; i++) {
		if (i >= road_count-1) { break; }
		vec2 segment = road_points[i+1]-road_points[i];
		float fraction = clamp(dot(ground_position-road_points[i],segment)/dot(segment,segment),0.0,1.0);
		distance_to_road = min(distance_to_road,length(ground_position-road_points[i]-segment*fraction));
	}
	float grain = texture(TEXTURE,UV*1.37).r;
	COLOR.a *= 1.0-smoothstep(half_width-12.0+grain*5.0,half_width,distance_to_road);
}
