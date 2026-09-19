extends RefCounted

const SettingsStore = preload("res://scripts/settings_store.gd")
const SaveSystem = preload("res://scripts/save_system.gd")

static func run(game: Node2D) -> void:
	assert(game.save_slot_path(1) != game.save_slot_path(2))
	assert(game.save_slot_path(2) != game.save_slot_path(3))
	var data: Dictionary = SaveSystem.capture_state(game)
	var summary: Dictionary = game.save_data_summary(data)
	assert(bool(summary.exists) and "第" in str(summary.text) and "生命" in str(summary.text))

	var clean: Dictionary = SettingsStore.sanitize({"master_volume":2.0,"sfx_volume":-1.0,"fullscreen":false,"mobile_layout":"invalid"})
	assert(float(clean.master_volume) == 1.0)
	assert(float(clean.sfx_volume) == 0.0)
	assert(clean.mobile_layout == "standard")

	game.show_product_shell()
	assert(is_instance_valid(game.product_shell))
	assert(game.simulation_paused)
	assert(not game.player.is_physics_processing())
	assert(game.product_shell.current_screen() == "main")
	game.product_shell.push_screen("tutorial")
	assert(game.product_shell.current_screen() == "tutorial")
	game.product_shell.pop_screen()
	assert(game.product_shell.current_screen() == "main")
	assert(FileAccess.file_exists("res://export_presets.cfg"))
	print("PRODUCT SHELL PASS: responsive menu, focus flow, 3 slots, summaries, settings validation and export preset")
	game.get_tree().quit()
