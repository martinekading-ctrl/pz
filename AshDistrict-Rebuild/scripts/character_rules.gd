extends RefCounted

const SkillRules=preload("res://scripts/skill_rules.gd")

const PROFESSION_ORDER:=["survivor","firefighter","nurse","mechanic"]
const PROFESSIONS:={
	"survivor":{"name":"普通幸存者","points":6,"desc":"没有专长，但拥有最多特质点。","items":{},"skills":{},"mods":{}},
	"firefighter":{"name":"消防员","points":2,"desc":"体能 2 级，自带手斧和工作靴。","items":{"hand_axe":1,"work_boots":1},"skills":{"fitness":90},"mods":{"stamina_cost":0.90}},
	"nurse":{"name":"护理员","points":2,"desc":"生存 2 级，自带绷带和消毒剂，治疗效果更好。","items":{"bandage":2,"disinfectant":1},"skills":{"survival":90},"mods":{"medical":1.15}},
	"mechanic":{"name":"维修工","points":2,"desc":"搜索 1 级，自带汽油与胶带，驾车更省油耐撞。","items":{"gas_can":1,"duct_tape":1},"skills":{"scavenging":30},"mods":{"vehicle_fuel":0.85,"vehicle_damage":0.80}},
}

const TRAIT_ORDER:=["strong","athletic","keen_eyes","thirsty","noisy","slow_learner"]
const TRAITS:={
	"strong":{"name":"强壮","cost":4,"desc":"近战伤害 +15%。","mods":{"melee_damage":1.15}},
	"athletic":{"name":"耐力充沛","cost":3,"desc":"体力消耗 -18%，恢复 +12%。","mods":{"stamina_cost":0.82,"stamina_regen":1.12}},
	"keen_eyes":{"name":"观察敏锐","cost":2,"desc":"搜索时间 -20%。","mods":{"search_time":0.80}},
	"thirsty":{"name":"容易口渴","cost":-2,"desc":"口渴增长速度 +30%。","mods":{"thirst":1.30}},
	"noisy":{"name":"动作吵闹","cost":-2,"desc":"行动声音传播范围 +25%。","mods":{"noise":1.25}},
	"slow_learner":{"name":"学习缓慢","cost":-3,"desc":"所有技能经验获取 -25%。","mods":{"xp_gain":0.75}},
}

const DEFAULT_MODIFIERS:={
	"melee_damage":1.0,"stamina_cost":1.0,"stamina_regen":1.0,"search_time":1.0,
	"thirst":1.0,"noise":1.0,"xp_gain":1.0,"medical":1.0,
	"vehicle_fuel":1.0,"vehicle_damage":1.0,
}

static func default_profile() -> Dictionary:
	return {"profession":"survivor","traits":[]}

static func sanitize_profile(value: Variant) -> Dictionary:
	if typeof(value)!=TYPE_DICTIONARY:
		return default_profile()
	var profession:=str(value.get("profession","survivor"))
	if profession not in PROFESSIONS:
		profession="survivor"
	var selected: Array[String]=[]
	var source: Variant=value.get("traits",[])
	if typeof(source)==TYPE_ARRAY:
		for entry: Variant in source:
			var trait_id:=str(entry)
			if trait_id in TRAITS and trait_id not in selected:
				selected.append(trait_id)
	var result:={"profession":profession,"traits":selected}
	while points_remaining(result)<0:
		var removed:=false
		for index in range(selected.size()-1,-1,-1):
			if int(TRAITS[selected[index]].cost)>0:
				selected.remove_at(index)
				removed=true
				break
		if not removed:
			break
	return result

static func points_remaining(profile: Dictionary) -> int:
	var profession:=str(profile.get("profession","survivor"))
	var points:=int(PROFESSIONS.get(profession,PROFESSIONS.survivor).points)
	for trait_id: Variant in profile.get("traits",[]):
		if str(trait_id) in TRAITS:
			points-=int(TRAITS[str(trait_id)].cost)
	return points

static func modifiers(profile: Dictionary) -> Dictionary:
	var result:=DEFAULT_MODIFIERS.duplicate()
	var clean:=sanitize_profile(profile)
	apply_modifiers(result,PROFESSIONS[clean.profession].get("mods",{}))
	for trait_id: String in clean.traits:
		apply_modifiers(result,TRAITS[trait_id].get("mods",{}))
	return result

static func apply_modifiers(target: Dictionary,source: Dictionary) -> void:
	for key: String in source.keys():
		target[key]=float(target.get(key,1.0))*float(source[key])

static func initial_items(profile: Dictionary) -> Dictionary:
	var clean:=sanitize_profile(profile)
	return PROFESSIONS[clean.profession].get("items",{}).duplicate(true)

static func initial_skills(profile: Dictionary) -> Dictionary:
	var result:=SkillRules.fresh_state()
	var clean:=sanitize_profile(profile)
	for skill_id: String in PROFESSIONS[clean.profession].get("skills",{}).keys():
		var xp:=int(PROFESSIONS[clean.profession].skills[skill_id])
		result[skill_id]={"xp":xp,"level":SkillRules.level_for_xp(xp)}
	return result

static func profession_name(profile: Dictionary) -> String:
	var clean:=sanitize_profile(profile)
	return str(PROFESSIONS[clean.profession].name)

static func summary(profile: Dictionary) -> String:
	var clean:=sanitize_profile(profile)
	var names: Array[String]=[]
	for trait_id: String in clean.traits:
		names.append(str(TRAITS[trait_id].name))
	return profession_name(clean)+(" · 无特质" if names.is_empty() else " · "+"、".join(names))
