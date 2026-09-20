extends RefCounted

const Catalog = preload("res://scripts/item_catalog.gd")

const MAX_VALUE := 100.0
const GAME_MINUTES_PER_REAL_SECOND := 0.8
const HUNGER_PER_GAME_MINUTE := 25.0 / 1440.0
const THIRST_PER_GAME_MINUTE := 40.0 / 1440.0
const STARVATION_DAMAGE_PER_GAME_MINUTE := 0.075
const DEHYDRATION_DAMAGE_PER_GAME_MINUTE := 0.11
const BLEED_DAMAGE_PER_GAME_MINUTE := 0.055
const INFECTION_DAMAGE_PER_GAME_MINUTE := 0.025
const FED_REGEN_PER_GAME_MINUTE := 0.012
const FATIGUE_PER_GAME_MINUTE := 100.0 / 960.0
const FATIGUE_RECOVERY_PER_GAME_MINUTE := 0.16
const SLEEP_HEALTH_RECOVERY_PER_GAME_MINUTE := 6.0 / 480.0

static func advance(needs: Dictionary, game_minutes: float, active: bool) -> void:
	var activity_multiplier := 1.55 if active else 1.0
	needs.food = maxf(0.0, float(needs.food) - HUNGER_PER_GAME_MINUTE * game_minutes * activity_multiplier)
	needs.water = maxf(0.0, float(needs.water) - THIRST_PER_GAME_MINUTE * game_minutes * activity_multiplier)
	needs.fatigue = minf(MAX_VALUE, float(needs.get("fatigue", 0.0)) + FATIGUE_PER_GAME_MINUTE * game_minutes * (1.18 if active else 1.0))
	var damage := 0.0
	if float(needs.food) <= 0.0:
		damage += STARVATION_DAMAGE_PER_GAME_MINUTE * game_minutes
	if float(needs.water) <= 0.0:
		damage += DEHYDRATION_DAMAGE_PER_GAME_MINUTE * game_minutes
	damage += float(needs.get("bleeding", 0.0)) * BLEED_DAMAGE_PER_GAME_MINUTE * game_minutes
	var infection := float(needs.get("infection", 0.0))
	if infection > 60.0:
		damage += ((infection - 60.0) / 40.0) * INFECTION_DAMAGE_PER_GAME_MINUTE * game_minutes
	if damage > 0.0:
		needs.health = maxf(0.0, float(needs.health) - damage)
	elif float(needs.food) >= 75.0 and float(needs.water) >= 75.0 and float(needs.health) < MAX_VALUE:
		needs.health = minf(MAX_VALUE, float(needs.health) + FED_REGEN_PER_GAME_MINUTE * game_minutes)

static func use_item(needs: Dictionary, item_key: String, spoiled: bool = false) -> Dictionary:
	if item_key == "bandage":
		var bleeding := float(needs.get("bleeding", 0.0))
		if bleeding <= 0.0 and float(needs.health) >= MAX_VALUE:
			return {"consumed":false, "message":"没有需要处理的伤口，未消耗绷带"}
		needs.bleeding = 0.0
		needs.health = minf(MAX_VALUE, float(needs.health) + (5.0 if bleeding > 0.0 else 15.0))
		return {"consumed":true, "message":"伤口已包扎，流血停止" if bleeding > 0.0 else "使用绷带，生命 +15"}
	if item_key == "fresh_food" and spoiled:
		needs.food = minf(MAX_VALUE, float(needs.food) + 4.0)
		needs.health = maxf(0.0, float(needs.health) - 6.0)
		return {"consumed":true, "message":"面包已经变质：饱食 +4，生命 -6"}
	var definition: Dictionary = Catalog.item(item_key)
	var effects: Dictionary = definition.get("effects", {})
	if effects.is_empty():
		return {"consumed": false, "message": "该物品不能直接使用"}
	var changed := false
	for key: String in effects.keys():
		var before := float(needs.get(key, 0.0))
		var after := clampf(before + float(effects[key]), 0.0, MAX_VALUE)
		if not is_equal_approx(before, after):
			changed = true
		needs[key] = after
	if not changed:
		return {"consumed":false, "message":"当前状态不需要使用" + str(definition.get("name", "该物品"))}
	return {"consumed":true, "message":str(definition.get("use_text", "已使用物品"))}

