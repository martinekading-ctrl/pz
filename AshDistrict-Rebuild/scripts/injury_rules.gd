extends RefCounted

const PARTS := ["head", "torso", "arms", "legs"]
const PART_LABELS := {
	"head":"头部",
	"torso":"躯干",
	"arms":"手臂",
	"legs":"腿部",
}
const WOUND_LABELS := {
	"none":"健康",
	"scratch":"擦伤",
	"laceration":"撕裂伤",
	"bite":"咬伤",
}
const WOUND_SEVERITY := {"none":0, "scratch":1, "laceration":2, "bite":3}
const BLEEDING_RATE := {"none":0.0, "scratch":0.28, "laceration":0.65, "bite":0.95}
const PAIN_VALUE := {"none":0.0, "scratch":12.0, "laceration":25.0, "bite":40.0}
const INFECTION_PER_HOUR := {"none":0.0, "scratch":0.25, "laceration":0.45, "bite":0.8}
const HEALING_MINUTES := {"none":0.0, "scratch":720.0, "laceration":2880.0, "bite":999999.0}

static func fresh_state() -> Dictionary:
	var result := {}
	for part: String in PARTS:
		result[part] = fresh_part()
	return result

static func fresh_part() -> Dictionary:
	return {"wound":"none", "severity":0, "bandaged":false, "infected":false, "infection":0.0, "healing":0.0}

static func sanitize(value: Variant) -> Dictionary:
	var result := fresh_state()
	if typeof(value) != TYPE_DICTIONARY:
		return result
	for part: String in PARTS:
		var source: Variant = value.get(part, {})
		if typeof(source) != TYPE_DICTIONARY:
			continue
		var wound := str(source.get("wound", "none"))
		if not WOUND_SEVERITY.has(wound):
			wound = "none"
		result[part] = {
			"wound":wound,
			"severity":int(WOUND_SEVERITY[wound]),
			"bandaged":bool(source.get("bandaged", false)) and wound != "none",
			"infected":bool(source.get("infected", false)) or wound == "bite",
			"infection":clampf(float(source.get("infection", 0.0)), 0.0, 100.0) if wound != "none" else 0.0,
			"healing":maxf(0.0, float(source.get("healing", 0.0))) if wound != "none" else 0.0,
		}
	return result

static func migrate_legacy_bleeding(bleeding: float) -> Dictionary:
	var result := fresh_state()
	if bleeding > 0.0:
		var wound := "laceration" if bleeding >= 0.6 else "scratch"
		result.torso = make_wound(wound, false, false, 0.0)
	return result

static func make_wound(wound: String, bandaged: bool = false, infected: bool = false, infection: float = 0.0, healing: float = 0.0) -> Dictionary:
	var valid_wound := wound if WOUND_SEVERITY.has(wound) else "none"
	return {
		"wound":valid_wound,
		"severity":int(WOUND_SEVERITY[valid_wound]),
		"bandaged":bandaged and valid_wound != "none",
		"infected":infected or valid_wound == "bite",
		"infection":clampf(infection, 0.0, 100.0) if valid_wound != "none" else 0.0,
		"healing":maxf(0.0, healing) if valid_wound != "none" else 0.0,
	}

static func apply_zombie_hit(injuries: Dictionary, wound_roll: float, part_roll: float, infection_roll: float) -> Dictionary:
	var wound := wound_from_roll(wound_roll)
	if wound == "none":
		return {"wounded":false, "message":""}
	var part := part_from_roll(part_roll)
	var chance: float = float({"scratch":0.07, "laceration":0.18, "bite":1.0}[wound])
	var new_infected: bool = infection_roll < chance
	var current: Dictionary = injuries.get(part, fresh_part())
	var current_severity := int(current.get("severity", 0))
	var new_severity := int(WOUND_SEVERITY[wound])
	if current_severity > new_severity:
		wound = str(current.get("wound", wound))
		new_severity = current_severity
	var was_wounded := current_severity > 0
	injuries[part] = make_wound(
		wound,
		false,
		bool(current.get("infected", false)) or new_infected,
		maxf(float(current.get("infection", 0.0)), 8.0 if new_infected else 0.0)
	)
	var suffix := "，伤口有感染迹象" if bool(injuries[part].infected) else ""
	var verb := "再次受创" if was_wounded else "受到"
	return {
		"wounded":true,
		"part":part,
		"wound":wound,
		"message":"%s%s%s%s" % [PART_LABELS[part], verb,WOUND_LABELS[wound],suffix],
	}

static func wound_from_roll(value: float) -> String:
	if value < 0.52:
		return "none"
	if value < 0.81:
		return "scratch"
	if value < 0.95:
		return "laceration"
	return "bite"

