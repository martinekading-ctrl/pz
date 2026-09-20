extends RefCounted

const Catalog = preload("res://scripts/item_catalog.gd")
const SLOTS := ["head", "torso", "legs", "feet"]
const SLOT_LABELS := {"head":"头部", "torso":"上身", "legs":"腿部", "feet":"脚部"}
const WOUND_WEAR := {"scratch":5.0, "laceration":11.0, "bite":18.0}

static func max_durability(item_id: String) -> float:
	return maxf(1.0, float(Catalog.item(item_id).get("durability", 1.0)))

static func slot(item_id: String) -> String:
	return str(Catalog.item(item_id).get("slot", "")) if Catalog.is_clothing(item_id) else ""

static func slots_for_part(part: String) -> Array[String]:
	match part:
		"head": return ["head"]
		"torso", "arms": return ["torso"]
		"legs": return ["legs", "feet"]
	return []

static func base_protection(item_id: String, wound: String) -> float:
	return clampf(float(Catalog.item(item_id).get(wound + "_protection", 0.0)), 0.0, 0.95)

static func effective_protection(item_id: String, durability: float, wound: String) -> float:
	var condition := clampf(durability / max_durability(item_id), 0.0, 1.0)
	return base_protection(item_id, wound) * lerpf(0.25, 1.0, condition)

static func combined_protection(part: String, wound: String, equipment: Dictionary, durability: Dictionary) -> float:
	var failure_probability := 1.0
	for clothing_slot: String in slots_for_part(part):
		var item_id := str(equipment.get(clothing_slot, ""))
		if not Catalog.is_clothing(item_id):
			continue
		var states: Array = durability.get(item_id, [])
		var condition := float(states[0]) if not states.is_empty() else max_durability(item_id)
		failure_probability *= 1.0 - effective_protection(item_id, condition, wound)
	return clampf(1.0 - failure_probability, 0.0, 0.95)

static func wear_for(wound: String, blocked: bool) -> float:
	return float(WOUND_WEAR.get(wound, 0.0)) * (1.0 if blocked else 0.65)

static func protection_text(item_id: String) -> String:
	if not Catalog.is_clothing(item_id):
		return ""
	var data := Catalog.item(item_id)
	return "擦伤 %d%%  撕裂 %d%%  咬伤 %d%%" % [roundi(float(data.scratch_protection) * 100.0), roundi(float(data.laceration_protection) * 100.0), roundi(float(data.bite_protection) * 100.0)]

static func condition_text(item_id: String, durability: float) -> String:
	return "%d / %d" % [roundi(clampf(durability, 0.0, max_durability(item_id))), roundi(max_durability(item_id))]
