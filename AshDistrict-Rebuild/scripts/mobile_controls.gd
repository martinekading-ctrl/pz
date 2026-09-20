extends Control

const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const SettingsStore = preload("res://scripts/settings_store.gd")
const LAYOUT_CONFIG_PATH := "user://mobile_controls.cfg"
const VALID_LAYOUTS := ["standard", "compact", "mirrored"]

var game: Node2D
var game_input: Node
var gameplay_root: Control
var move_stick: Control
var aim_stick: Control
var buttons := {}
var layout_preset := "standard"
var vehicle_mode := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	gameplay_root = Control.new()
	gameplay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gameplay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gameplay_root)
	move_stick = JoystickScript.new()
	move_stick.setup("移动")
	move_stick.vector_changed.connect(game_input.set_touch_move)
	gameplay_root.add_child(move_stick)
	aim_stick = JoystickScript.new()
	aim_stick.setup("瞄准/攻击")
	aim_stick.vector_changed.connect(game_input.set_touch_aim)
	aim_stick.gesture_released.connect(request_aim_attack)
	gameplay_root.add_child(aim_stick)

	buttons.interact = make_button("交互", 76)
	buttons.reload = make_button("装填", 68)
	buttons.run = make_button("跑", 72)
	buttons.crouch = make_button("蹲", 72)
	for key in ["interact", "reload", "run", "crouch"]:
		gameplay_root.add_child(buttons[key])
	buttons.interact.pressed.connect(request_interact)
	buttons.reload.pressed.connect(request_reload)
	buttons.run.button_down.connect(game_input.set_touch_run.bind(true))
	buttons.run.button_up.connect(game_input.set_touch_run.bind(false))
	buttons.crouch.toggle_mode = true
	buttons.crouch.toggled.connect(game_input.set_touch_crouch)

	buttons.backpack = make_button("背包", 76)
	buttons.crafting = make_button("制作", 76)
	buttons.settings = make_button("⚙", 76)
	buttons.settings.add_theme_font_size_override("font_size", 29)
	add_child(buttons.backpack)
	add_child(buttons.crafting)
	add_child(buttons.settings)
	buttons.backpack.pressed.connect(request_backpack)
	buttons.crafting.pressed.connect(request_crafting)
	buttons.settings.pressed.connect(request_settings)
	load_layout_preset()
	resized.connect(layout_controls)
	call_deferred("layout_controls")

func make_button(text: String, diameter: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(diameter, diameter)
	button.size = Vector2(diameter, diameter)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("f3f1e7"))
	button.add_theme_stylebox_override("normal", circle_style(Color(0.025, 0.04, 0.035, 0.66), Color(0.78, 0.84, 0.76, 0.58), diameter))
	button.add_theme_stylebox_override("hover", circle_style(Color(0.11, 0.15, 0.12, 0.78), Color(0.9, 0.87, 0.66, 0.85), diameter))
	button.add_theme_stylebox_override("pressed", circle_style(Color(0.32, 0.25, 0.12, 0.9), Color(1.0, 0.83, 0.42, 0.95), diameter))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

