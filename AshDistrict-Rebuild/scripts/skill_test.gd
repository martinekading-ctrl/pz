extends RefCounted

const SkillRules = preload("res://scripts/skill_rules.gd")
const SaveSystem = preload("res://scripts/save_system.gd")

static func run(game: Node2D) -> void:
	game.simulation_paused = true
	game.player.set_physics_process(false)
	var state := SkillRules.fresh_state()
	var gained := SkillRules.add_xp(state,"melee",90)
	assert(gained.leveled and SkillRules.level(state,"melee")==2,"Cumulative XP must resolve deterministic levels")
	assert(is_equal_approx(SkillRules.melee_damage_multiplier(2),1.10))
	assert(is_equal_approx(SkillRules.search_duration_multiplier(5),0.65))
	assert(is_equal_approx(SkillRules.weapon_wear_multiplier(5),0.70))
	var sanitized := SkillRules.sanitize({"fitness":{"xp":99999,"level":99},"invalid":{"xp":1}})
	assert(SkillRules.level(sanitized,"fitness")==5 and sanitized.size()==4,"Skill state must clamp and reject unknown tracks")

	game.skills = SkillRules.fresh_state()
	game.gain_skill_xp("scavenging",30)
	assert(game.skill_level("scavenging")==1,"Main game must award skill XP")
	var saved := SaveSystem.capture_state(game)
	assert(int(saved.skills.scavenging.level)==1,"Skills must be captured in saves")
	game.skills = SkillRules.fresh_state()
	assert(SaveSystem.apply_state(game,saved) and game.skill_level("scavenging")==1,"Skill XP and levels must survive a save round trip")
	var legacy := saved.duplicate(true)
	legacy.version = 5
	legacy.erase("skills")
	var migrated := SaveSystem.migrate(legacy)
	assert(int(migrated.version)==SaveSystem.SAVE_VERSION and migrated.has("skills"),"Version 5 saves must gain a fresh skill state")
	game.open_skills_panel()
	assert(is_instance_valid(game.skills_overlay) and not game.player.is_physics_processing(),"Skill page must lock movement")
	game.close_skills_panel(false)
	print("SKILL PASS: XP levels, gameplay bonuses, skill UI and save migration")
	game.get_tree().quit()