static func apply_glass_scratch(injuries: Dictionary,part_roll: float) -> Dictionary:
	var part:="arms" if part_roll<0.58 else "legs"
	var current: Dictionary=injuries.get(part,fresh_part())
	if int(current.get("severity",0))>1:
		return {"wounded":false,"message":"碎玻璃擦过了%s" % PART_LABELS[part]}
	injuries[part]=make_wound("scratch",false,bool(current.get("infected",false)),float(current.get("infection",0.0)))
	return {"wounded":true,"part":part,"wound":"scratch","message":"翻越碎窗时%s被玻璃划伤" % PART_LABELS[part]}

static func part_from_roll(value: float) -> String:
	if value < 0.08:
		return "head"
	if value < 0.48:
		return "torso"
	if value < 0.73:
		return "arms"
	return "legs"

static func bleeding_value(injuries: Dictionary) -> float:
	var total := 0.0
	for part: String in PARTS:
		var injury: Dictionary = injuries.get(part, fresh_part())
		var rate := float(BLEEDING_RATE.get(str(injury.get("wound", "none")), 0.0))
		total += rate * (0.16 if bool(injury.get("bandaged", false)) else 1.0)
	return minf(total, 2.5)

static func raw_pain(injuries: Dictionary) -> float:
	var total := 0.0
	for part: String in PARTS:
		var injury: Dictionary = injuries.get(part, fresh_part())
		var pain := float(PAIN_VALUE.get(str(injury.get("wound", "none")), 0.0))
		var part_multiplier := 1.05 if part == "head" else (0.9 if part == "legs" else (0.85 if part == "arms" else 1.0))
		total += pain * part_multiplier
	return minf(total, 100.0)

static func infection_value(injuries: Dictionary) -> float:
	var maximum := 0.0
	for part: String in PARTS:
		var injury: Dictionary = injuries.get(part, fresh_part())
		if bool(injury.get("infected", false)):
			maximum = maxf(maximum, float(injury.get("infection", 0.0)))
	return maximum

static func sync_needs(injuries: Dictionary, needs: Dictionary) -> void:
	needs["bleeding"] = bleeding_value(injuries)
	needs["wounds_bandaged"] = all_wounds_bandaged(injuries)
	var relief := float(needs.get("pain_relief", 0.0))
	needs["pain"] = maxf(0.0, raw_pain(injuries) - (22.0 if relief > 0.0 else 0.0))
	needs["infection"] = infection_value(injuries)

static func advance(injuries: Dictionary, needs: Dictionary, game_minutes: float) -> void:
	needs["pain_relief"] = maxf(0.0, float(needs.get("pain_relief", 0.0)) - game_minutes)
	for part: String in PARTS:
		var injury: Dictionary = injuries.get(part, fresh_part())
		if int(injury.get("severity", 0)) <= 0:
			continue
		if bool(injury.get("infected", false)):
			var rate := float(INFECTION_PER_HOUR.get(str(injury.get("wound", "none")), 0.0))
			if bool(injury.get("bandaged", false)):
				rate *= 0.65
			injury["infection"] = minf(100.0, float(injury.get("infection", 0.0)) + rate * game_minutes / 60.0)
		else:
			var healing_rate := 1.0 if bool(injury.get("bandaged", false)) else 0.5
			injury["healing"] = float(injury.get("healing", 0.0)) + game_minutes * healing_rate
			var required := float(HEALING_MINUTES.get(str(injury.get("wound", "none")), 999999.0))
			if float(injury.healing) >= required:
				injury = fresh_part()
		injuries[part] = injury
	sync_needs(injuries, needs)

static func all_wounds_bandaged(injuries: Dictionary) -> bool:
	var found_wound := false
	for part: String in PARTS:
		var injury: Dictionary = injuries.get(part, fresh_part())
		if int(injury.get("severity", 0)) <= 0:
			continue
		found_wound = true
		if not bool(injury.get("bandaged", false)):
			return false
	return found_wound

static func apply_bandage(injuries: Dictionary, preferred_part: String = "") -> Dictionary:
	var part := preferred_part if preferred_part in PARTS else most_urgent_unbandaged(injuries)
	if part.is_empty():
		return {"consumed":false, "message":"没有需要包扎的伤口"}
	var injury: Dictionary = injuries.get(part, fresh_part())
	if int(injury.get("severity", 0)) <= 0:
		return {"consumed":false, "message":PART_LABELS[part] + "没有伤口"}
	if bool(injury.get("bandaged", false)):
		return {"consumed":false, "message":PART_LABELS[part] + "已经包扎"}
	injury["bandaged"] = true
	injuries[part] = injury
	return {"consumed":true, "part":part, "message":"已包扎%s的%s，出血大幅减缓" % [PART_LABELS[part], WOUND_LABELS[str(injury.wound)]]}

static func remove_bandage(injuries: Dictionary, part: String) -> Dictionary:
	if part not in PARTS or not bool(injuries.get(part, {}).get("bandaged", false)):
		return {"removed":false, "message":"这里没有绷带"}
	injuries[part]["bandaged"] = false
	return {"removed":true, "message":"已拆下%s绷带" % PART_LABELS[part]}

