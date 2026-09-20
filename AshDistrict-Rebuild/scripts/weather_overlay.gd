extends Control

var rain_intensity:=0.0
var fog_intensity:=0.0
var overcast_intensity:=0.0
var animation_time:=0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	process_mode=Node.PROCESS_MODE_ALWAYS

func set_weather(state: Dictionary) -> void:
	rain_intensity=clampf(float(state.get("rain",0.0)),0.0,1.0)
	fog_intensity=clampf(float(state.get("fog",0.0)),0.0,1.0)
	overcast_intensity=clampf(float(state.get("overcast",0.0)),0.0,1.0)
	queue_redraw()

func _process(delta: float) -> void:
	if rain_intensity<=0.005 and fog_intensity<=0.005:
		return
	animation_time=fmod(animation_time+delta,1000.0)
	queue_redraw()

func _draw() -> void:
	if overcast_intensity>0.001:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.08,0.12,0.14,overcast_intensity*0.34))
	if fog_intensity>0.001:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.72,0.78,0.75,fog_intensity*0.48))
		for band: int in 4:
			var y:=fmod(float(band)*190.0+animation_time*7.0,size.y+260.0)-130.0
			draw_circle(Vector2(size.x*(0.16+0.24*band),y),260.0,Color(0.82,0.86,0.83,fog_intensity*0.035))
	if rain_intensity<=0.01:
		return
	var streak_count:=roundi(28.0+rain_intensity*48.0)
	var rain_color:=Color(0.72,0.83,0.91,0.24+rain_intensity*0.30)
	for index: int in streak_count:
		var x:=fmod(float(index*97)+animation_time*(430.0+float(index%5)*15.0),size.x+160.0)-80.0
		var y:=fmod(float(index*61)+animation_time*(690.0+float(index%7)*19.0),size.y+120.0)-100.0
		var length:=14.0+float(index%4)*4.0
		draw_line(Vector2(x,y),Vector2(x-7.0,y+length),rain_color,1.2,true)
