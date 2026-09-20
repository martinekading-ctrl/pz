extends RefCounted

const CharacterRules=preload("res://scripts/character_rules.gd")
const SaveSystem=preload("res://scripts/save_system.gd")
const Survival=preload("res://scripts/survival_rules.gd")

static func run(game: Node2D) -> void:
	var profile:={"profession":"mechanic","traits":["strong","noisy"]}
	assert(CharacterRules.points_remaining(profile)==0,"Profession and trait points must balance")
	var mods:=CharacterRules.modifiers(profile)
	assert(float(mods.melee_damage)>1.0 and float(mods.noise)>1.0 and float(mods.vehicle_fuel)<1.0,"Profile choices must produce gameplay modifiers")
	game.apply_character_start(profile)
	assert(game.character_profile.profession=="mechanic" and int(game.inventory.gas_can)==1 and int(game.inventory.duct_tape)==1,"Profession must grant its starting kit")
	assert(game.skill_level("scavenging")==1 and is_equal_approx(game.character_modifier("melee_damage"),1.15),"Profession skills and traits must apply")
	var normal:={"health":100.0,"food":100.0,"water":100.0,"stamina":100.0,"fatigue":0.0,"bleeding":0.0,"infection":0.0}
	var thirsty:=normal.duplicate(true)
	Survival.advance(normal,60.0,false,1.0)
	Survival.advance(thirsty,60.0,false,1.3)
	assert(float(thirsty.water)<float(normal.water),"Thirsty trait must increase water loss")
	game.set_character_profile(CharacterRules.sanitize_profile({"profession":"survivor","traits":["slow_learner"]}))
	game.skills=preload("res://scripts/skill_rules.gd").fresh_state()
	game.gain_skill_xp("melee",20)
	assert(int(game.skills.melee.xp)==15,"Slow learner must reduce earned XP")
	game.set_character_profile(CharacterRules.sanitize_profile(profile))
	var state:=SaveSystem.capture_state(game)
	assert(state.character_profile.profession=="mechanic","Character profile must save")
	var legacy:=state.duplicate(true)
	legacy.version=7
	legacy.erase("character_profile")
	var migrated:=SaveSystem.migrate(legacy)
	assert(int(migrated.version)==SaveSystem.SAVE_VERSION and migrated.character_profile.profession=="survivor","Version 7 saves must receive a default profile")
	game.show_product_shell()
	game.product_shell.begin_character_creation(2)
	assert(game.product_shell.current_screen()=="character","New game must enter character creation")
	print("CHARACTER PASS: professions, balanced traits, starting kits, gameplay modifiers, creator and save migration")
	game.get_tree().quit()
