extends RefCounted

const TYPES={
	"fridge":{"label":"冰箱","seconds":1.5,"capacity":15.0},
	"kitchen":{"label":"厨房储物","seconds":2.0,"capacity":20.0},
	"medical":{"label":"卫生用品","seconds":1.0,"capacity":5.0},
	"tools":{"label":"工具储物","seconds":2.5,"capacity":30.0},
	"wardrobe":{"label":"衣物储物","seconds":2.0,"capacity":15.0},
	"general":{"label":"杂物","seconds":1.2,"capacity":10.0}}

static func classify(title: String) -> String:
	if "冰箱" in title: return "fridge"
	if "厨房" in title or "食品" in title: return "kitchen"
	if "浴" in title or "医" in title: return "medical"
	if "工具" in title or "车库" in title: return "tools"
	if "衣柜" in title or "衣物" in title: return "wardrobe"
	return "general"

static func profile(item: Dictionary) -> Dictionary:
	return TYPES[classify(item.title)]

static func duration(item: Dictionary) -> float:
	return .15 if item.get("searched",false) else float(profile(item).seconds)

static func transfer(source: Dictionary,destination: Dictionary,key: String,requested: int,capacity: float,slot_limit: int) -> int:
	var pack=preload("res://scripts/backpack.gd")
	var moved:=0
	while moved<requested and int(source.get(key,0))>0:
		var candidate:=destination.duplicate()
		candidate[key]=int(candidate.get(key,0))+1
		if pack.weight(candidate)>capacity+.001 or pack.slots(candidate)>slot_limit: break
		source[key]-=1
		destination[key]=int(destination.get(key,0))+1
		moved+=1
	return moved
