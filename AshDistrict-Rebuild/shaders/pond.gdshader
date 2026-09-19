shader_type canvas_item;
render_mode unshaded;
void fragment(){
	vec2 p=UV*2.0-1.0;
	float edge=smoothstep(0.6,1.0,length(p));
	float ripple=sin(UV.x*92.0+UV.y*29.0+TIME*0.45)*sin(UV.y*61.0-TIME*0.32);
	vec3 deep=vec3(0.22,0.39,0.40);
	vec3 shallow=vec3(0.46,0.58,0.48);
	COLOR=vec4(mix(deep,shallow,edge)+ripple*0.015,1.0);
}
