extends RefCounted

const WeatherRules=preload("res://scripts/weather_rules.gd")

static func run(game: Node2D) -> void:
	var observed:={}
	for slot: int in WeatherRules.SCHEDULE.size():
		var state:=WeatherRules.sample(float(slot)*WeatherRules.SLOT_MINUTES+120.0)
		observed[str(state.id)]=true
	for weather_id: String in ["clear","cloudy","rain","fog"]:
		assert(observed.has(weather_id),"Every lightweight weather state must appear in the schedule")
	var before:=WeatherRules.sample(WeatherRules.SLOT_MINUTES-0.01)
	var after:=WeatherRules.sample(WeatherRules.SLOT_MINUTES+0.01)
	var before_tint: Color=before.tint
	var after_tint: Color=after.tint
	var tint_difference:=absf(before_tint.r-after_tint.r)+absf(before_tint.g-after_tint.g)+absf(before_tint.b-after_tint.b)
	assert(tint_difference<0.01,"Weather transitions must remain visually continuous")
	var needs_before: Dictionary=game.needs.duplicate(true)
	game.game_time_minutes=900.0
	game.update_world_lighting()
	assert(str(game.weather_state.id)=="rain" and float(game.weather_overlay.rain_intensity)>0.9,"Rain time must update tint and screen effect")
	var interior_logical: Vector2=(game.world_map.blue_house.furniture[0].use_zone as Rect2).get_center()
	game.player.position=game.world_map.map_to_world(interior_logical)
	game.update_world_lighting()
	assert(is_zero_approx(float(game.weather_overlay.rain_intensity)),"Rain streaks must stay outside buildings")
	assert(game.needs==needs_before,"Weather must not add survival penalties")
	print("WEATHER PASS: clear, cloudy, rain and fog cycle smoothly with visual-only effects")
	game.get_tree().quit()
