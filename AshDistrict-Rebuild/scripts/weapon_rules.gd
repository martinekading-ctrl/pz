extends RefCounted

const Catalog=preload("res://scripts/item_catalog.gd")
const UNARMED := {"name":"徒手","damage":12,"range":0.82,"swing":0.68,"knockback":0.12,"durability":0.0,"wear":0.0,"visual_length":0.0,"visual_color":"bd9c78"}

static func stats(item_id: String) -> Dictionary:
	return Catalog.item(item_id) if Catalog.is_weapon(item_id) else UNARMED

static func max_durability(item_id: String) -> float:
	return float(stats(item_id).durability)

static func durability_text(item_id: String,current: float) -> String:
	if not Catalog.is_weapon(item_id):
		return "无需耐久"
	return "%d / %d" % [ceili(maxf(0.0,current)),roundi(max_durability(item_id))]

static func apply_wear(item_id: String,current: float) -> float:
	return maxf(0.0,current-float(stats(item_id).wear))