static func rest(needs: Dictionary, game_minutes: float = 480.0) -> Dictionary:
	var check := can_sleep(needs)
	if not bool(check.ok):
		return {"rested":false, "message":str(check.message)}
	sleep_step(needs, game_minutes)
	finish_sleep(needs)
	return {"rested":true, "message":"休息了 8 小时，体力已经恢复"}

static func can_sleep(needs: Dictionary) -> Dictionary:
	if float(needs.get("bleeding", 0.0)) > 0.0 and not bool(needs.get("wounds_bandaged", false)):
		return {"ok":false, "message":"正在流血，包扎后才能睡觉"}
	if float(needs.get("fatigue", 0.0)) < 10.0 and float(needs.get("stamina", 100.0)) >= 95.0:
		return {"ok":false, "message":"现在还不需要睡觉"}
	return {"ok":true, "message":"可以睡觉"}

static func sleep_step(needs: Dictionary, game_minutes: float) -> void:
	if game_minutes <= 0.0:
		return
	needs.food = maxf(0.0, float(needs.food) - HUNGER_PER_GAME_MINUTE * game_minutes * 0.72)
	needs.water = maxf(0.0, float(needs.water) - THIRST_PER_GAME_MINUTE * game_minutes * 0.72)
	needs.fatigue = maxf(0.0, float(needs.get("fatigue", 0.0)) - FATIGUE_RECOVERY_PER_GAME_MINUTE * game_minutes)
	if float(needs.food) >= 25.0 and float(needs.water) >= 25.0:
		needs.health = minf(MAX_VALUE, float(needs.health) + SLEEP_HEALTH_RECOVERY_PER_GAME_MINUTE * game_minutes)

static func finish_sleep(needs: Dictionary) -> void:
	needs.stamina = MAX_VALUE

static func movement_multiplier(needs: Dictionary) -> float:
	var lowest := minf(float(needs.food), float(needs.water))
	if lowest <= 0.0:
		return 0.62
	if lowest < 10.0:
		return 0.72
	if lowest < 25.0:
		return 0.86
	return 1.0

static func can_run(needs: Dictionary) -> bool:
	return float(needs.food) > 10.0 and float(needs.water) > 10.0

static func condition_text(needs: Dictionary) -> String:
	var states: Array[String] = []
	if float(needs.get("bleeding", 0.0)) > 0.0:
		states.append("伤口已包扎" if bool(needs.get("wounds_bandaged", false)) else "流血")
	var infection := float(needs.get("infection", 0.0))
	if infection >= 80.0:
		states.append("严重感染")
	elif infection >= 25.0:
		states.append("感染")
	var pain := float(needs.get("pain", 0.0))
	if pain >= 70.0:
		states.append("剧痛")
	elif pain >= 40.0:
		states.append("疼痛")
	if float(needs.water) <= 0.0:
		states.append("严重脱水")
	elif float(needs.water) < 25.0:
		states.append("口渴")
	if float(needs.food) <= 0.0:
		states.append("极度饥饿")
	elif float(needs.food) < 25.0:
		states.append("饥饿")
	var fatigue := float(needs.get("fatigue", 0.0))
	if fatigue >= 90.0:
		states.append("极度疲劳")
	elif fatigue >= 70.0:
		states.append("疲劳")
	if float(needs.get("stamina", 100.0)) <= 10.0:
		states.append("体力耗尽")
	return "状态正常" if states.is_empty() else " · ".join(states)

static func clock_parts(total_minutes: float) -> Dictionary:
	var whole := maxi(0, int(floor(total_minutes)))
	return {
		"day": whole / 1440 + 1,
		"hour": (whole % 1440) / 60,
		"minute": whole % 60
	}

static func light_color(total_minutes: float) -> Color:
	var minute_of_day := fmod(total_minutes, 1440.0)
	var daylight := clampf(sin((minute_of_day - 360.0) / 720.0 * PI), 0.0, 1.0)
	return Color("a9b8cc").lerp(Color.WHITE, 0.35 + daylight * 0.65)
