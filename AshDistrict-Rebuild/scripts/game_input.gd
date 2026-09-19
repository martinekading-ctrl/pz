extends Node

var touch_move := Vector2.ZERO
var touch_aim := Vector2.ZERO
var touch_run := false
var touch_crouch := false
var touch_attack_queued := false
var touch_attack_aim := Vector2.ZERO

static func install_default_actions() -> void:
	add_key_action("move_left", [KEY_A, KEY_LEFT])
	add_key_action("move_right", [KEY_D, KEY_RIGHT])
	add_key_action("move_up", [KEY_W, KEY_UP])
	add_key_action("move_down", [KEY_S, KEY_DOWN])
	add_key_action("run", [KEY_SHIFT])
	add_key_action("crouch", [KEY_C])
	add_key_action("interact", [KEY_E])
	add_key_action("backpack", [KEY_TAB, KEY_B])
	add_key_action("crafting", [KEY_K])
	add_key_action("weapon_swap", [KEY_Q])
	add_key_action("reload", [KEY_R])
	add_key_action("save_game", [KEY_F5])
	add_key_action("load_game", [KEY_F9])
	add_key_action("back", [KEY_ESCAPE])
	add_mouse_action("attack", MOUSE_BUTTON_LEFT)
	add_mouse_action("aim", MOUSE_BUTTON_RIGHT)

static func add_key_action(action: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode: int in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

static func add_mouse_action(action: StringName, button_index: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func movement_vector() -> Vector2:
	var physical := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return touch_move if touch_move.length_squared() > physical.length_squared() else physical

func aim_vector() -> Vector2:
	return touch_aim

func mouse_aiming() -> bool:
	return Input.is_action_pressed("aim")

func wants_run() -> bool:
	return touch_run or Input.is_action_pressed("run")

func wants_crouch() -> bool:
	return touch_crouch or Input.is_action_pressed("crouch")

func consume_attack_request() -> bool:
	if touch_attack_queued:
		touch_attack_queued = false
		return true
	return Input.is_action_just_pressed("attack")

func consume_attack_aim() -> Vector2:
	var value := touch_attack_aim
	touch_attack_aim = Vector2.ZERO
	return value

func set_touch_move(value: Vector2) -> void:
	touch_move = value.limit_length(1.0)

func set_touch_aim(value: Vector2) -> void:
	touch_aim = value.limit_length(1.0)

func set_touch_run(value: bool) -> void:
	touch_run = value

func set_touch_crouch(value: bool) -> void:
	touch_crouch = value

func queue_touch_attack(direction: Vector2 = Vector2.ZERO) -> void:
	touch_attack_queued = true
	touch_attack_aim = direction.normalized() if direction.length_squared() > 0.01 else Vector2.ZERO

func clear_transient() -> void:
	touch_move = Vector2.ZERO
	touch_aim = Vector2.ZERO
	touch_run = false
	touch_attack_queued = false
	touch_attack_aim = Vector2.ZERO