func circle_style(fill: Color, border: Color, diameter: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(roundi(diameter * 0.5))
	return style

func layout_controls() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var safe := safe_rect()
	match layout_preset:
		"compact": layout_compact(safe)
		"mirrored": layout_mirrored(safe)
		_: layout_standard(safe)
	place(buttons.settings, Vector2(safe.end.x - 88.0, safe.position.y + 12.0), 76)
	place(buttons.backpack, Vector2(safe.end.x - 180.0, safe.position.y + 12.0), 76)
	place(buttons.crafting, Vector2(safe.end.x - 272.0, safe.position.y + 12.0), 76)

func layout_standard(safe: Rect2) -> void:
	place_square(move_stick, Vector2(safe.position.x + 18.0, safe.end.y - 186.0), 168)
	place_square(aim_stick, Vector2(safe.end.x - 196.0, safe.end.y - 196.0), 184)
	place(buttons.interact, Vector2(safe.end.x - 92.0, safe.end.y - 292.0), 76)
	place(buttons.reload, Vector2(safe.end.x - 178.0, safe.end.y - 282.0), 68)
	place(buttons.run, Vector2(safe.end.x - 286.0, safe.end.y - 88.0), 72)
	place(buttons.crouch, Vector2(safe.end.x - 286.0, safe.end.y - 178.0), 72)

func layout_compact(safe: Rect2) -> void:
	place_square(move_stick, Vector2(safe.position.x + 18.0, safe.end.y - 166.0), 148)
	place_square(aim_stick, Vector2(safe.end.x - 180.0, safe.end.y - 180.0), 168)
	place(buttons.interact, Vector2(safe.end.x - 92.0, safe.end.y - 268.0), 76)
	place(buttons.reload, Vector2(safe.end.x - 172.0, safe.end.y - 258.0), 68)
	place(buttons.run, Vector2(safe.end.x - 280.0, safe.end.y - 88.0), 72)
	place(buttons.crouch, Vector2(safe.end.x - 280.0, safe.end.y - 178.0), 72)

func layout_mirrored(safe: Rect2) -> void:
	place_square(aim_stick, Vector2(safe.position.x + 12.0, safe.end.y - 196.0), 184)
	place_square(move_stick, Vector2(safe.end.x - 186.0, safe.end.y - 186.0), 168)
	place(buttons.interact, Vector2(safe.position.x + 12.0, safe.end.y - 292.0), 76)
	place(buttons.reload, Vector2(safe.position.x + 98.0, safe.end.y - 282.0), 68)
	place(buttons.run, Vector2(safe.position.x + 216.0, safe.end.y - 88.0), 72)
	place(buttons.crouch, Vector2(safe.position.x + 216.0, safe.end.y - 178.0), 72)

func place(control: Control, position: Vector2, diameter: float) -> void:
	control.position = position
	control.size = Vector2(diameter, diameter)

func place_square(control: Control, position: Vector2, edge: float) -> void:
	control.position = position
	control.size = Vector2(edge, edge)

func apply_layout_preset(preset: String, persist: bool = true) -> void:
	layout_preset = preset if preset in VALID_LAYOUTS else "standard"
	layout_controls()
	if persist:
		var config := ConfigFile.new()
		config.set_value("controls", "layout", layout_preset)
		config.save(LAYOUT_CONFIG_PATH)
		var settings := SettingsStore.load_values()
		settings.mobile_layout = layout_preset
		SettingsStore.save_values(settings)

func load_layout_preset() -> void:
	var config := ConfigFile.new()
	if config.load(LAYOUT_CONFIG_PATH) == OK:
		var saved := str(config.get_value("controls", "layout", "standard"))
		layout_preset = saved if saved in VALID_LAYOUTS else "standard"

func layout_preset_name() -> String:
	return {"standard":"标准布局", "compact":"紧凑布局", "mirrored":"左右互换"}.get(layout_preset, "标准布局")

func safe_rect() -> Rect2:
	var viewport_rect := Rect2(Vector2.ZERO, size)
	var window_size := Vector2(DisplayServer.window_get_size())
	var display_safe := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or display_safe.size.x <= 0 or display_safe.size.y <= 0:
		return viewport_rect.grow(-16.0)
	var scale := Vector2(size.x / window_size.x, size.y / window_size.y)
	var position := Vector2(display_safe.position) * scale
	var safe_size := Vector2(display_safe.size) * scale
	var result := Rect2(position, safe_size).intersection(viewport_rect)
	return result.grow(-16.0) if result.size.x > 500.0 and result.size.y > 300.0 else viewport_rect.grow(-16.0)

func set_gameplay_enabled(value: bool) -> void:
	gameplay_root.visible = value
	if not value:
		move_stick.set_output(Vector2.ZERO)
		aim_stick.set_output(Vector2.ZERO)
		game_input.set_touch_run(false)

func set_vehicle_mode(value: bool) -> void:
	vehicle_mode=value
	aim_stick.visible=not value
	buttons.reload.visible=not value
	buttons.run.visible=not value
	buttons.crouch.visible=not value
	buttons.interact.text="下车" if value else "交互"

func request_interact() -> void:
	if gameplay_root.visible:
		game.interact()

func request_aim_attack(direction: Vector2) -> void:
	if gameplay_root.visible:
		game_input.queue_touch_attack(direction)

func request_reload() -> void:
	if gameplay_root.visible:
		game.begin_reload()

func request_backpack() -> void:
	game.toggle_backpack()

func request_crafting() -> void:
	game.toggle_crafting()

func request_settings() -> void:
	game.toggle_mobile_settings()