static func take_painkillers(needs: Dictionary, injuries: Dictionary) -> Dictionary:
	if raw_pain(injuries) <= 0.0:
		return {"consumed":false, "message":"当前没有需要缓解的伤痛"}
	if float(needs.get("pain_relief", 0.0)) >= 120.0:
		return {"consumed":false, "message":"止痛药仍在生效，未重复服用"}
	needs["pain_relief"] = 180.0
	sync_needs(injuries, needs)
	return {"consumed":true, "message":"服用了止痛药，约三小时内减轻疼痛"}

static func disinfect_wound(injuries: Dictionary, preferred_part: String = "", effectiveness: float = 1.0) -> Dictionary:
	var part := preferred_part if preferred_part in PARTS else most_infected_part(injuries)
	if part.is_empty():
		return {"consumed":false, "message":"没有需要消毒的感染伤口"}
	var injury: Dictionary = injuries.get(part, fresh_part())
	if int(injury.get("severity",0)) <= 0 or not bool(injury.get("infected",false)):
		return {"consumed":false, "message":PART_LABELS[part] + "没有感染伤口"}
	var before := float(injury.get("infection",0.0))
	injury["infection"] = maxf(0.0, before - 18.0 * maxf(0.0,effectiveness))
	if str(injury.get("wound","none")) != "bite" and float(injury.infection) <= 0.0:
		injury["infected"] = false
	injuries[part] = injury
	return {"consumed":true, "message":"已为%s消毒，感染 %.0f%% → %.0f%%" % [PART_LABELS[part],before,float(injury.infection)]}

static func take_antibiotics(injuries: Dictionary, effectiveness: float = 1.0) -> Dictionary:
	var treated := 0
	var bite_present := false
	for part: String in PARTS:
		var injury: Dictionary = injuries.get(part,fresh_part())
		if not bool(injury.get("infected",false)):
			continue
		var wound := str(injury.get("wound","none"))
		var reduction := (10.0 if wound == "bite" else 35.0) * maxf(0.0,effectiveness)
		injury["infection"] = maxf(0.0,float(injury.get("infection",0.0))-reduction)
		if wound != "bite" and float(injury.infection) <= 0.0:
			injury["infected"] = false
		if wound == "bite":
			bite_present = true
		injuries[part] = injury
		treated += 1
	if treated <= 0:
		return {"consumed":false, "message":"当前没有需要抗生素处理的感染"}
	return {"consumed":true, "message":"抗生素降低了感染" + ("；咬伤感染只能暂时减缓" if bite_present else "")}

static func most_infected_part(injuries: Dictionary) -> String:
	var chosen := ""
	var highest := -1.0
	for part: String in PARTS:
		var injury: Dictionary = injuries.get(part,fresh_part())
		if bool(injury.get("infected",false)) and float(injury.get("infection",0.0)) > highest:
			highest = float(injury.get("infection",0.0))
			chosen = part
	return chosen

static func most_urgent_unbandaged(injuries: Dictionary) -> String:
	var chosen := ""
	var highest := 0
	for part: String in PARTS:
		var injury: Dictionary = injuries.get(part, fresh_part())
		var severity := int(injury.get("severity", 0))
		if severity > highest and not bool(injury.get("bandaged", false)):
			highest = severity
			chosen = part
	return chosen

static func movement_multiplier(injuries: Dictionary, needs: Dictionary) -> float:
	var leg_severity := int(injuries.get("legs", {}).get("severity", 0))
	var wound_multiplier: float = float([1.0, 0.94, 0.82, 0.68][clampi(leg_severity, 0, 3)])
	var pain := float(needs.get("pain", 0.0))
	var pain_multiplier := 0.9 if pain >= 70.0 else (0.96 if pain >= 40.0 else 1.0)
	return wound_multiplier * pain_multiplier

static func attack_duration_multiplier(injuries: Dictionary, needs: Dictionary) -> float:
	var arm_severity := int(injuries.get("arms", {}).get("severity", 0))
	var wound_multiplier: float = float([1.0, 1.08, 1.22, 1.42][clampi(arm_severity, 0, 3)])
	return wound_multiplier * (1.12 if float(needs.get("pain", 0.0)) >= 70.0 else 1.0)

static func attack_stamina_multiplier(injuries: Dictionary) -> float:
	var arm_severity := int(injuries.get("arms", {}).get("severity", 0))
	return [1.0, 1.05, 1.12, 1.25][clampi(arm_severity, 0, 3)]

static func part_summary(injuries: Dictionary, part: String) -> String:
	var injury: Dictionary = injuries.get(part, fresh_part())
	var wound := str(injury.get("wound", "none"))
	if wound == "none":
		return "健康"
	var text := str(WOUND_LABELS[wound])
	if bool(injury.get("bandaged", false)):
		text += " · 已包扎"
	if bool(injury.get("infected", false)):
		text += " · 感染 %.0f%%" % float(injury.get("infection", 0.0))
	return text
