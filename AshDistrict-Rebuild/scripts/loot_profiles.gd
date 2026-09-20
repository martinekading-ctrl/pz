extends RefCounted

const REVISION := 2

static func additions(building_id: String, title: String, index: int) -> Dictionary:
	var loot := {}
	var roll: int = absi(hash(building_id + ":" + title + ":" + str(index))) % 5
	if "冰箱" in title or "冷柜" in title:
		loot["fresh_food"] = 1 + (1 if roll == 0 else 0)
		loot["canned_soup"] = 1
		if "饮料" in title or roll in [1,3]:
			loot["soda"] = 1 + (1 if "饮料" in title else 0)
	elif "厨房" in title:
		loot["canned_soup"] = 1
		loot["coffee"] = 1 if roll != 4 else 0
	elif "罐头" in title:
		loot["canned_soup"] = 3
	elif "食品" in title:
		loot["energy_bar"] = 2
		loot["fresh_food"] = 1
		loot["coffee"] = 1
	elif "浴" in title or "医" in title:
		loot["disinfectant"] = 1
		if roll in [0,2]:
			loot["antibiotics"] = 1
	elif "衣柜" in title or "衣物" in title:
		loot["denim_jacket" if roll <= 2 else "leather_jacket"] = 1
		loot["jeans" if roll % 2 == 0 else "cargo_pants"] = 1
		loot["sneakers" if roll <= 2 else "work_boots"] = 1
		if roll in [0,3]:
			loot["baseball_cap"] = 1
	elif "储物" in title or "工具" in title or "车库" in title:
		loot["duct_tape"] = 1
		if roll == 0:
			loot["work_boots"] = 1
	elif "收银" in title:
		loot["energy_bar"] = 2
		loot["soda"] = 1
		if roll == 1:
			loot["baseball_cap"] = 1
	elif "餐桌" in title or "沙发" in title:
		if roll <= 1:
			loot["energy_bar"] = 1
	for item_id: String in loot.keys():
		if int(loot[item_id]) <= 0:
			loot.erase(item_id)
	return loot
