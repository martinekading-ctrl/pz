extends RefCounted

const Catalog = preload("res://scripts/item_catalog.gd")
const Backpack = preload("res://scripts/backpack.gd")

const MAX_BARRICADE_LAYERS := 2
const BARRICADE_COST := {"plank":1, "nails":2}
const BARRICADE_TOOLS := ["hammer"]
const REMOVE_TOOLS := ["hammer", "crowbar"]
const RECOVERED_MATERIALS := {"plank":1, "nails":1}
const REPAIR_COST := {"nails":1}

const RECIPES := {
	"rip_cloth":{
		"name":"撕开旧床单",
		"description":"把一张旧床单撕成四条干净布料。",
		"inputs":{"bed_sheet":1},
		"tools":[],
		"outputs":{"ripped_cloth":4},
	},
	"improvised_bandage":{
		"name":"制作简易绷带",
		"description":"用两条撕布制作一份可用绷带。",
		"inputs":{"ripped_cloth":2},
		"tools":[],
		"outputs":{"bandage":1},
	},
}

static func has_items(inventory: Dictionary, required: Dictionary) -> bool:
	for item_id: String in required:
		if int(inventory.get(item_id, 0)) < int(required[item_id]):
			return false
	return true

static func has_any_tool(inventory: Dictionary, tools: Array) -> bool:
	if tools.is_empty():
		return true
	for item_id: String in tools:
		if int(inventory.get(item_id, 0)) > 0:
			return true
	return false

static func can_fit_result(inventory: Dictionary, consumed: Dictionary, granted: Dictionary) -> bool:
	var result := inventory.duplicate(true)
	for item_id: String in consumed:
		result[item_id] = maxi(0, int(result.get(item_id, 0)) - int(consumed[item_id]))
	for item_id: String in granted:
		result[item_id] = int(result.get(item_id, 0)) + int(granted[item_id])
	return Backpack.weight(result) <= Backpack.MAX_WEIGHT + 0.001 and Backpack.slots(result) <= Backpack.MAX_SLOTS

static func craft(inventory: Dictionary, recipe_id: String) -> Dictionary:
	if not RECIPES.has(recipe_id):
		return {"ok":false, "message":"未知配方"}
	var recipe: Dictionary = RECIPES[recipe_id]
	if not has_items(inventory, recipe.inputs):
		return {"ok":false, "message":"材料不足"}
	if not has_any_tool(inventory, recipe.tools):
		return {"ok":false, "message":"缺少所需工具"}
	if not can_fit_result(inventory, recipe.inputs, recipe.outputs):
		return {"ok":false, "message":"背包没有足够容量"}
	apply_delta(inventory, recipe.inputs, -1)
	apply_delta(inventory, recipe.outputs, 1)
	return {"ok":true, "message":"已完成：" + str(recipe.name)}

static func can_build_barricade(inventory: Dictionary) -> Dictionary:
	if not has_any_tool(inventory, BARRICADE_TOOLS):
		return {"ok":false, "message":"需要木工锤"}
	if not has_items(inventory, BARRICADE_COST):
		return {"ok":false, "message":"每层需要 1 木板和 2 钉子"}
	return {"ok":true, "message":"可以施工"}

static func consume_barricade_materials(inventory: Dictionary) -> Dictionary:
	var result := can_build_barricade(inventory)
	if not bool(result.ok):
		return result
	apply_delta(inventory, BARRICADE_COST, -1)
	return {"ok":true, "message":"已加固一层"}

static func can_remove_barricade(inventory: Dictionary) -> Dictionary:
	if not has_any_tool(inventory, REMOVE_TOOLS):
		return {"ok":false, "message":"需要木工锤或撬棍"}
	if not can_fit_result(inventory, {}, RECOVERED_MATERIALS):
		return {"ok":false, "message":"背包没有空间存放拆下的材料"}
	return {"ok":true, "message":"可以拆除"}

static func grant_recovered_materials(inventory: Dictionary) -> Dictionary:
	var result := can_remove_barricade(inventory)
	if not bool(result.ok):
		return result
	apply_delta(inventory, RECOVERED_MATERIALS, 1)
	return {"ok":true, "message":"拆除完成，回收 1 木板和 1 钉子"}

static func repair_barricade(inventory: Dictionary) -> Dictionary:
	if not has_any_tool(inventory,BARRICADE_TOOLS):
		return {"ok":false,"message":"需要木工锤"}
	if not has_items(inventory,REPAIR_COST):
		return {"ok":false,"message":"维修需要 1 枚钉子"}
	apply_delta(inventory,REPAIR_COST,-1)
	return {"ok":true,"message":"外层木板已修好"}

static func apply_delta(inventory: Dictionary, items: Dictionary, direction: int) -> void:
	for item_id: String in items:
		inventory[item_id] = maxi(0, int(inventory.get(item_id, 0)) + direction * int(items[item_id]))

static func item_list(items: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id: String in items:
		parts.append("%s ×%d" % [Catalog.item(item_id).name, int(items[item_id])])
	return "、".join(parts)
