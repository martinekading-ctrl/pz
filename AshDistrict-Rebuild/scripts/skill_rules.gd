extends RefCounted

const MAX_LEVEL := 5
const LEVEL_XP := [0, 30, 90, 180, 300, 460]
const ORDER := ["fitness", "melee", "scavenging", "survival"]
const DEFINITIONS := {
	"fitness": {"name":"体能", "icon":"跑", "desc":"奔跑更省体力，停下后恢复更快。"},
	"melee": {"name":"近战", "icon":"击", "desc":"近战命中造成更高伤害。"},
	"scavenging": {"name":"搜索", "icon":"搜", "desc":"搜索容器所需时间更短。"},
	"survival": {"name":"生存", "icon":"生", "desc":"医疗、修理和武器保养效果更好。"},
}

static func fresh_state() -> Dictionary:
	var result := {}
	for skill_id: String in ORDER:
		result[skill_id] = {"xp":0, "level":0}
	return result

static func sanitize(value: Variant) -> Dictionary:
	var result := fresh_state()
	if typeof(value) != TYPE_DICTIONARY:
		return result
	for skill_id: String in ORDER:
		var entry: Variant = value.get(skill_id, {})
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var xp := clampi(int(entry.get("xp",0)),0,LEVEL_XP[MAX_LEVEL])
		result[skill_id] = {"xp":xp, "level":level_for_xp(xp)}
	return result

static func level_for_xp(xp: int) -> int:
	var level := 0
	for index: int in LEVEL_XP.size():
		if xp >= int(LEVEL_XP[index]):
			level = index
	return mini(level,MAX_LEVEL)

static func add_xp(state: Dictionary, skill_id: String, amount: int) -> Dictionary:
	if skill_id not in DEFINITIONS or amount <= 0:
		return {"changed":false,"leveled":false,"before":0,"after":0}
	var entry: Dictionary = state.get(skill_id,{"xp":0,"level":0})
	var before := level_for_xp(int(entry.get("xp",0)))
	var xp := clampi(int(entry.get("xp",0))+amount,0,LEVEL_XP[MAX_LEVEL])
	var after := level_for_xp(xp)
	state[skill_id] = {"xp":xp,"level":after}
	return {"changed":true,"leveled":after>before,"before":before,"after":after,"xp":xp}

static func level(state: Dictionary, skill_id: String) -> int:
	return clampi(int(state.get(skill_id,{}).get("level",0)),0,MAX_LEVEL)

static func level_progress(state: Dictionary, skill_id: String) -> Dictionary:
	var current_level := level(state,skill_id)
	var xp := int(state.get(skill_id,{}).get("xp",0))
	if current_level >= MAX_LEVEL:
		return {"current":1,"required":1,"percent":100.0,"text":"已满级"}
	var floor_xp := int(LEVEL_XP[current_level])
	var ceiling_xp := int(LEVEL_XP[current_level+1])
	var current := xp-floor_xp
	var required := ceiling_xp-floor_xp
	return {"current":current,"required":required,"percent":float(current)/float(required)*100.0,"text":"%d / %d XP" % [current,required]}

static func stamina_cost_multiplier(skill_level: int) -> float:
	return maxf(0.75,1.0-0.05*clampi(skill_level,0,MAX_LEVEL))

static func stamina_regen_multiplier(skill_level: int) -> float:
	return 1.0+0.06*clampi(skill_level,0,MAX_LEVEL)

static func melee_damage_multiplier(skill_level: int) -> float:
	return 1.0+0.05*clampi(skill_level,0,MAX_LEVEL)

static func search_duration_multiplier(skill_level: int) -> float:
	return maxf(0.65,1.0-0.07*clampi(skill_level,0,MAX_LEVEL))

static func treatment_multiplier(skill_level: int) -> float:
	return 1.0+0.08*clampi(skill_level,0,MAX_LEVEL)

static func weapon_wear_multiplier(skill_level: int) -> float:
	return maxf(0.70,1.0-0.06*clampi(skill_level,0,MAX_LEVEL))

static func bonus_text(skill_id: String, skill_level: int) -> String:
	match skill_id:
		"fitness":
			return "体力消耗 -%d%%  ·  恢复 +%d%%" % [skill_level*5,skill_level*6]
		"melee":
			return "近战伤害 +%d%%" % (skill_level*5)
		"scavenging":
			return "搜索时间 -%d%%" % (skill_level*7)
		"survival":
			return "治疗/修理 +%d%%  ·  武器磨损 -%d%%" % [skill_level*8,skill_level*6]
	return ""
