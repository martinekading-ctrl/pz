extends RefCounted

const JoystickScript = preload("res://scripts/virtual_joystick.gd")

static func run(game: Node2D) -> void:
	await game.get_tree().process_frame
	var controls: Control = game.mobile_controls
	assert(is_instance_valid(controls) and controls.visible, "Mobile controls must be visible in mobile test mode")
	assert(game.camera.zoom.is_equal_approx(Vector2(0.68,0.68)), "Normal mobile gameplay must use the balanced camera zoom")
	controls.layout_controls()
	assert(JoystickScript.apply_radial_deadzone(Vector2(0.1, 0.0)).is_zero_approx(), "Stick deadzone must reject center drift")
	controls.move_stick.set_value_for_test(Vector2(0.8, 0.2))
	assert(game.game_input.movement_vector().distance_to(Vector2(0.8, 0.2).limit_length(1.0)) < 0.01, "Left stick must drive movement")
	controls.aim_stick.set_value_for_test(Vector2.RIGHT)
	assert(game.game_input.aim_vector() == Vector2.RIGHT, "Right stick must drive aim")
	controls.aim_stick.gesture_released.emit(Vector2.RIGHT)
	assert(game.game_input.consume_attack_request(), "Releasing the aim stick must queue one attack")
	assert(game.game_input.consume_attack_aim() == Vector2.RIGHT, "Released aim direction must be preserved for the attack")
	assert(not game.game_input.consume_attack_request(), "Aim-release attack edge must be consumed once")
	controls.buttons.run.button_down.emit()
	assert(game.game_input.wants_run(), "Run must be held")
	controls.buttons.run.button_up.emit()
	assert(not game.game_input.wants_run(), "Run must release")
	controls.buttons.crouch.toggled.emit(true)
	assert(game.game_input.wants_crouch(), "Crouch toggle must persist")
	controls.buttons.crouch.toggled.emit(false)
	assert(not game.game_input.wants_crouch(), "Crouch toggle must clear")
	for action in ["move_left", "move_right", "move_up", "move_down", "run", "crouch", "attack", "aim", "interact", "backpack", "weapon_swap", "reload", "save_game", "load_game", "back"]:
		assert(InputMap.has_action(action), "Missing named input action: " + action)
	assert(not controls.buttons.has("pause") and controls.buttons.has("settings"), "Settings gear must replace the pause button")
	assert(controls.buttons.has("reload"), "Mobile controls must provide a reload button")
	var viewport := Rect2(Vector2.ZERO, controls.size)
	for key in controls.buttons.keys():
		var button: Control = controls.buttons[key]
		assert(button.size.x >= 68.0 and button.size.y >= 68.0, "Touch target too small: " + str(key))
		assert(viewport.encloses(Rect2(button.position, button.size)), "Touch target outside viewport: " + str(key))
	for stick: Control in [controls.move_stick, controls.aim_stick]:
		assert(viewport.encloses(Rect2(stick.position, stick.size)), "Joystick outside viewport")
	var quickbar: Control = game.quickbar
	assert(is_instance_valid(quickbar) and quickbar.visible and quickbar.slot_buttons.size() == 6, "Mobile quickbar must expose six inventory slots")
	assert(viewport.encloses(Rect2(quickbar.panel.global_position, quickbar.panel.size)), "Quickbar must stay inside the viewport")
	for slot: Button in quickbar.slot_buttons:
		assert(slot.size.x >= 68.0 and slot.size.y >= 68.0, "Quickbar touch target is too small")
	game.inventory.baseball_bat = 1
	game.add_weapon_instances("baseball_bat", 1)
	assert(game.equip_weapon("baseball_bat", "secondary"), "Test weapon must equip")
	quickbar.press_slot(1)
	assert(game.active_weapon_slot == "secondary" and quickbar.selected_index == 1, "Weapon slot must select the equipped weapon")
	game.inventory.food = 1
	game.needs.food = 50.0
	quickbar.press_slot(2)
	assert(game.inventory.food == 1, "First consumable tap must only select the slot")
	quickbar.press_slot(2)
	assert(game.inventory.food == 0 and game.needs.food == 75.0, "Second consumable tap must use one item")
	controls.apply_layout_preset("standard", false)
	var standard_move: Vector2 = controls.move_stick.position
	var standard_aim: Vector2 = controls.aim_stick.position
	controls.apply_layout_preset("compact", false)
	assert(controls.move_stick.position != standard_move and controls.aim_stick.position != standard_aim, "Compact preset must change control positions")
	controls.apply_layout_preset("mirrored", false)
	assert(controls.aim_stick.position.x < controls.move_stick.position.x, "Mirrored preset must swap movement and aim sides")
	controls.apply_layout_preset("standard", false)
	game.open_mobile_settings()
	assert(is_instance_valid(game.mobile_settings_overlay) and not game.simulation_paused, "Settings must open without pausing the world")
	game.close_mobile_settings()
	controls.set_gameplay_enabled(false)
	assert(game.game_input.touch_move.is_zero_approx() and game.game_input.touch_aim.is_zero_approx() and not game.game_input.touch_run, "Closing gameplay UI must clear held touch state")
	print("MOBILE INPUT PASS: named actions, move stick, aim-release attack, reload, radial deadzone, run hold, crouch toggle, quickbar and safe touch targets")
	game.get_tree().quit()
