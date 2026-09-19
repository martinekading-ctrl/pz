extends Control

signal vector_changed(value: Vector2)
signal gesture_released(value: Vector2)

const DEADZONE := 0.18
var output := Vector2.ZERO
var touch_index := -1
var mouse_dragging := false
var caption := ""
var gesture_vector := Vector2.ZERO

func setup(label_text: String) -> void:
	caption = label_text
	custom_minimum_size = Vector2(168, 168)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index < 0:
			touch_index = event.index
			gesture_vector = Vector2.ZERO
			set_from_point(event.position)
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			gesture_released.emit(gesture_vector)
			set_output(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == touch_index:
		set_from_point(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_dragging = true
			gesture_vector = Vector2.ZERO
			set_from_point(event.position)
		elif mouse_dragging:
			mouse_dragging = false
			gesture_released.emit(gesture_vector)
			set_output(Vector2.ZERO)
	elif event is InputEventMouseMotion and mouse_dragging:
		set_from_point(event.position)

func set_from_point(point: Vector2) -> void:
	var radius := maxf(1.0, minf(size.x, size.y) * 0.5 - 14.0)
	var raw := (point - size * 0.5) / radius
	set_output(apply_radial_deadzone(raw.limit_length(1.0), DEADZONE))

func set_output(value: Vector2) -> void:
	output = value.limit_length(1.0)
	if output.length_squared() > 0.001:
		gesture_vector = output
	vector_changed.emit(output)
	queue_redraw()

func set_value_for_test(value: Vector2) -> void:
	set_output(value)

static func apply_radial_deadzone(value: Vector2, deadzone: float = DEADZONE) -> Vector2:
	var magnitude := value.length()
	if magnitude <= deadzone:
		return Vector2.ZERO
	var scaled := (magnitude - deadzone) / (1.0 - deadzone)
	return value.normalized() * clampf(scaled, 0.0, 1.0)

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 8.0
	draw_circle(center, radius, Color(0.025, 0.04, 0.035, 0.48))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.78, 0.84, 0.76, 0.52), 3.0, true)
	for ring_scale in [0.42, 0.72]:
		draw_arc(center, radius * ring_scale, 0.0, TAU, 32, Color(0.62, 0.7, 0.62, 0.18), 2.0, true)
	var knob := center + output * radius * 0.68
	draw_circle(knob, radius * 0.3, Color(0.75, 0.79, 0.72, 0.72))
	draw_arc(knob, radius * 0.3, 0.0, TAU, 32, Color(0.95, 0.96, 0.9, 0.8), 2.0, true)
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(font, center - Vector2(text_size.x * 0.5, -6), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.94, 0.95, 0.9, 0.74))
