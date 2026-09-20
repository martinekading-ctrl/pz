extends Node2D

const WorldMap = preload("res://scripts/world_map.gd")
const Player = preload("res://scripts/player.gd")
const Zombie = preload("res://scripts/zombie.gd")
const Combat = preload("res://scripts/combat_rules.gd")
const Survival = preload("res://scripts/survival_rules.gd")
const Exertion = preload("res://scripts/exertion_rules.gd")
const InjuryRules = preload("res://scripts/injury_rules.gd")
const Catalog = preload("res://scripts/item_catalog.gd")
const WeaponRules = preload("res://scripts/weapon_rules.gd")
const FirearmRules = preload("res://scripts/firearm_rules.gd")
const CraftingRules = preload("res://scripts/crafting_rules.gd")
const SettingsStore = preload("res://scripts/settings_store.gd")
const SaveSystem = preload("res://scripts/save_system.gd")
const GameInput = preload("res://scripts/game_input.gd")
const MobileControls = preload("res://scripts/mobile_controls.gd")
const Quickbar = preload("res://scripts/quickbar.gd")
const MobileSettingsPanel = preload("res://scripts/mobile_settings_panel.gd")
const HealthPanel = preload("res://scripts/health_panel.gd")
const ZombiePopulation = preload("res://scripts/zombie_population.gd")
const CorpsePanel = preload("res://scripts/corpse_panel.gd")
const CraftingPanel = preload("res://scripts/crafting_panel.gd")
const ProductShell = preload("res://scripts/product_shell.gd")
const LootProfiles = preload("res://scripts/loot_profiles.gd")
const ClothingRules = preload("res://scripts/clothing_rules.gd")
const UtilityRules = preload("res://scripts/utility_rules.gd")
const SkillRules = preload("res://scripts/skill_rules.gd")
const SkillsPanel = preload("res://scripts/skills_panel.gd")
const VehiclePanel = preload("res://scripts/vehicle_panel.gd")
const VehicleRules = preload("res://scripts/vehicle_rules.gd")
const CharacterRules = preload("res://scripts/character_rules.gd")
const PISTOL_SHOT_SOUND = preload("res://art/audio/pistol_shot.wav")
const PISTOL_DRY_SOUND = preload("res://art/audio/pistol_dry.wav")
const SAVE_SLOT_PATH := "user://ash_district_slot_1.json"
const DEFAULT_CAMERA_ZOOM := 0.68
const SLEEP_DURATION_MINUTES := 480.0
const SLEEP_MINUTES_PER_REAL_SECOND := 120.0
const SAFEHOUSE_DANGER_RADIUS_METERS := 8.0

var world_map: Node2D
var player: Node2D
var game_input: Node
var mobile_controls: Control
var quickbar: Control
var mobile_settings_overlay: ColorRect
var health_overlay: ColorRect
var corpse_overlay: ColorRect
var crafting_overlay: ColorRect
var skills_overlay: ColorRect
var vehicle_overlay: ColorRect
var product_shell: ColorRect
var active_save_slot := 1
var game_started := false
var active_corpse: Node2D
var camera: Camera2D
var hud: CanvasLayer
var header_panel: ColorRect
var survival_panel: ColorRect
var status_label: Label
var hint_label: Label
var help_label: Label
var inventory_label: Label
var weapon_label: Label
var utility_label: Label
var clock_label: Label
var condition_label: Label
var health_status_button: Button
var need_bars := {}
var world_tint: CanvasModulate
var loot_overlay: ColorRect
var active_loot := -1
var active_building: Node2D
var search_building: Node2D
var left_items := {}
var searching := -1
var search_time := 0.0
var inventory := {"food":0,"water":0,"empty_bottle":0,"fresh_food":0,"canned_soup":0,"energy_bar":0,"soda":0,"coffee":0,"bandage":0,"painkillers":0,"disinfectant":0,"antibiotics":0,"duct_tape":0,"gas_can":0,"baseball_cap":0,"motorcycle_helmet":0,"denim_jacket":0,"leather_jacket":0,"jeans":0,"cargo_pants":0,"sneakers":0,"work_boots":0,"parts":0,"bed_sheet":0,"ripped_cloth":0,"plank":0,"nails":0,"hammer":0,"pistol_ammo":0,"pistol_magazine":0,"crowbar":1,"baseball_bat":0,"kitchen_knife":0,"hand_axe":0,"pistol":0}
const Backpack=preload("res://scripts/backpack.gd")
var backpack: ColorRect
var ground_items: Array[Dictionary]=[]
var needs:={"health":100.0,"food":82.0,"water":78.0,"stamina":100.0,"fatigue":0.0,"bleeding":0.0,"pain":0.0,"infection":0.0,"pain_relief":0.0}
var injuries: Dictionary = InjuryRules.fresh_state()
var zombies: Array[Node2D]=[]
var player_invulnerability:=0.0
var combat_message:=""
var combat_message_time:=0.0
var game_time_minutes:=3380.0
var fresh_food_expiry_minutes:=6980.0
var power_cutoff_minutes := UtilityRules.DEFAULT_POWER_CUTOFF_MINUTES
var water_cutoff_minutes := UtilityRules.DEFAULT_WATER_CUTOFF_MINUTES
var time_multiplier:=1.0
var simulation_paused:=false
var game_over_overlay: ColorRect
var injury_rng:=RandomNumberGenerator.new()
var survival_clock_enabled:=true
var weapon_durability:={"crowbar":[100.0],"baseball_bat":[],"kitchen_knife":[],"hand_axe":[],"pistol":[]}
var equipment:={"primary":"crowbar","secondary":""}
var clothing_equipment := {"head":"", "torso":"", "legs":"", "feet":""}
var clothing_durability := {"baseball_cap":[],"motorcycle_helmet":[],"denim_jacket":[],"leather_jacket":[],"jeans":[],"cargo_pants":[],"sneakers":[],"work_boots":[]}
var active_weapon_slot:="primary"
var firearm_loaded := {"pistol":0}
var reload_remaining := 0.0
var reload_weapon_id := ""
var shot_sequence := 0
var pistol_audio_pool: Array[AudioStreamPlayer] = []
var pistol_dry_player: AudioStreamPlayer
var stamina_recovery_delay := 0.0
var footstep_noise_timer := 0.0
var last_noise := {}
var population_enabled := false
var population_timer := ZombiePopulation.RESPAWN_INTERVAL_SECONDS
var population_respawn_budget := ZombiePopulation.RESPAWN_BUDGET
var population_seed_cursor := 0
var population_next_id := 0
var safehouse_building_id := ""
var safehouse_spawn_logical := Vector2.ZERO
var last_player_building_id := ""
var sleeping := false
var sleep_elapsed_minutes := 0.0
var sleep_overlay: ColorRect
var sleep_clock_label: Label
var sleep_progress: ProgressBar
var autosave_cooldown := 0.0
var autosave_path_override := ""
var skills: Dictionary = SkillRules.fresh_state()
var fitness_xp_seconds := 0.0
var active_vehicle: Node2D
var character_profile: Dictionary = CharacterRules.default_profile()
var character_modifiers_cache: Dictionary = CharacterRules.DEFAULT_MODIFIERS.duplicate()

func _ready() -> void:
	get_tree().auto_accept_quit = false
	DisplayServer.window_set_title("余烬街区：重建版 · 职业与特质 0.31")
	injury_rng.randomize()
	survival_clock_enabled=OS.get_cmdline_user_args().is_empty()
	GameInput.install_default_actions()
	setup_firearm_audio()
	SettingsStore.apply(SettingsStore.load_values(),DisplayServer.get_name() != "headless")
	game_input = GameInput.new()
	add_child(game_input)
	world_map = WorldMap.new()
	world_map.name = "WorldMap"
	add_child(world_map)
	for vehicle: Node2D in world_map.vehicles:
		vehicle.game=self
		vehicle.controls=game_input
	seed_weapon_loot()
	seed_expanded_loot()
	world_tint=CanvasModulate.new()
	world_tint.color=Survival.light_color(game_time_minutes)
	add_child(world_tint)
	player = Player.new()
	player.world_map = world_map
	player.controls = game_input
	player.request_attack_stamina = try_spend_attack_stamina
	player.request_firearm_shot = try_fire_active_weapon
	player.position = world_map.map_to_world(Vector2(36,49))
	add_child(player)
	InjuryRules.sync_needs(injuries, needs)
	refresh_equipped_weapon()
	player.melee_impact.connect(_on_player_melee_impact)
	if should_spawn_zombies():
		spawn_zombies()
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2.ONE * DEFAULT_CAMERA_ZOOM
	camera.position = Vector2(0,-90)
	player.add_child(camera)
	create_hud()
	create_mobile_controls()
	var saved_settings := SettingsStore.load_values()
	mobile_controls.apply_layout_preset(str(saved_settings.mobile_layout),false)
	if "--container-test" in OS.get_cmdline_user_args() or "--container-capture" in OS.get_cmdline_user_args(): call_deferred("run_container_test")
	if "--backpack-preview" in OS.get_cmdline_user_args(): call_deferred("open_backpack")
	if "--backpack-test" in OS.get_cmdline_user_args() or "--backpack-capture" in OS.get_cmdline_user_args(): call_deferred("backpack_test")
	if "--player-test" in OS.get_cmdline_user_args(): call_deferred("run_player_controls_test")
	if "--catalog-preview" in OS.get_cmdline_user_args(): call_deferred("catalog_preview")
	if "--catalog-capture" in OS.get_cmdline_user_args(): call_deferred("catalog_capture")
	if "--expansion-test" in OS.get_cmdline_user_args() or "--expansion-capture" in OS.get_cmdline_user_args(): call_deferred("run_expansion_test")
	if "--standard-test" in OS.get_cmdline_user_args() or "--standard-capture" in OS.get_cmdline_user_args(): call_deferred("run_standard_test")
	if "--layout-test" in OS.get_cmdline_user_args(): call_deferred("layout_test")
	if "--house-test" in OS.get_cmdline_user_args(): call_deferred("run_house_flow",false)
	if "--flow-capture" in OS.get_cmdline_user_args(): call_deferred("run_house_flow",true)
	if "--store-test" in OS.get_cmdline_user_args(): call_deferred("run_store_flow",false)
	if "--store-capture" in OS.get_cmdline_user_args(): call_deferred("run_store_flow",true)
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("capture")
	if "--house-capture" in OS.get_cmdline_user_args(): call_deferred("house_capture")
	if "--b01-capture" in OS.get_cmdline_user_args(): call_deferred("b01_capture")
	if "--b01-test" in OS.get_cmdline_user_args(): call_deferred("run_b01_test")
	if "--b01-preview" in OS.get_cmdline_user_args(): call_deferred("b01_preview")
	if "--combat-test" in OS.get_cmdline_user_args(): call_deferred("run_combat_test")
	if "--combat-capture" in OS.get_cmdline_user_args(): call_deferred("combat_capture")
	if "--survival-test" in OS.get_cmdline_user_args(): call_deferred("run_survival_test")
	if "--survival-capture" in OS.get_cmdline_user_args(): call_deferred("survival_capture")
	if "--weapon-test" in OS.get_cmdline_user_args(): call_deferred("run_weapon_test")
	if "--weapon-capture" in OS.get_cmdline_user_args(): call_deferred("weapon_capture")
	if "--save-test" in OS.get_cmdline_user_args(): call_deferred("run_save_test")
	if "--mobile-test" in OS.get_cmdline_user_args(): call_deferred("run_mobile_test")
	if "--mobile-capture" in OS.get_cmdline_user_args(): call_deferred("mobile_capture")
	if "--settings-capture" in OS.get_cmdline_user_args(): call_deferred("mobile_settings_capture")
	if "--exertion-test" in OS.get_cmdline_user_args(): call_deferred("run_exertion_test")
	if "--exertion-capture" in OS.get_cmdline_user_args(): call_deferred("exertion_capture")
	if "--injury-test" in OS.get_cmdline_user_args(): call_deferred("run_injury_test")
	if "--injury-capture" in OS.get_cmdline_user_args(): call_deferred("injury_capture")
	if "--population-test" in OS.get_cmdline_user_args(): call_deferred("run_population_test")
	if "--population-capture" in OS.get_cmdline_user_args(): call_deferred("population_capture")
	if "--firearm-test" in OS.get_cmdline_user_args(): call_deferred("run_firearm_test")
	if "--firearm-capture" in OS.get_cmdline_user_args(): call_deferred("firearm_capture")
	if "--firearm-preview" in OS.get_cmdline_user_args(): call_deferred("firearm_preview")
	if "--crafting-test" in OS.get_cmdline_user_args(): call_deferred("run_crafting_test")
	if "--crafting-capture" in OS.get_cmdline_user_args(): call_deferred("crafting_capture")
	if "--crafting-preview" in OS.get_cmdline_user_args(): call_deferred("crafting_preview")
	if "--product-test" in OS.get_cmdline_user_args(): call_deferred("run_product_test")
	if "--barrier-test" in OS.get_cmdline_user_args(): call_deferred("run_barrier_test")
	if "--barrier-capture" in OS.get_cmdline_user_args(): call_deferred("barrier_capture")
	if "--safehouse-test" in OS.get_cmdline_user_args(): call_deferred("run_safehouse_test")
	if "--safehouse-capture" in OS.get_cmdline_user_args(): call_deferred("safehouse_capture")
	if "--loot-test" in OS.get_cmdline_user_args(): call_deferred("run_loot_test")
	if "--loot-capture" in OS.get_cmdline_user_args(): call_deferred("loot_capture")
	if "--clothing-test" in OS.get_cmdline_user_args(): call_deferred("run_clothing_test")
	if "--clothing-capture" in OS.get_cmdline_user_args(): call_deferred("clothing_capture")
	if "--utility-test" in OS.get_cmdline_user_args(): call_deferred("run_utility_test")
	if "--utility-capture" in OS.get_cmdline_user_args(): call_deferred("utility_capture")
	if "--skill-test" in OS.get_cmdline_user_args(): call_deferred("run_skill_test")
	if "--skill-capture" in OS.get_cmdline_user_args(): call_deferred("skill_capture")
	if "--vehicle-test" in OS.get_cmdline_user_args(): call_deferred("run_vehicle_test")
	if "--vehicle-capture" in OS.get_cmdline_user_args(): call_deferred("vehicle_capture")
	if "--character-test" in OS.get_cmdline_user_args(): call_deferred("run_character_test")
	if "--character-capture" in OS.get_cmdline_user_args(): call_deferred("character_capture")
	if "--product-capture" in OS.get_cmdline_user_args(): call_deferred("product_capture")
	if OS.get_cmdline_user_args().is_empty() or "--product-preview" in OS.get_cmdline_user_args(): call_deferred("show_product_shell")

func create_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	header_panel = ColorRect.new()
	header_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	header_panel.position = Vector2(20,20)
	header_panel.size = Vector2(760,76)
	header_panel.color = Color(0.035,0.055,0.045,0.88)
	hud.add_child(header_panel)
	var title := Label.new()
	title.position = Vector2(18,11)
	title.text = "余烬街区 · 生存测试版 0.31"
	title.add_theme_font_size_override("font_size",22)
	header_panel.add_child(title)
	help_label = Label.new()
	help_label.position = Vector2(18,43)
	help_label.text = "WASD 移动 · E 交互 · K 制作 · 右键瞄准/左键射击 · R 装填 · F5 保存 · F9 读取"
	help_label.add_theme_color_override("font_color",Color("bdcbb5"))
	header_panel.add_child(help_label)
	status_label = Label.new()
	status_label.name = "Status"
	status_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	status_label.offset_left = 20
	status_label.offset_top = -38
	status_label.offset_right = 470
	status_label.offset_bottom = -10
	status_label.text = "地图：512×576 格   区块：32×32 格   当前：0,0"
	hud.add_child(status_label)
	hint_label = Label.new()
	hint_label.anchor_left = 0.28
	hint_label.anchor_right = 0.72
	hint_label.anchor_top = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_top = -72
	hint_label.offset_bottom = -36
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size",20)
	hint_label.add_theme_color_override("font_color",Color("d8e5ad"))
	hud.add_child(hint_label)
	inventory_label = Label.new()
	inventory_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inventory_label.offset_left = -380
	inventory_label.offset_top = 112
	inventory_label.offset_right = -20
	inventory_label.offset_bottom = 138
	inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inventory_label.add_theme_font_size_override("font_size",17)
	hud.add_child(inventory_label)
	weapon_label=Label.new()
	weapon_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	weapon_label.offset_left = -380
	weapon_label.offset_top = 140
	weapon_label.offset_right = -20
	weapon_label.offset_bottom = 166
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_label.add_theme_font_size_override("font_size",17)
	weapon_label.add_theme_color_override("font_color",Color("d9c681"))
	hud.add_child(weapon_label)
	utility_label=Label.new()
	utility_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	utility_label.offset_left=-440
	utility_label.offset_top=170
	utility_label.offset_right=-20
	utility_label.offset_bottom=220
	utility_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	utility_label.add_theme_font_size_override("font_size",15)
	utility_label.add_theme_color_override("font_color",Color("a9c9c2"))
	hud.add_child(utility_label)
	survival_panel=ColorRect.new()
	survival_panel.position=Vector2(20,108)
	survival_panel.size=Vector2(330,202)
	survival_panel.color=Color(0.035,0.055,0.045,0.88)
	hud.add_child(survival_panel)
	clock_label=Label.new()
	clock_label.position=Vector2(16,10)
	clock_label.add_theme_font_size_override("font_size",20)
	survival_panel.add_child(clock_label)
	create_need_bar(survival_panel,"health","生命",42,Color("c85858"))
	create_need_bar(survival_panel,"food","饱食",70,Color("c79b47"))
	create_need_bar(survival_panel,"water","水分",98,Color("4e91c9"))
	create_need_bar(survival_panel,"stamina","体力",126,Color("65a66d"))
	condition_label=Label.new()
	condition_label.position=Vector2(16,160)
	condition_label.add_theme_font_size_override("font_size",17)
	survival_panel.add_child(condition_label)
	health_status_button = Button.new()
	health_status_button.name = "HealthStatusButton"
	health_status_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_status_button.text = ""
	health_status_button.tooltip_text = "打开健康与治疗页面"
	health_status_button.focus_mode = Control.FOCUS_NONE
	health_status_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	health_status_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	health_status_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	health_status_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	health_status_button.pressed.connect(open_health_panel)
	survival_panel.add_child(health_status_button)
	update_survival_hud()

func create_mobile_controls() -> void:
	mobile_controls = MobileControls.new()
	mobile_controls.name = "MobileControls"
	mobile_controls.game = self
	mobile_controls.game_input = game_input
	hud.add_child(mobile_controls)
	var args := OS.get_cmdline_user_args()
	mobile_controls.visible = args.is_empty() or "--mobile-preview" in args or "--mobile-test" in args or "--mobile-capture" in args or "--settings-capture" in args or "--exertion-capture" in args or "--injury-capture" in args or "--population-capture" in args or "--firearm-capture" in args or "--firearm-preview" in args or "--crafting-preview" in args or "--safehouse-capture" in args
	if mobile_controls.visible:
		apply_compact_mobile_hud()
	quickbar = Quickbar.new()
	quickbar.name = "Quickbar"
	quickbar.game = self
	quickbar.visible = mobile_controls.visible
	hud.add_child(quickbar)

func apply_compact_mobile_hud() -> void:
	# The phone HUD keeps only information needed during play; controls are taught once in onboarding.
	header_panel.visible = false
	status_label.visible = false
	inventory_label.visible = false
	weapon_label.visible = false
	utility_label.visible = false
	hint_label.offset_top = -150
	hint_label.offset_bottom = -116
	survival_panel.position = Vector2(18,18)
	survival_panel.size = Vector2(272,152)
	survival_panel.color = Color(0.025,0.045,0.035,0.74)
	clock_label.position = Vector2(12,7)
	clock_label.add_theme_font_size_override("font_size",17)
	var rows := {"health":39.0,"food":63.0,"water":87.0,"stamina":111.0}
	for key: String in rows:
		var row: Dictionary = need_bars[key]
		var name_label: Label = row["name"]
		var bar: ProgressBar = row["bar"]
		var value_label: Label = row["label"]
		name_label.position = Vector2(12,rows[key]-6.0)
		name_label.size = Vector2(42,22)
		name_label.add_theme_font_size_override("font_size",14)
		bar.position = Vector2(54,rows[key])
		bar.size = Vector2(156,12)
		value_label.position = Vector2(218,rows[key]-7.0)
		value_label.size = Vector2(42,22)
		value_label.add_theme_font_size_override("font_size",14)
	condition_label.position = Vector2(12,132)
	condition_label.size = Vector2(248, 20)
	condition_label.clip_text = true
	condition_label.add_theme_font_size_override("font_size",13)

func create_need_bar(parent: Control,key: String,title_text: String,y: float,color: Color) -> void:
	var name_label:=Label.new()
	name_label.position=Vector2(16,y-3)
	name_label.size=Vector2(54,24)
	name_label.text=title_text
	parent.add_child(name_label)
	var bar:=ProgressBar.new()
	bar.position=Vector2(72,y)
	bar.size=Vector2(190,16)
	bar.min_value=0
	bar.max_value=100
	bar.show_percentage=false
	var background:=StyleBoxFlat.new()
	background.bg_color=Color("18201d")
	background.border_color=Color("6e786c")
	background.set_border_width_all(1)
	bar.add_theme_stylebox_override("background",background)
	var fill:=StyleBoxFlat.new()
	fill.bg_color=color
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	var value_label:=Label.new()
	value_label.position=Vector2(270,y-4)
	value_label.size=Vector2(50,24)
	parent.add_child(value_label)
	need_bars[key]={"name":name_label,"bar":bar,"label":value_label}

func _process(delta: float) -> void:
	if world_map == null or player == null or world_map.blue_house == null:
		return
	var simulation_delta:=0.0 if simulation_paused or int(needs.health)<=0 else delta
	if simulation_delta>0.0:
		update_firearm_reload(simulation_delta)
		update_zombie_population(simulation_delta)
		if sleeping:
			update_sleep(simulation_delta)
		else:
			update_exertion(simulation_delta)
			update_movement_noise(simulation_delta)
		if survival_clock_enabled and not sleeping:
			advance_survival(simulation_delta)
		autosave_cooldown = maxf(0.0, autosave_cooldown - simulation_delta)
	if is_instance_valid(active_vehicle):
		player.position=active_vehicle.position
		player.update_depth()
	for building in world_map.interactive_buildings: building.update_player(player.position,delta)
	update_world_lighting()
	update_safehouse_entry()
	player_invulnerability=maxf(0.0,player_invulnerability-simulation_delta)
	combat_message_time=maxf(0.0,combat_message_time-simulation_delta)
	if searching >= 0:
		if search_building.nearest_furniture(player.position)!=searching:
			searching=-1
			refresh_player_control()
			return
		search_time += simulation_delta
		var duration: float=preload("res://scripts/container_rules.gd").duration(search_building.furniture[searching]) * SkillRules.search_duration_multiplier(skill_level("scavenging")) * character_modifier("search_time")
		hint_label.text = ("已暂停 · 空格继续" if simulation_paused else "正在搜索… %d%%  ·  Esc 取消" % mini(100,int(search_time/duration*100.0)))
		if search_time >= duration:
			var target := searching
			searching = -1
			open_loot(target,search_building)
			return
	var status := get_node_or_null("HUD/Status") as Label
	if status: status.text = "地图：512×576 格   区块：32×32 格   当前："+str(world_map.chunk_of_world(player.position))
	var vehicle_nearby := nearest_vehicle()
	var corpse_nearby := nearest_searchable_corpse()
	update_corpse_highlights(corpse_nearby)
	var nearby_building: Node2D = world_map.building_near(player.position)
	var nearby: int = nearby_building.nearest_furniture(player.position)
	var nearby_window: int = nearby_building.nearest_window(player.position)
	var context_hint := ""
	if is_instance_valid(active_vehicle):
		context_hint = "E 下车  ·  W/S 油门与倒车  ·  A/D 转向"
	elif vehicle_nearby != null:
		context_hint = "E 检查「%s」" % vehicle_nearby.display_name
	elif corpse_nearby != null:
		context_hint = "E 搜索尸体"
	elif nearby >= 0:
		context_hint = "E 搜索「" + nearby_building.item_title(nearby) + "」"
	elif nearby_window >= 0:
		var layers: int = nearby_building.barricade_layers(nearby_window)
		var window_state: String=nearby_building.window_state(nearby_window)
		context_hint = "E 窗户操作 · %s · 木板 %d/%d" % [{"closed":"关闭","open":"打开","broken":"破碎"}.get(window_state,window_state),layers,CraftingRules.MAX_BARRICADE_LAYERS]
	elif nearby_building.near_door(player.position):
		var nearby_door: Node2D=nearby_building.nearest_door_component(player.position)
		context_hint = "门已损坏" if nearby_door.broken else ("E 关门" if nearby_door.opened else "E 开门")
	hint_label.text = "游戏已暂停" if simulation_paused else (combat_message if combat_message_time > 0.0 else context_hint)
	inventory_label.text = "背包  罐头 %d  水 %d  绷带 %d  零件 %d" % [inventory.food,inventory.water,inventory.bandage,inventory.parts]
	update_weapon_hud()
	update_survival_hud()

func advance_survival(real_delta: float) -> void:
	var game_minutes:=real_delta*Survival.GAME_MINUTES_PER_REAL_SECOND*time_multiplier
	advance_world_time(game_minutes)
	InjuryRules.advance(injuries, needs, game_minutes)
	Survival.advance(needs,game_minutes,player.running and player.moving,character_modifier("thirst"))
	update_player_condition_effects()
	if int(needs.health)<=0:
		show_game_over()

func power_available() -> bool:
	return UtilityRules.power_on(game_time_minutes,power_cutoff_minutes)

func water_available() -> bool:
	return UtilityRules.water_on(game_time_minutes,water_cutoff_minutes)

func advance_world_time(minutes: float) -> void:
	if minutes <= 0.0:
		return
	var had_power := power_available()
	var had_water := water_available()
	game_time_minutes += minutes
	if had_power and not power_available():
		fresh_food_expiry_minutes = minf(fresh_food_expiry_minutes,game_time_minutes+UtilityRules.OUTAGE_FRESH_FOOD_GRACE_MINUTES)
		show_combat_message("全区停电 · 冰箱停止制冷",2.8)
	if had_water and not water_available():
		show_combat_message("全区停水 · 水龙头已经干涸",2.8)
	update_world_lighting()

func update_world_lighting() -> void:
	if not is_instance_valid(world_tint):
		return
	var base := Survival.light_color(game_time_minutes)
	var inside := not current_player_building_id().is_empty()
	world_tint.color = UtilityRules.darken_for_unpowered_interior(base,game_time_minutes,inside,power_available())

func update_survival_hud() -> void:
	if not is_instance_valid(clock_label):
		return
	var clock:=Survival.clock_parts(game_time_minutes)
	var phase:="夜晚" if int(clock.hour)<6 or int(clock.hour)>=20 else ("清晨" if int(clock.hour)<9 else ("傍晚" if int(clock.hour)>=17 else "白昼"))
	var speed_text:="睡眠" if sleeping else ("暂停" if simulation_paused else ("%d×" % roundi(time_multiplier)))
	clock_label.text="第 %d 天  %02d:%02d  %s  %s" % [clock.day,clock.hour,clock.minute,phase,speed_text]
	for key: String in ["health","food","water","stamina"]:
		need_bars[key].bar.value=clampf(float(needs.get(key,100.0)),0.0,100.0)
		need_bars[key].label.text=str(roundi(float(needs.get(key,100.0))))
	var safehouse_text := "  ·  安全屋" if not safehouse_building_id.is_empty() and current_player_building_id() == safehouse_building_id else ""
	condition_label.text=Survival.condition_text(needs) + safehouse_text + ("  ·  点击治疗" if is_instance_valid(mobile_controls) and mobile_controls.visible else "")
	if is_instance_valid(mobile_controls) and mobile_controls.visible:
		condition_label.text += " · 电%s 水%s" % ["✓" if power_available() else "×","✓" if water_available() else "×"]
	if is_instance_valid(utility_label):
		utility_label.text = UtilityRules.service_text("供电",power_available(),power_cutoff_minutes)+"\n"+UtilityRules.service_text("供水",water_available(),water_cutoff_minutes)
	var condition_warning := minf(float(needs.food),float(needs.water))<25.0 or float(needs.get("fatigue",0.0))>=70.0 or float(needs.get("stamina",100.0))<=10.0
	condition_label.add_theme_color_override("font_color",Color("e0786d") if float(needs.get("bleeding",0.0))>0.0 or float(needs.get("infection",0.0))>=60.0 else (Color("e0bd69") if condition_warning or float(needs.get("pain",0.0))>=40.0 else Color("b9c9b6")))

func update_exertion(real_delta: float) -> void:
	var running_now: bool = bool(player.running and player.moving)
	var fitness_level := skill_level("fitness")
	stamina_recovery_delay = Exertion.advance_stamina(needs, real_delta, running_now, stamina_recovery_delay, SkillRules.stamina_cost_multiplier(fitness_level)*character_modifier("stamina_cost"), SkillRules.stamina_regen_multiplier(fitness_level)*character_modifier("stamina_regen"))
	if running_now:
		fitness_xp_seconds += real_delta
		while fitness_xp_seconds >= 4.0:
			fitness_xp_seconds -= 4.0
			gain_skill_xp("fitness",1)
	update_player_condition_effects()

func update_player_condition_effects() -> void:
	player.survival_speed_multiplier = Survival.movement_multiplier(needs) * Exertion.fatigue_speed_multiplier(needs) * InjuryRules.movement_multiplier(injuries, needs)
	player.run_allowed = Survival.can_run(needs) and Exertion.can_run(needs)
	var stats := active_weapon_stats()
	player.weapon_swing_seconds = float(stats.swing) * InjuryRules.attack_duration_multiplier(injuries, needs)

func try_spend_attack_stamina() -> bool:
	var item_id := active_weapon_id()
	var weight := float(Catalog.item(item_id).get("weight", 0.0)) if not item_id.is_empty() else 0.0
	var cost := Exertion.attack_cost(weight) * InjuryRules.attack_stamina_multiplier(injuries) * SkillRules.stamina_cost_multiplier(skill_level("fitness")) * character_modifier("stamina_cost")
	if not Exertion.spend_attack(needs, cost):
		combat_message = "体力不足"
		combat_message_time = 0.8
		return false
	stamina_recovery_delay = maxf(stamina_recovery_delay, Exertion.RECOVERY_DELAY_SECONDS)
	emit_world_sound(player.position, 6.0 + weight, "melee")
	return true

func update_movement_noise(real_delta: float) -> void:
	if not player.moving:
		footstep_noise_timer = 0.0
		return
	footstep_noise_timer -= real_delta
	if footstep_noise_timer > 0.0:
		return
	var radius := Exertion.movement_noise_radius(player.running, player.crouching)
	emit_world_sound(player.position, radius, "footstep")
	footstep_noise_timer = Exertion.movement_noise_interval(player.running, player.crouching)

func emit_world_sound(source: Vector2, radius_meters: float, kind: String) -> int:
	if kind not in ["vehicle","vehicle_crash"]:
		radius_meters*=character_modifier("noise")
	var listeners := 0
	for zombie: Node2D in zombies:
		if zombie.hear_sound(source, radius_meters):
			listeners += 1
	last_noise = {"position":source, "radius":radius_meters, "kind":kind, "listeners":listeners}
	return listeners

func rest_at_bed() -> Dictionary:
	if active_building == null or active_loot < 0 or active_loot >= active_building.furniture.size():
		return {"rested":false, "started":false, "message":"需要靠近一张床"}
	if "床" not in str(active_building.furniture[active_loot].title):
		return {"rested":false, "started":false, "message":"这里只能搜索，不能睡觉"}
	var sleep_check: Dictionary = Survival.can_sleep(needs)
	if not bool(sleep_check.ok):
		return {"rested":false, "started":false, "message":str(sleep_check.message)}
	var danger := sleep_danger_reason()
	if not danger.is_empty():
		return {"rested":false, "started":false, "message":danger}
	sleeping = true
	sleep_elapsed_minutes = 0.0
	close_loot()
	create_sleep_overlay()
	refresh_player_control()
	update_survival_hud()
	return {"rested":false, "started":true, "message":"正在睡眠……"}

func claim_safehouse_at_bed() -> Dictionary:
	if active_building == null or active_loot < 0 or active_loot >= active_building.furniture.size():
		return {"ok":false, "message":"需要靠近一张床"}
	var bed: Dictionary = active_building.furniture[active_loot]
	if "床" not in str(bed.title):
		return {"ok":false, "message":"只有带床的住宅可以设为安全屋"}
	if building_has_living_zombie(active_building):
		return {"ok":false, "message":"屋内仍有僵尸，无法设为安全屋"}
	safehouse_building_id = str(active_building.name)
	safehouse_spawn_logical = (bed.use_zone as Rect2).get_center()
	last_player_building_id = safehouse_building_id
	var saved := autosave_game("安全屋已设定")
	return {"ok":bool(saved.ok), "message":"已设为安全屋并自动保存" if bool(saved.ok) else "安全屋已设定，但自动保存失败"}

func is_safehouse(building: Node2D) -> bool:
	return is_instance_valid(building) and not safehouse_building_id.is_empty() and str(building.name) == safehouse_building_id

func building_has_living_zombie(building: Node2D) -> bool:
	for zombie: Node2D in zombies:
		if not zombie.is_dead() and world_map.building_containing(zombie.position) == building:
			return true
	return false

func sleep_danger_reason() -> String:
	for zombie: Node2D in zombies:
		if not zombie.is_dead() and Combat.distance_meters(world_map, player.position, zombie.position) <= SAFEHOUSE_DANGER_RADIUS_METERS:
			return "附近有危险，无法睡觉"
	return ""

func update_sleep(real_delta: float) -> void:
	if not sleeping:
		return
	var danger := sleep_danger_reason()
	if not danger.is_empty():
		interrupt_sleep("你被附近的动静惊醒了")
		return
	var remaining := SLEEP_DURATION_MINUTES - sleep_elapsed_minutes
	var advanced := minf(remaining, real_delta * SLEEP_MINUTES_PER_REAL_SECOND)
	Survival.sleep_step(needs, advanced)
	InjuryRules.advance(injuries, needs, advanced)
	sleep_elapsed_minutes += advanced
	advance_world_time(advanced)
	update_sleep_overlay()
	update_survival_hud()
	if int(needs.health) <= 0:
		finish_sleep(true, "你没能从睡眠中醒来")
		show_game_over()
	elif sleep_elapsed_minutes >= SLEEP_DURATION_MINUTES - 0.01:
		Survival.finish_sleep(needs)
		finish_sleep(false, "睡眠完成 · 新的一天开始了")

func interrupt_sleep(reason: String) -> void:
	if sleeping:
		finish_sleep(true, reason)

func finish_sleep(interrupted: bool, message: String) -> void:
	sleeping = false
	if is_instance_valid(sleep_overlay):
		sleep_overlay.hide()
		sleep_overlay.queue_free()
	sleep_overlay = null
	sleep_clock_label = null
	sleep_progress = null
	stamina_recovery_delay = 0.0
	update_player_condition_effects()
	update_survival_hud()
	refresh_player_control()
	show_combat_message(message, 2.4)
	if not interrupted:
		autosave_game("睡眠完成")

func create_sleep_overlay() -> void:
	if is_instance_valid(sleep_overlay):
		return
	sleep_overlay = ColorRect.new()
	sleep_overlay.name = "SleepOverlay"
	sleep_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sleep_overlay.color = Color(0.015,0.025,0.035,0.88)
	sleep_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(sleep_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sleep_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520,210)
	panel.add_theme_stylebox_override("panel", panel_style())
	center.add_child(panel)
	var margin := MarginContainer.new()
	for edge: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+edge,24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	margin.add_child(column)
	var title := Label.new()
	title.text = "正在睡眠"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",30)
	column.add_child(title)
	sleep_clock_label = Label.new()
	sleep_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sleep_clock_label.add_theme_font_size_override("font_size",21)
	column.add_child(sleep_clock_label)
	sleep_progress = ProgressBar.new()
	sleep_progress.min_value = 0.0
	sleep_progress.max_value = SLEEP_DURATION_MINUTES
	sleep_progress.show_percentage = false
	sleep_progress.custom_minimum_size = Vector2(460,18)
	column.add_child(sleep_progress)
	var note := Label.new()
	note.text = "时间正在推进；危险靠近或门窗遭到撞击会惊醒你。"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color",Color("b9c9c2"))
	column.add_child(note)
	update_sleep_overlay()

func update_sleep_overlay() -> void:
	if not is_instance_valid(sleep_clock_label) or not is_instance_valid(sleep_progress):
		return
	var clock := Survival.clock_parts(game_time_minutes)
	sleep_clock_label.text = "第 %d 天  %02d:%02d  ·  已睡 %.1f 小时" % [clock.day,clock.hour,clock.minute,sleep_elapsed_minutes/60.0]
	sleep_progress.value = sleep_elapsed_minutes

func gameplay_blocked() -> bool:
	# Inventory and search screens do not pause the simulation.
	return simulation_paused or int(needs.health)<=0

func refresh_player_control() -> void:
	var modal_open:=sleeping or is_instance_valid(backpack) or is_instance_valid(loot_overlay) or is_instance_valid(corpse_overlay) or is_instance_valid(crafting_overlay) or is_instance_valid(skills_overlay) or is_instance_valid(vehicle_overlay) or is_instance_valid(product_shell) or is_instance_valid(mobile_settings_overlay) or is_instance_valid(health_overlay) or searching>=0
	var gameplay_enabled := not simulation_paused and int(needs.health)>0 and not modal_open
	player.set_physics_process(gameplay_enabled and not is_instance_valid(active_vehicle))
	if not gameplay_enabled:
		player.running = false
		player.moving = false
	if is_instance_valid(game_input) and not gameplay_enabled:
		game_input.clear_transient()
	if is_instance_valid(mobile_controls):
		mobile_controls.set_gameplay_enabled(gameplay_enabled)
		mobile_controls.set_vehicle_mode(is_instance_valid(active_vehicle))
	if is_instance_valid(quickbar):
		quickbar.set_interactive(gameplay_enabled and not is_instance_valid(active_vehicle))
	if is_instance_valid(world_map):
		for vehicle: Node2D in world_map.vehicles:
			vehicle.driving_enabled=gameplay_enabled and vehicle==active_vehicle

func current_player_building_id() -> String:
	var building: Node2D = world_map.building_containing(player.position) if is_instance_valid(world_map) and is_instance_valid(player) else null
	return str(building.name) if is_instance_valid(building) else ""

func nearest_vehicle(max_distance_meters: float=2.0) -> Node2D:
	if not is_instance_valid(world_map):
		return null
	var nearest: Node2D
	var best:=max_distance_meters
	for vehicle: Node2D in world_map.vehicles:
		var distance: float=vehicle.interaction_distance_meters(player.position)
		if distance<=best:
			best=distance
			nearest=vehicle
	return nearest

func update_safehouse_entry() -> void:
	if not game_started or sleeping or safehouse_building_id.is_empty():
		last_player_building_id = current_player_building_id()
		return
	var current_id := current_player_building_id()
	if current_id == safehouse_building_id and last_player_building_id != safehouse_building_id and autosave_cooldown <= 0.0:
		autosave_game("进入安全屋")
	last_player_building_id = current_id

func set_simulation_paused(value: bool) -> void:
	if int(needs.health)<=0:
		return
	simulation_paused=value
	refresh_player_control()
	update_survival_hud()

func should_spawn_zombies() -> bool:
	var args := OS.get_cmdline_user_args()
	var isolated_modes := [
		"--container-test", "--container-capture", "--backpack-test", "--backpack-capture",
		"--backpack-preview", "--player-test", "--catalog-preview", "--catalog-capture",
		"--expansion-test", "--expansion-capture", "--standard-test", "--standard-capture",
		"--layout-test", "--house-test", "--flow-capture", "--store-test", "--store-capture",
		"--capture", "--house-capture", "--b01-capture", "--b01-test", "--b01-preview",
		"--survival-test", "--survival-capture", "--weapon-test", "--weapon-capture", "--save-test",
		"--mobile-test", "--mobile-capture", "--settings-capture",
		"--injury-test", "--injury-capture", "--crafting-test", "--crafting-capture", "--crafting-preview",
		"--product-test", "--product-capture", "--product-preview",
		"--safehouse-test", "--safehouse-capture", "--loot-test", "--loot-capture",
		"--clothing-test", "--clothing-capture", "--utility-test", "--utility-capture",
		"--skill-test", "--skill-capture", "--vehicle-test", "--vehicle-capture",
		"--character-test", "--character-capture"
	]
	for mode: String in isolated_modes:
		if mode in args:
			return false
	return true

func seed_weapon_loot() -> void:
	seed_item_in_building(world_map.blue_house,"厨房橱柜","kitchen_knife",1)
	seed_item_in_building(world_map.store_building,"收银台","baseball_bat",1)
	seed_item_in_building(world_map.store_building,"收银台","pistol",1)
	seed_item_in_building(world_map.store_building,"收银台","pistol_magazine",1)
	seed_item_in_building(world_map.store_building,"收银台","pistol_ammo",18)
	seed_item_in_building(world_map.residential_b01,"储物柜","hand_axe",1)
	seed_item_in_building(world_map.residential_b01,"储物柜","pistol_ammo",12)
	seed_item_in_building(world_map.blue_house,"柜","painkillers",1)
	seed_item_in_building(world_map.residential_b01,"柜","painkillers",2)
	seed_item_in_building(world_map.blue_house,"衣柜","bed_sheet",1)
	seed_item_in_building(world_map.blue_house,"储物柜","nails",10)
	seed_item_in_building(world_map.residential_b01,"双人床","bed_sheet",1)
	seed_item_in_building(world_map.residential_b01,"储物柜","plank",3)
	seed_item_in_building(world_map.residential_b01,"储物柜","nails",12)
	seed_item_in_building(world_map.residential_b01,"储物柜","hammer",1)
	seed_item_in_building(world_map.residential_b01,"储物柜","gas_can",1)

func seed_expanded_loot() -> void:
	for building: Node2D in world_map.interactive_buildings:
		for index: int in building.furniture.size():
			var item: Dictionary = building.furniture[index]
			var additions: Dictionary = LootProfiles.additions(str(building.name),str(item.title),index)
			for item_id: String in additions.keys():
				item.remaining[item_id] = int(item.remaining.get(item_id,0)) + int(additions[item_id])

func seed_item_in_building(building: Node2D,title_part: String,item_id: String,count: int) -> void:
	for item: Dictionary in building.furniture:
		if title_part in str(item.title):
			item.remaining[item_id]=int(item.remaining.get(item_id,0))+count
			return

func active_weapon_id() -> String:
	var item_id: String=str(equipment.get(active_weapon_slot,""))
	return item_id if Catalog.is_weapon(item_id) and int(inventory.get(item_id,0))>0 else ""

func active_weapon_stats() -> Dictionary:
	return WeaponRules.stats(active_weapon_id())

func active_weapon_durability() -> float:
	var item_id:=active_weapon_id()
	if item_id.is_empty():
		return 0.0
	var states: Array=weapon_durability.get(item_id,[])
	return float(states[0]) if not states.is_empty() else WeaponRules.max_durability(item_id)

func weapon_condition_text(item_id: String) -> String:
	if not Catalog.is_weapon(item_id):
		return ""
	var states: Array=weapon_durability.get(item_id,[])
	return WeaponRules.durability_text(item_id,float(states[0]) if not states.is_empty() else WeaponRules.max_durability(item_id))

func is_food_spoiled(item_id: String) -> bool:
	return item_id == "fresh_food" and game_time_minutes >= fresh_food_expiry_minutes

func item_condition_text(item_id: String) -> String:
	if item_id != "fresh_food":
		return ""
	if is_food_spoiled(item_id):
		return "已变质"
	var remaining_days := maxf(0.0, fresh_food_expiry_minutes - game_time_minutes) / 1440.0
	return "新鲜 · 剩余 %.1f 天" % remaining_days

func repair_active_weapon_with_tape() -> Dictionary:
	var item_id := active_weapon_id()
	if item_id.is_empty():
		return {"consumed":false,"message":"先装备一件需要修理的武器"}
	var states: Array = weapon_durability.get(item_id, [])
	if states.is_empty():
		states.append(WeaponRules.max_durability(item_id))
	var maximum := WeaponRules.max_durability(item_id)
	var current := float(states[0])
	if current >= maximum - 0.01:
		return {"consumed":false,"message":"当前武器无需修理"}
	states[0] = minf(maximum, current + maximum * 0.2 * SkillRules.treatment_multiplier(skill_level("survival")))
	weapon_durability[item_id] = states
	return {"consumed":true,"message":"用强力胶带修补了%s，耐久恢复至 %s" % [item_name(item_id), weapon_condition_text(item_id)]}

func add_weapon_instances(item_id: String,count: int,durability: float=-1.0) -> void:
	if not Catalog.is_weapon(item_id):
		return
	var states: Array=weapon_durability.get(item_id,[])
	for i: int in count:
		states.append(WeaponRules.max_durability(item_id) if durability<0.0 else clampf(durability,0.0,WeaponRules.max_durability(item_id)))
	weapon_durability[item_id]=states

func remove_weapon_instances(item_id: String,count: int) -> Array[float]:
	var removed: Array[float]=[]
	var states: Array=weapon_durability.get(item_id,[])
	for i: int in mini(count,states.size()):
		removed.append(float(states.pop_back()))
	weapon_durability[item_id]=states
	if Catalog.is_firearm(item_id) and int(inventory.get(item_id, 0)) <= 0:
		firearm_loaded[item_id] = 0
	validate_equipment()
	return removed

func clothing_condition_value(item_id: String) -> float:
	var states: Array = clothing_durability.get(item_id, [])
	return float(states[0]) if not states.is_empty() else ClothingRules.max_durability(item_id)

func clothing_condition_text(item_id: String) -> String:
	return ClothingRules.condition_text(item_id, clothing_condition_value(item_id)) if Catalog.is_clothing(item_id) else ""

func add_clothing_instances(item_id: String, count: int, durability: float = -1.0) -> void:
	if not Catalog.is_clothing(item_id):
		return
	var states: Array = clothing_durability.get(item_id, [])
	for _index: int in count:
		states.append(ClothingRules.max_durability(item_id) if durability < 0.0 else clampf(durability, 0.0, ClothingRules.max_durability(item_id)))
	clothing_durability[item_id] = states

func remove_clothing_instances(item_id: String, count: int) -> Array[float]:
	var removed: Array[float] = []
	var states: Array = clothing_durability.get(item_id, [])
	for _index: int in mini(count, states.size()):
		removed.append(float(states.pop_back()))
	clothing_durability[item_id] = states
	validate_clothing_equipment()
	return removed

func equip_clothing(item_id: String) -> bool:
	if not Catalog.is_clothing(item_id) or int(inventory.get(item_id, 0)) <= 0:
		return false
	var slot := ClothingRules.slot(item_id)
	if slot not in ClothingRules.SLOTS:
		return false
	var states: Array = clothing_durability.get(item_id, [])
	if states.is_empty():
		add_clothing_instances(item_id, int(inventory.get(item_id, 0)))
	clothing_equipment[slot] = item_id
	return true

func unequip_clothing(slot: String) -> void:
	if slot in ClothingRules.SLOTS:
		clothing_equipment[slot] = ""

func validate_clothing_equipment() -> void:
	for slot: String in ClothingRules.SLOTS:
		var item_id := str(clothing_equipment.get(slot, ""))
		if not Catalog.is_clothing(item_id) or ClothingRules.slot(item_id) != slot or int(inventory.get(item_id, 0)) <= 0:
			clothing_equipment[slot] = ""

func apply_clothing_protection(part: String, wound: String) -> Dictionary:
	var protection := ClothingRules.combined_protection(part, wound, clothing_equipment, clothing_durability)
	var blocked := injury_rng.randf() < protection
	var damaged_names: Array[String] = []
	var broken_names: Array[String] = []
	for clothing_slot: String in ClothingRules.slots_for_part(part):
		var item_id := str(clothing_equipment.get(clothing_slot, ""))
		if not Catalog.is_clothing(item_id):
			continue
		var states: Array = clothing_durability.get(item_id, [])
		if states.is_empty():
			states.append(ClothingRules.max_durability(item_id))
		states[0] = maxf(0.0, float(states[0]) - ClothingRules.wear_for(wound, blocked))
		damaged_names.append(item_name(item_id))
		if float(states[0]) <= 0.0:
			states.pop_front()
			inventory[item_id] = maxi(0, int(inventory.get(item_id, 0)) - 1)
			clothing_equipment[clothing_slot] = ""
			broken_names.append(item_name(item_id))
		clothing_durability[item_id] = states
	var message := ""
	if blocked and not damaged_names.is_empty():
		message = "服装挡住了%s" % InjuryRules.WOUND_LABELS[wound]
	if not broken_names.is_empty():
		message += (" · " if not message.is_empty() else "") + "%s损坏" % "、".join(broken_names)
	return {"blocked":blocked,"protection":protection,"message":message}

func validate_equipment() -> void:
	for slot: String in ["primary","secondary"]:
		var item_id: String=str(equipment[slot])
		if not item_id.is_empty() and int(inventory.get(item_id,0))<=0:
			equipment[slot]=""
	if str(equipment.get(active_weapon_slot,"")).is_empty():
		active_weapon_slot="secondary" if not str(equipment.secondary).is_empty() else "primary"
	validate_clothing_equipment()
	refresh_equipped_weapon()

func equip_weapon(item_id: String,slot: String) -> bool:
	if slot not in ["primary","secondary"] or not Catalog.is_weapon(item_id) or int(inventory.get(item_id,0))<=0:
		return false
	var other: String="secondary" if slot=="primary" else "primary"
	if str(equipment[other])==item_id:
		equipment[other]=""
	equipment[slot]=item_id
	active_weapon_slot=slot
	cancel_reload()
	refresh_equipped_weapon()
	return true

func set_active_weapon_slot(slot: String) -> void:
	if slot in ["primary","secondary"] and not str(equipment[slot]).is_empty():
		cancel_reload()
		active_weapon_slot=slot
		refresh_equipped_weapon()

func cycle_active_weapon() -> void:
	var other: String="secondary" if active_weapon_slot=="primary" else "primary"
	if not str(equipment[other]).is_empty():
		cancel_reload()
		active_weapon_slot=other
	refresh_equipped_weapon()

func refresh_equipped_weapon() -> void:
	if not is_instance_valid(player):
		return
	var stats:=active_weapon_stats()
	player.weapon_swing_seconds=float(stats.swing) * InjuryRules.attack_duration_multiplier(injuries, needs)
	player.weapon_is_firearm = Catalog.is_firearm(active_weapon_id())
	player.firearm_cooldown_seconds = float(stats.swing)
	player.weapon_visual_length=float(stats.visual_length)
	player.weapon_visual_color=Color(str(stats.visual_color))
	player.queue_redraw()
	update_weapon_hud()
	if is_instance_valid(quickbar):
		quickbar.sync_to_active_weapon()

func update_weapon_hud() -> void:
	if not is_instance_valid(weapon_label):
		return
	if is_instance_valid(active_vehicle):
		weapon_label.text="%s  %d km/h  ·  油 %.1f L  ·  车况 %d%%" % [active_vehicle.display_name,VehicleRules.speed_kph(active_vehicle.speed_mps),active_vehicle.fuel_liters,roundi(active_vehicle.condition)]
		return
	var item_id:=active_weapon_id()
	if item_id.is_empty():
		weapon_label.text = "[Q] 徒手"
	elif Catalog.is_firearm(item_id):
		var stats := Catalog.item(item_id)
		var reload_text := " · 装填 %.1fs" % reload_remaining if reload_remaining > 0.0 else ""
		weapon_label.text = "[Q] %s  弹匣 %d/%d  备弹 %d  [R] 装填%s" % [stats.name, active_firearm_loaded(), int(stats.mag_capacity), int(inventory.get(str(stats.ammo_item), 0)), reload_text]
	else:
		weapon_label.text = "[Q] %s  耐久 %s" % [Catalog.item(item_id).name,weapon_condition_text(item_id)]

func setup_firearm_audio() -> void:
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus < 0:
		AudioServer.add_bus()
		sfx_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_bus, "SFX")
		AudioServer.set_bus_send(sfx_bus, "Master")
		AudioServer.set_bus_volume_db(sfx_bus, -3.0)
	for index: int in 3:
		var player_node := AudioStreamPlayer.new()
		player_node.name = "PistolShot%02d" % index
		player_node.stream = PISTOL_SHOT_SOUND
		player_node.bus = "SFX"
		player_node.volume_db = -4.0
		add_child(player_node)
		pistol_audio_pool.append(player_node)
	pistol_dry_player = AudioStreamPlayer.new()
	pistol_dry_player.name = "PistolDry"
	pistol_dry_player.stream = PISTOL_DRY_SOUND
	pistol_dry_player.bus = "SFX"
	pistol_dry_player.volume_db = -8.0
	add_child(pistol_dry_player)

func play_pistol_shot_sound() -> void:
	if pistol_audio_pool.is_empty():
		return
	var audio := pistol_audio_pool[shot_sequence % pistol_audio_pool.size()]
	audio.pitch_scale = [0.97, 1.02, 0.99][shot_sequence % 3]
	audio.play()

func play_pistol_dry_sound() -> void:
	if is_instance_valid(pistol_dry_player):
		pistol_dry_player.pitch_scale = 0.98 + float(shot_sequence % 3) * 0.02
		pistol_dry_player.play()

func stop_firearm_audio() -> void:
	for audio: AudioStreamPlayer in pistol_audio_pool:
		audio.stop()
	if is_instance_valid(pistol_dry_player):
		pistol_dry_player.stop()

func active_firearm_loaded() -> int:
	var item_id := active_weapon_id()
	return int(firearm_loaded.get(item_id, 0)) if Catalog.is_firearm(item_id) else 0

func cancel_reload() -> void:
	reload_remaining = 0.0
	reload_weapon_id = ""

func begin_reload() -> bool:
	var item_id := active_weapon_id()
	if not Catalog.is_firearm(item_id):
		return false
	var stats := Catalog.item(item_id)
	if reload_remaining > 0.0:
		combat_message = "正在装填"
		combat_message_time = 0.7
		return false
	if active_firearm_loaded() >= int(stats.mag_capacity):
		combat_message = "弹匣已满"
		combat_message_time = 0.8
		return false
	if int(inventory.get(str(stats.magazine_item), 0)) <= 0:
		combat_message = "缺少 %s" % Catalog.item(str(stats.magazine_item)).name
		combat_message_time = 1.0
		return false
	if int(inventory.get(str(stats.ammo_item), 0)) <= 0:
		combat_message = "没有可用的 %s" % Catalog.item(str(stats.ammo_item)).name
		combat_message_time = 1.0
		return false
	reload_weapon_id = item_id
	reload_remaining = float(stats.reload_seconds)
	combat_message = "正在装填…"
	combat_message_time = reload_remaining
	update_weapon_hud()
	return true

func update_firearm_reload(delta: float) -> void:
	if reload_remaining <= 0.0:
		return
	if active_weapon_id() != reload_weapon_id or not Catalog.is_firearm(reload_weapon_id):
		cancel_reload()
		return
	reload_remaining = maxf(0.0, reload_remaining - delta)
	if reload_remaining > 0.0:
		update_weapon_hud()
		return
	var stats := Catalog.item(reload_weapon_id)
	var ammo_item := str(stats.ammo_item)
	var needed := maxi(0, int(stats.mag_capacity) - int(firearm_loaded.get(reload_weapon_id, 0)))
	var moved := mini(needed, int(inventory.get(ammo_item, 0)))
	inventory[ammo_item] = maxi(0, int(inventory.get(ammo_item, 0)) - moved)
	firearm_loaded[reload_weapon_id] = int(firearm_loaded.get(reload_weapon_id, 0)) + moved
	combat_message = "装填完成 · %d/%d" % [int(firearm_loaded[reload_weapon_id]), int(stats.mag_capacity)]
	combat_message_time = 1.0
	reload_weapon_id = ""
	update_weapon_hud()
	if is_instance_valid(quickbar):
		quickbar.force_refresh()

func try_fire_active_weapon(origin: Vector2, direction: Vector2, aiming: bool) -> bool:
	var item_id := active_weapon_id()
	if gameplay_blocked() or not Catalog.is_firearm(item_id):
		return false
	if not aiming:
		combat_message = "先按住右键瞄准"
		combat_message_time = 0.9
		return false
	if reload_remaining > 0.0:
		combat_message = "正在装填"
		combat_message_time = 0.6
		return false
	var loaded := int(firearm_loaded.get(item_id, 0))
	if loaded <= 0:
		combat_message = "弹匣已空 · 按 R 装填"
		combat_message_time = 1.0
		play_pistol_dry_sound()
		return false
	firearm_loaded[item_id] = loaded - 1
	var stats := Catalog.item(item_id)
	var shot_direction := FirearmRules.resolved_direction(world_map, direction, shot_sequence, player.moving, player.crouching)
	shot_sequence += 1
	var target_zombie := FirearmRules.first_target(world_map, origin, shot_direction, zombies, float(stats.range))
	play_pistol_shot_sound()
	var listeners := emit_world_sound(origin, float(stats.noise_radius), "gunshot")
	damage_active_weapon()
	if is_instance_valid(target_zombie):
		target_zombie.take_hit(int(stats.damage), origin, float(stats.knockback))
		combat_message = ("击倒" if target_zombie.is_dead() else "命中") + " · 弹匣 %d/%d · 惊动 %d" % [int(firearm_loaded[item_id]), int(stats.mag_capacity), listeners]
	else:
		combat_message = "未命中 · 弹匣 %d/%d · 惊动 %d" % [int(firearm_loaded[item_id]), int(stats.mag_capacity), listeners]
	combat_message_time = 1.0
	update_weapon_hud()
	if is_instance_valid(quickbar):
		quickbar.force_refresh()
	return true

func damage_active_weapon() -> String:
	var item_id:=active_weapon_id()
	if item_id.is_empty():
		return ""
	var states: Array=weapon_durability.get(item_id,[])
	if states.is_empty():
		states.append(WeaponRules.max_durability(item_id))
	var wear := float(WeaponRules.stats(item_id).wear) * SkillRules.weapon_wear_multiplier(skill_level("survival"))
	states[0]=maxf(0.0,float(states[0])-wear)
	var broke:=float(states[0])<=0.0
	if broke:
		states.remove_at(0)
		inventory[item_id]=maxi(0,int(inventory.get(item_id,0))-1)
		if Catalog.is_firearm(item_id) and int(inventory.get(item_id, 0)) <= 0:
			firearm_loaded[item_id] = 0
		combat_message=str(Catalog.item(item_id).name)+"损坏了"
		combat_message_time=1.2
	weapon_durability[item_id]=states
	validate_equipment()
	return str(Catalog.item(item_id).name) if broke else ""

func spawn_zombies() -> void:
	if not zombies.is_empty():
		return
	population_enabled = true
	for profile: Dictionary in ZombiePopulation.build_initial_plan(world_map):
		spawn_zombie(profile.logical_position, profile)

func spawn_zombie(logical_position: Vector2, profile: Dictionary = {}) -> Node2D:
	var zombie: Node2D = Zombie.new()
	zombie.name = "Zombie_%03d" % population_next_id
	var spawn_id := population_next_id
	population_next_id += 1
	var spawn_profile := profile.duplicate(true)
	if not spawn_profile.has("corpse_loot"):
		spawn_profile["corpse_loot"] = ZombiePopulation.corpse_loot(spawn_id, str(spawn_profile.get("zone", "road")))
	add_child(zombie)
	zombie.setup(self, world_map, player, logical_position, spawn_id, spawn_profile)
	zombies.append(zombie)
	return zombie

func clear_zombies() -> void:
	for zombie: Node2D in zombies:
		if is_instance_valid(zombie):
			zombie.queue_free()
	zombies.clear()

func alive_zombie_count() -> int:
	var count := 0
	for zombie: Node2D in zombies:
		if is_instance_valid(zombie) and not zombie.is_dead():
			count += 1
	return count

func update_zombie_population(delta: float) -> void:
	if not population_enabled or population_respawn_budget <= 0:
		return
	population_timer = maxf(0.0, population_timer - delta)
	if population_timer <= 0.0 and alive_zombie_count() < ZombiePopulation.MIN_ALIVE:
		try_replenish_population()

func try_replenish_population() -> bool:
	if population_respawn_budget <= 0 or alive_zombie_count() >= ZombiePopulation.MIN_ALIVE:
		return false
	for offset: int in ZombiePopulation.MIGRATION_CANDIDATES.size():
		var index: int = (population_seed_cursor + offset) % ZombiePopulation.MIGRATION_CANDIDATES.size()
		var logical: Vector2 = ZombiePopulation.MIGRATION_CANDIDATES[index]
		var world_position: Vector2 = world_map.map_to_world(logical)
		if not world_map.is_walkable_world(world_position):
			continue
		if Combat.distance_meters(world_map, player.position, world_position) < ZombiePopulation.MIN_RESPAWN_DISTANCE_METERS:
			continue
		if position_in_camera_view(world_position):
			continue
		var separated := true
		for zombie: Node2D in zombies:
			if not zombie.is_dead() and Combat.distance_meters(world_map, zombie.position, world_position) < 2.0:
				separated = false
				break
		if not separated:
			continue
		population_seed_cursor = (index + 1) % ZombiePopulation.MIGRATION_CANDIDATES.size()
		population_respawn_budget -= 1
		population_timer = ZombiePopulation.RESPAWN_INTERVAL_SECONDS
		spawn_zombie(logical, {"zone":"migration", "sleeping":false})
		return true
	population_timer = 12.0
	return false

func position_in_camera_view(world_position: Vector2, margin: float = 90.0) -> bool:
	var screen_position := get_viewport().get_canvas_transform() * world_position
	return get_viewport_rect().grow(margin).has_point(screen_position)

func nearest_searchable_corpse(max_distance_meters: float = 1.25, include_active: bool = false) -> Node2D:
	var nearest: Node2D
	var best := max_distance_meters
	for zombie: Node2D in zombies:
		if not zombie.is_dead():
			continue
		if not zombie.is_corpse_searchable() and not (include_active and zombie == active_corpse):
			continue
		var distance := Combat.distance_meters(world_map, player.position, zombie.position)
		if distance <= best:
			best = distance
			nearest = zombie
	return nearest

func update_corpse_highlights(nearest: Node2D) -> void:
	for zombie: Node2D in zombies:
		if zombie.is_dead():
			zombie.set_corpse_highlight(zombie == nearest)

func _on_player_melee_impact(origin: Vector2,direction: Vector2) -> void:
	if gameplay_blocked():
		return
	var weapon: Dictionary=active_weapon_stats()
	var target_zombie: Node2D
	var nearest:=INF
	for zombie: Node2D in zombies:
		if zombie.is_dead() or not Combat.in_melee_arc(world_map,origin,direction,zombie.position,float(weapon.range)):
			continue
		var distance: float=Combat.distance_meters(world_map,origin,zombie.position)
		if distance<nearest and zombie.has_line_of_sight(origin):
			nearest=distance
			target_zombie=zombie
	if target_zombie!=null:
		var damage := roundi(float(weapon.damage)*SkillRules.melee_damage_multiplier(skill_level("melee"))*character_modifier("melee_damage"))
		target_zombie.take_hit(damage,origin,float(weapon.knockback))
		gain_skill_xp("fitness",1)
		gain_skill_xp("melee",17 if target_zombie.is_dead() else 5)
		var broken_weapon:=damage_active_weapon()
		combat_message=broken_weapon+"损坏了" if not broken_weapon.is_empty() else ("击倒" if target_zombie.is_dead() else "命中")
		combat_message_time=0.45

func damage_player(amount: int,source_world: Vector2) -> void:
	if player_invulnerability>0.0 or int(needs.health)<=0:
		return
	if sleeping:
		interrupt_sleep("你受到攻击并惊醒了")
	var interrupted_search := searching>=0
	if interrupted_search:
		searching=-1
		search_time=0.0
		search_building=null
	needs.health=maxf(0.0,float(needs.health)-float(amount))
	var injury_result := {"wounded":false, "message":""}
	if amount>=Combat.ZOMBIE_ATTACK_DAMAGE:
		var wound_roll := injury_rng.randf()
		var part_roll := injury_rng.randf()
		var infection_roll := injury_rng.randf()
		var wound := InjuryRules.wound_from_roll(wound_roll)
		if wound != "none":
			var part := InjuryRules.part_from_roll(part_roll)
			var protection_result := apply_clothing_protection(part, wound)
			if bool(protection_result.blocked):
				injury_result = {"wounded":false,"message":str(protection_result.message)}
			else:
				injury_result = InjuryRules.apply_zombie_hit(injuries, wound_roll, part_roll, infection_roll)
				if not str(protection_result.message).is_empty():
					injury_result.message = str(injury_result.message) + " · " + str(protection_result.message)
		InjuryRules.sync_needs(injuries, needs)
	update_player_condition_effects()
	player_invulnerability=0.55
	player.receive_hit(source_world)
	if interrupted_search and int(needs.health)>0 and not is_instance_valid(backpack) and not is_instance_valid(loot_overlay):
		refresh_player_control()
	var damage_text := "受到 %d 点伤害" % amount
	if not str(injury_result.message).is_empty():
		damage_text += " · " + str(injury_result.message)
	if interrupted_search:
		damage_text += " · 搜索中断"
	combat_message="你倒下了" if int(needs.health)<=0 else damage_text
	combat_message_time=0.8
	if int(needs.health)<=0:
		show_game_over()

func _input(event: InputEvent) -> void:
	if is_instance_valid(product_shell):
		return
	if sleeping:
		if event.is_action_pressed("back") or event.is_action_pressed("interact"):
			interrupt_sleep("你主动结束了睡眠")
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("save_game"):
			save_game()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("load_game"):
			load_game()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode in [KEY_1,KEY_2,KEY_3]:
			time_multiplier={KEY_1:1.0,KEY_2:2.0,KEY_3:4.0}[event.physical_keycode]
			update_survival_hud()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("weapon_swap") and int(needs.health)>0 and not simulation_paused:
			cycle_active_weapon()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("reload") and int(needs.health)>0 and player.is_physics_processing():
			begin_reload()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("backpack"):
			get_viewport().set_input_as_handled()
			toggle_backpack()
			return
		if event.is_action_pressed("crafting"):
			get_viewport().set_input_as_handled()
			toggle_crafting()
			return
		if is_instance_valid(crafting_overlay):
			if event.is_action_pressed("back"):
				get_viewport().set_input_as_handled()
				close_crafting()
			return
		if is_instance_valid(skills_overlay):
			if event.is_action_pressed("back"):
				get_viewport().set_input_as_handled()
				close_skills_panel(true)
			return
		if is_instance_valid(vehicle_overlay):
			if event.is_action_pressed("back"):
				get_viewport().set_input_as_handled()
				close_vehicle_panel()
			return
		if is_instance_valid(corpse_overlay):
			if event.is_action_pressed("back"):
				get_viewport().set_input_as_handled()
				close_corpse_loot()
			return
		if is_instance_valid(health_overlay):
			if event.is_action_pressed("back"):
				get_viewport().set_input_as_handled()
				close_health_panel()
			return
		if is_instance_valid(mobile_settings_overlay):
			if event.is_action_pressed("back"):
				get_viewport().set_input_as_handled()
				close_mobile_settings()
			return
		if is_instance_valid(backpack):
			if event.is_action_pressed("back"):
				get_viewport().set_input_as_handled()
				close_backpack()
			return
		if simulation_paused:
			return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F6:
		catalog_index=(catalog_index+1)%8
		catalog_preview()
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.is_action_pressed("back"):
		if loot_overlay: close_loot()
		if searching >= 0:
			searching = -1
			refresh_player_control()
		return
	if not event.is_action_pressed("interact"): return
	interact()

func toggle_backpack() -> void:
	if int(needs.health) <= 0:
		return
	if is_instance_valid(active_vehicle):
		show_combat_message("请先停车并下车")
		return
	if is_instance_valid(backpack):
		close_backpack()
	else:
		open_backpack()

func interact() -> void:
	if is_instance_valid(active_vehicle):
		exit_vehicle()
		return
	if crafting_overlay:
		close_crafting()
		return
	if corpse_overlay:
		close_corpse_loot()
		return
	if loot_overlay:
		close_loot()
		return
	if searching >= 0: return
	var nearby_vehicle:=nearest_vehicle()
	if nearby_vehicle!=null:
		open_vehicle_panel(nearby_vehicle)
		return
	var corpse_nearby := nearest_searchable_corpse()
	if corpse_nearby != null:
		open_corpse_loot(corpse_nearby)
		return
	# Door takes precedence only at the threshold, so nearby furniture stays accessible.
	var house = world_map.building_near(player.position)
	if house.near_door(player.position) and world_map.world_to_map(player.position-house.door_midpoint()).length()*.5<.7:
		if house.try_toggle_door(player.position):
			emit_world_sound(player.position, 5.0, "door")
			return
	var nearby: int = house.nearest_furniture(player.position)
	if nearby >= 0:
		searching = nearby
		search_building = house
		search_time = 0.0
		emit_world_sound(player.position, 2.8, "search")
		refresh_player_control()
		return
	var nearby_window: int = house.nearest_window(player.position)
	if nearby_window >= 0:
		open_crafting(house,nearby_window)
		return
	if house.near_door(player.position):
		if house.try_toggle_door(player.position):
			emit_world_sound(player.position, 5.0, "door")

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202822")
	style.border_color = Color("899777")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	return style

func open_loot(index: int,building: Node2D = null) -> void:
	close_corpse_loot()
	if building == null: building = active_building if active_building != null else world_map.building_near(player.position)
	if index < 0 or building.nearest_furniture(player.position) != index:
		refresh_player_control()
		return
	if is_instance_valid(loot_overlay):
		loot_overlay.hide()
		loot_overlay.queue_free()
	active_building=building
	active_loot=index
	var first_search := not bool(building.furniture[index].get("searched",false))
	building.furniture[index]["searched"]=true
	if first_search:
		gain_skill_xp("scavenging",15)
	player.set_physics_process(false)
	var panel=preload("res://scripts/container_panel.gd").new()
	panel.game=self
	panel.building=building
	panel.index=index
	panel.message="选择需要的物品；未拿取的物品留在这里。"
	loot_overlay=panel
	hud.add_child(panel)
	refresh_player_control()

func leave_loot(index: int,key: String) -> void:
	left_items[key] = true
	open_loot(index)

func take_loot(index: int,key: String) -> void:
	if active_building == null or active_building.nearest_furniture(player.position) != index: return
	var available: int=active_building.available_loot(index).get(key,0)
	var amount:=0
	while amount<available and Backpack.fits(inventory,key,amount+1): amount+=1
	if amount>0:
		active_building.furniture[index].remaining[key]-=amount
		inventory[key]+=amount
		if Catalog.is_weapon(key):
			add_weapon_instances(key,amount)
	open_loot(index)
	if amount<available:
		var notice:=Label.new()
		notice.text="背包容量不足，剩余物品已留在容器内。Tab 打开背包"
		notice.position=Vector2(340,90)
		loot_overlay.add_child(notice)

func open_corpse_loot(corpse: Node2D) -> void:
	if not is_instance_valid(corpse) or not corpse.is_dead():
		return
	close_mobile_settings()
	close_health_panel()
	close_crafting()
	if is_instance_valid(backpack):
		close_backpack()
	close_loot()
	searching = -1
	search_time = 0.0
	search_building = null
	active_corpse = corpse
	var first_search := not bool(corpse.corpse_searched)
	corpse.corpse_searched = true
	if first_search:
		gain_skill_xp("scavenging",8)
	corpse.set_corpse_highlight(false)
	corpse_overlay = CorpsePanel.new()
	corpse_overlay.name = "CorpsePanel"
	corpse_overlay.game = self
	corpse_overlay.corpse = corpse
	hud.add_child(corpse_overlay)
	refresh_player_control()

func close_corpse_loot() -> void:
	if is_instance_valid(corpse_overlay):
		corpse_overlay.hide()
		corpse_overlay.queue_free()
	corpse_overlay = null
	if is_instance_valid(active_corpse):
		active_corpse.set_corpse_highlight(false)
	active_corpse = null
	refresh_player_control()

func take_corpse_item(corpse: Node2D, item_id: String, requested: int) -> int:
	if not is_instance_valid(corpse) or not corpse.is_dead() or not Catalog.has(item_id):
		return 0
	var available := int(corpse.corpse_inventory.get(item_id, 0))
	var moved := 0
	while moved < mini(available, requested) and Backpack.fits(inventory, item_id, 1):
		inventory[item_id] = int(inventory.get(item_id, 0)) + 1
		corpse.corpse_inventory[item_id] = int(corpse.corpse_inventory.get(item_id, 0)) - 1
		if Catalog.is_weapon(item_id):
			add_weapon_instances(item_id, 1)
		elif Catalog.is_clothing(item_id):
			add_clothing_instances(item_id, 1)
		moved += 1
	if is_instance_valid(quickbar):
		quickbar.force_refresh()
	return moved

func open_backpack() -> void:
	close_skills_panel(false)
	close_vehicle_panel()
	close_corpse_loot()
	close_health_panel()
	close_mobile_settings()
	close_crafting()
	searching=-1
	close_loot()
	backpack=Backpack.new()
	backpack.game=self
	hud.add_child(backpack)
	refresh_player_control()

func close_backpack() -> void:
	if is_instance_valid(backpack):
		backpack.hide()
		backpack.queue_free()
	backpack=null
	refresh_player_control()

func open_skills_panel() -> void:
	if int(needs.health)<=0 or is_instance_valid(skills_overlay):
		return
	if is_instance_valid(backpack):
		close_backpack()
	close_vehicle_panel()
	close_corpse_loot()
	close_health_panel()
	close_mobile_settings()
	close_crafting()
	close_loot()
	searching=-1
	search_time=0.0
	search_building=null
	skills_overlay=SkillsPanel.new()
	skills_overlay.name="SkillsPanel"
	skills_overlay.game=self
	hud.add_child(skills_overlay)
	refresh_player_control()

func close_skills_panel(return_to_backpack: bool = false) -> void:
	if is_instance_valid(skills_overlay):
		skills_overlay.hide()
		skills_overlay.queue_free()
	skills_overlay=null
	refresh_player_control()
	if return_to_backpack and int(needs.health)>0:
		call_deferred("open_backpack")

func skill_level(skill_id: String) -> int:
	return SkillRules.level(skills,skill_id)

func gain_skill_xp(skill_id: String,amount: int) -> Dictionary:
	var adjusted:=maxi(1,roundi(float(amount)*character_modifier("xp_gain"))) if amount>0 else 0
	var result:=SkillRules.add_xp(skills,skill_id,adjusted)
	if bool(result.get("leveled",false)):
		show_combat_message("%s提升至等级 %d" % [SkillRules.DEFINITIONS[skill_id].name,int(result.after)],2.2)
	return result

func open_vehicle_panel(vehicle: Node2D) -> void:
	if not is_instance_valid(vehicle) or is_instance_valid(active_vehicle) or vehicle.interaction_distance_meters(player.position)>2.4:
		return
	close_skills_panel(false)
	close_corpse_loot()
	close_health_panel()
	close_mobile_settings()
	close_crafting()
	if is_instance_valid(backpack): close_backpack()
	close_loot()
	searching=-1
	search_time=0.0
	search_building=null
	vehicle_overlay=VehiclePanel.new()
	vehicle_overlay.name="VehiclePanel"
	vehicle_overlay.game=self
	vehicle_overlay.vehicle=vehicle
	hud.add_child(vehicle_overlay)
	refresh_player_control()

func close_vehicle_panel() -> void:
	if is_instance_valid(vehicle_overlay):
		vehicle_overlay.hide()
		vehicle_overlay.queue_free()
	vehicle_overlay=null
	refresh_player_control()

func vehicle_item_storable(item_id: String) -> bool:
	return Catalog.has(item_id) and not Catalog.is_weapon(item_id) and not Catalog.is_clothing(item_id)

func transfer_vehicle_item(vehicle: Node2D,item_id: String,amount: int,from_vehicle: bool) -> Dictionary:
	if not is_instance_valid(vehicle) or not Catalog.has(item_id) or amount<=0:
		return {"moved":0,"message":"无法转移该物品"}
	if not from_vehicle and not vehicle_item_storable(item_id):
		return {"moved":0,"message":"武器和衣物请保留在随身装备中"}
	var source: Dictionary=vehicle.trunk if from_vehicle else inventory
	var destination: Dictionary=inventory if from_vehicle else vehicle.trunk
	var moved:=0
	while moved<mini(amount,int(source.get(item_id,0))):
		var fits:=Backpack.fits(destination,item_id,1) if from_vehicle else vehicle_trunk_fits(destination,item_id,1)
		if not fits: break
		source[item_id]=int(source.get(item_id,0))-1
		destination[item_id]=int(destination.get(item_id,0))+1
		moved+=1
	if int(source.get(item_id,0))<=0: source.erase(item_id)
	if is_instance_valid(quickbar): quickbar.force_refresh()
	return {"moved":moved,"message":"已%s %d 件%s%s" % ["取出" if from_vehicle else "存入",moved,item_name(item_id),"，容量不足" if moved<amount else ""]}

func vehicle_trunk_fits(items: Dictionary,item_id: String,count: int) -> bool:
	var copy:=items.duplicate()
	copy[item_id]=int(copy.get(item_id,0))+count
	return Backpack.weight(copy)<=VehicleRules.TRUNK_MAX_WEIGHT+0.001 and Backpack.slots(copy)<=VehicleRules.TRUNK_MAX_SLOTS

func refuel_vehicle(vehicle: Node2D) -> Dictionary:
	if not is_instance_valid(vehicle) or vehicle.fuel_liters>=VehicleRules.MAX_FUEL_LITERS-0.01:
		return {"ok":false,"message":"油箱已经装满"}
	if int(inventory.get("gas_can",0))<=0:
		return {"ok":false,"message":"背包中没有汽油桶"}
	inventory.gas_can=int(inventory.get("gas_can",0))-1
	vehicle.fuel_liters=minf(VehicleRules.MAX_FUEL_LITERS,vehicle.fuel_liters+10.0)
	if is_instance_valid(quickbar): quickbar.force_refresh()
	return {"ok":true,"message":"加入 10 升汽油 · 当前 %.1f L" % vehicle.fuel_liters}

func enter_vehicle(vehicle: Node2D) -> bool:
	if not is_instance_valid(vehicle) or vehicle.condition<=0.0 or vehicle.fuel_liters<=0.0:
		return false
	close_vehicle_panel()
	active_vehicle=vehicle
	vehicle.occupied=true
	player.visible=false
	player.moving=false
	player.running=false
	player.position=vehicle.position
	camera.zoom=Vector2.ONE*0.56
	show_combat_message("已进入驾驶位 · W/S 油门与倒车 · A/D 转向 · E 下车",3.0)
	refresh_player_control()
	return true

func exit_vehicle() -> bool:
	if not is_instance_valid(active_vehicle):
		return false
	if absf(float(active_vehicle.speed_mps))>1.2:
		show_combat_message("请先把车辆停稳")
		return false
	var vehicle:=active_vehicle
	var exit_position: Vector2=vehicle.exit_world_position()
	vehicle.occupied=false
	vehicle.driving_enabled=false
	active_vehicle=null
	player.position=exit_position
	player.visible=true
	player.update_depth()
	camera.zoom=Vector2.ONE*DEFAULT_CAMERA_ZOOM
	refresh_player_control()
	return true

func clear_vehicle_occupancy() -> void:
	if is_instance_valid(active_vehicle):
		active_vehicle.occupied=false
		active_vehicle.driving_enabled=false
	active_vehicle=null
	player.visible=true
	camera.zoom=Vector2.ONE*DEFAULT_CAMERA_ZOOM

func restore_vehicle_occupancy(vehicle_id: String) -> void:
	clear_vehicle_occupancy()
	if vehicle_id.is_empty(): return
	for vehicle: Node2D in world_map.vehicles:
		if vehicle.vehicle_id==vehicle_id:
			active_vehicle=vehicle
			vehicle.occupied=true
			player.visible=false
			player.position=vehicle.position
			camera.zoom=Vector2.ONE*0.56
			return

func on_vehicle_travel(vehicle: Node2D,_old_position: Vector2,_distance_meters: float) -> void:
	if vehicle!=active_vehicle or absf(float(vehicle.speed_mps))<3.0:
		return
	for zombie: Node2D in zombies:
		if zombie.is_dead(): continue
		var distance: float=world_map.world_to_map(zombie.position-vehicle.position).length()*0.5
		if distance>1.5 or not vehicle.can_hit_zombie(zombie): continue
		var damage:=VehicleRules.impact_damage(vehicle.speed_mps)
		if damage<=0: continue
		zombie.take_hit(damage,vehicle.position,clampf(absf(vehicle.speed_mps)/12.0,0.3,1.0))
		vehicle.condition=maxf(0.0,vehicle.condition-0.5)
		show_combat_message("撞击感染者 · 车辆受损")

func on_vehicle_collision(vehicle: Node2D,impact_speed: float) -> void:
	emit_world_sound(vehicle.position,20.0,"vehicle_crash")
	show_combat_message("车辆碰撞 · 车况 %d%%" % roundi(vehicle.condition),2.0)

func toggle_crafting() -> void:
	if int(needs.health) <= 0:
		return
	if is_instance_valid(active_vehicle):
		show_combat_message("驾驶时无法制作")
		return
	if is_instance_valid(crafting_overlay):
		close_crafting()
	else:
		var target := nearest_barricade_target()
		open_crafting(target.get("building"),int(target.get("index",-1)))

func nearest_barricade_target() -> Dictionary:
	var building: Node2D = world_map.building_near(player.position)
	var index: int = building.nearest_window(player.position)
	return {"building":building,"index":index} if index >= 0 else {}

func open_crafting(building: Node2D = null,window_index: int = -1) -> void:
	close_vehicle_panel()
	close_corpse_loot()
	close_health_panel()
	close_mobile_settings()
	if is_instance_valid(backpack):
		close_backpack()
	close_loot()
	searching = -1
	search_time = 0.0
	search_building = null
	crafting_overlay = CraftingPanel.new()
	crafting_overlay.name = "CraftingPanel"
	crafting_overlay.game = self
	crafting_overlay.target_building = building
	crafting_overlay.target_window = window_index
	hud.add_child(crafting_overlay)
	refresh_player_control()

func close_crafting() -> void:
	if is_instance_valid(crafting_overlay):
		crafting_overlay.hide()
		crafting_overlay.queue_free()
	crafting_overlay = null
	refresh_player_control()

func craft_recipe(recipe_id: String) -> Dictionary:
	var result := CraftingRules.craft(inventory,recipe_id)
	if bool(result.ok):
		emit_world_sound(player.position,2.5,"craft")
		gain_skill_xp("survival",12)
		if is_instance_valid(quickbar):
			quickbar.force_refresh()
	return result

func build_window_barricade(building: Node2D,index: int) -> Dictionary:
	if not is_instance_valid(building) or building.nearest_window(player.position) != index:
		return {"ok":false,"message":"离窗户太远"}
	if building.barricade_layers(index) >= CraftingRules.MAX_BARRICADE_LAYERS:
		return {"ok":false,"message":"这扇窗户已经加固到上限"}
	var result := CraftingRules.consume_barricade_materials(inventory)
	if not bool(result.ok):
		return result
	if not building.add_barricade_layer(index):
		CraftingRules.apply_delta(inventory,CraftingRules.BARRICADE_COST,1)
		return {"ok":false,"message":"施工失败，材料已退回"}
	emit_world_sound(player.position,9.0,"construction")
	gain_skill_xp("survival",16)
	if is_instance_valid(quickbar):
		quickbar.force_refresh()
	return result

func remove_window_barricade(building: Node2D,index: int) -> Dictionary:
	if not is_instance_valid(building) or building.nearest_window(player.position) != index:
		return {"ok":false,"message":"离窗户太远"}
	if building.barricade_layers(index) <= 0:
		return {"ok":false,"message":"这扇窗户没有可拆除的木板"}
	var check := CraftingRules.can_remove_barricade(inventory)
	if not bool(check.ok):
		return check
	if not building.remove_barricade_layer(index):
		return {"ok":false,"message":"拆除失败"}
	var result := CraftingRules.grant_recovered_materials(inventory)
	emit_world_sound(player.position,8.0,"construction")
	gain_skill_xp("survival",6)
	if is_instance_valid(quickbar):
		quickbar.force_refresh()
	return result

func toggle_target_window(building: Node2D,index: int) -> Dictionary:
	if not is_instance_valid(building) or building.nearest_window(player.position)!=index:
		return {"ok":false,"message":"离窗户太远"}
	var result: Dictionary=building.toggle_window(index)
	if bool(result.ok): emit_world_sound(player.position,3.0,"window")
	return result

func climb_target_window(building: Node2D,index: int) -> Dictionary:
	if not is_instance_valid(building) or building.nearest_window(player.position)!=index:
		return {"ok":false,"message":"离窗户太远"}
	var crossing: Dictionary=building.window_crossing(index,player.position)
	if crossing.is_empty():
		return {"ok":false,"message":"请先打开窗户或清除木板"}
	close_crafting()
	if not player.begin_traversal(crossing.destination,0.65):
		return {"ok":false,"message":"当前无法翻越"}
	emit_world_sound(player.position,4.0,"climb")
	if bool(crossing.broken) and injury_rng.randf()<0.24:
		var injury: Dictionary=InjuryRules.apply_glass_scratch(injuries,injury_rng.randf())
		InjuryRules.sync_needs(injuries,needs)
		show_combat_message(str(injury.message))
	return {"ok":true,"message":"正在翻越窗户"}

func repair_window_barricade(building: Node2D,index: int) -> Dictionary:
	if not is_instance_valid(building) or building.nearest_window(player.position)!=index:
		return {"ok":false,"message":"离窗户太远"}
	if not building.repair_window(index,0.0):
		# Zero is a read-only damaged-state check; repair only after the item check.
		var window: Dictionary=building.windows[index]
		if int(window.layers)<=0 or float(window.layer_hp[int(window.layers)-1])>=building.BARRICADE_LAYER_HP:
			return {"ok":false,"message":"外层木板不需要维修"}
	var result:=CraftingRules.repair_barricade(inventory)
	if not bool(result.ok): return result
	building.repair_window(index,building.BARRICADE_LAYER_HP*SkillRules.treatment_multiplier(skill_level("survival")))
	emit_world_sound(player.position,7.0,"construction")
	gain_skill_xp("survival",10)
	if is_instance_valid(quickbar): quickbar.force_refresh()
	return result

func on_barrier_damaged(entry: Dictionary,result: Dictionary,source: Vector2) -> void:
	var event:=str(result.get("event",""))
	var radius:=8.0 if event in ["glass_broken","door_broken"] else 4.5
	emit_world_sound(source,radius,"barrier")
	if event=="board_broken":
		ground_items.append({"key":"plank","position":entry.position+Vector2(8,3)})
	if event=="glass_broken":
		show_combat_message("附近有窗户玻璃被打碎")
	elif event=="door_broken":
		show_combat_message("附近有门被撞开")
	if sleeping and event in ["board_broken","glass_broken","door_broken"]:
		interrupt_sleep("撞击声把你惊醒了")

func show_combat_message(text: String,duration: float=1.3) -> void:
	combat_message=text
	combat_message_time=duration

func toggle_mobile_settings() -> void:
	if is_instance_valid(mobile_settings_overlay):
		close_mobile_settings()
	else:
		open_mobile_settings()

func open_mobile_settings() -> void:
	if int(needs.health) <= 0:
		return
	close_vehicle_panel()
	close_corpse_loot()
	close_health_panel()
	close_crafting()
	if is_instance_valid(backpack):
		close_backpack()
	close_loot()
	searching = -1
	mobile_settings_overlay = MobileSettingsPanel.new()
	mobile_settings_overlay.name = "MobileSettings"
	mobile_settings_overlay.game = self
	mobile_settings_overlay.controls = mobile_controls
	hud.add_child(mobile_settings_overlay)
	refresh_player_control()

func close_mobile_settings() -> void:
	if is_instance_valid(mobile_settings_overlay):
		mobile_settings_overlay.hide()
		mobile_settings_overlay.queue_free()
	mobile_settings_overlay = null
	refresh_player_control()

func open_health_panel() -> void:
	if int(needs.health) <= 0 or is_instance_valid(health_overlay):
		return
	close_vehicle_panel()
	close_corpse_loot()
	close_mobile_settings()
	close_crafting()
	if is_instance_valid(backpack):
		close_backpack()
	close_loot()
	searching = -1
	search_time = 0.0
	search_building = null
	InjuryRules.sync_needs(injuries, needs)
	health_overlay = HealthPanel.new()
	health_overlay.name = "HealthPanel"
	health_overlay.game = self
	hud.add_child(health_overlay)
	refresh_player_control()

func close_health_panel() -> void:
	if is_instance_valid(health_overlay):
		health_overlay.hide()
		health_overlay.queue_free()
	health_overlay = null
	refresh_player_control()

func use_inventory_item(item_id: String, preferred_part: String = "") -> Dictionary:
	if int(inventory.get(item_id, 0)) <= 0:
		return {"consumed":false, "message":"背包中没有这件物品"}
	var result: Dictionary
	match item_id:
		"bandage":
			result = InjuryRules.apply_bandage(injuries, preferred_part)
		"painkillers":
			result = InjuryRules.take_painkillers(needs, injuries)
		"disinfectant":
			result = InjuryRules.disinfect_wound(injuries, preferred_part, SkillRules.treatment_multiplier(skill_level("survival"))*character_modifier("medical"))
		"antibiotics":
			result = InjuryRules.take_antibiotics(injuries, SkillRules.treatment_multiplier(skill_level("survival"))*character_modifier("medical"))
		"duct_tape":
			result = repair_active_weapon_with_tape()
		_:
			result = Survival.use_item(needs, item_id, is_food_spoiled(item_id))
	if bool(result.get("consumed", false)):
		inventory[item_id] = maxi(0, int(inventory.get(item_id, 0)) - 1)
		if item_id in ["bandage","painkillers","disinfectant","antibiotics","duct_tape"]:
			gain_skill_xp("survival",8)
		if item_id == "water":
			inventory["empty_bottle"] = int(inventory.get("empty_bottle",0)) + 1
	InjuryRules.sync_needs(injuries, needs)
	update_player_condition_effects()
	update_survival_hud()
	if is_instance_valid(quickbar):
		quickbar.force_refresh()
	return result

func drink_from_tap() -> Dictionary:
	if not water_available():
		return {"ok":false,"message":"供水已经中断，水龙头没有水"}
	if float(needs.water) >= 100.0:
		return {"ok":false,"message":"当前不需要饮水"}
	var before := float(needs.water)
	needs.water = minf(100.0,before+35.0)
	update_survival_hud()
	return {"ok":true,"message":"饮用了自来水，水分 +%d" % roundi(float(needs.water)-before)}

func fill_water_bottles(requested: int = 999) -> Dictionary:
	if not water_available():
		return {"ok":false,"moved":0,"message":"供水已经中断，无法灌装"}
	var moved := 0
	while moved < requested and int(inventory.get("empty_bottle",0)) > 0:
		var candidate := inventory.duplicate()
		candidate.empty_bottle = int(candidate.get("empty_bottle",0))-1
		if not Backpack.fits(candidate,"water",1):
			break
		inventory.empty_bottle = int(inventory.get("empty_bottle",0))-1
		inventory.water = int(inventory.get("water",0))+1
		moved += 1
	if is_instance_valid(quickbar):
		quickbar.force_refresh()
	return {"ok":moved>0,"moved":moved,"message":"灌装了 %d 瓶饮用水" % moved if moved>0 else "没有空瓶，或背包容量不足"}

func remove_injury_bandage(part: String) -> Dictionary:
	var result: Dictionary = InjuryRules.remove_bandage(injuries, part)
	InjuryRules.sync_needs(injuries, needs)
	update_player_condition_effects()
	update_survival_hud()
	return result

func backpack_test() -> void:
	inventory={"food":6,"water":3,"bandage":4,"parts":5}
	assert(Backpack.slots(inventory)==5)
	assert(not Backpack.fits(inventory,"water",30))
	open_backpack()
	assert(not player.is_physics_processing())
	needs.food=50
	backpack.selected="food"
	backpack.use_item()
	assert(inventory.food==5 and needs.food==75)
	backpack.drop_item()
	assert(inventory.food==4 and ground_items.size()==1)
	backpack.pickup()
	assert(inventory.food==5 and ground_items.is_empty())
	needs.food=100
	backpack.use_item()
	assert(inventory.food==5)
	if "--backpack-capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(.5).timeout
		get_viewport().get_texture().get_image().save_png("res://build/backpack-v1.png")
	close_backpack()
	assert(player.is_physics_processing())
	print("BACKPACK PASS: stacks, capacity, use, drop, pickup, modal lock")
	get_tree().quit()

func close_loot() -> void:
	if is_instance_valid(loot_overlay):
		loot_overlay.visible = false
		loot_overlay.queue_free()
	loot_overlay = null
	active_loot = -1
	active_building = null
	left_items.clear()
	refresh_player_control()

func show_game_over() -> void:
	if is_instance_valid(game_over_overlay):
		return
	simulation_paused=false
	searching=-1
	if is_instance_valid(corpse_overlay):
		corpse_overlay.queue_free()
		corpse_overlay=null
		active_corpse=null
	if is_instance_valid(health_overlay):
		health_overlay.queue_free()
		health_overlay=null
	if is_instance_valid(crafting_overlay):
		crafting_overlay.queue_free()
		crafting_overlay=null
	if is_instance_valid(skills_overlay):
		skills_overlay.queue_free()
		skills_overlay=null
	if is_instance_valid(vehicle_overlay):
		vehicle_overlay.queue_free()
		vehicle_overlay=null
	clear_vehicle_occupancy()
	if is_instance_valid(backpack):
		backpack.queue_free()
		backpack=null
	if is_instance_valid(loot_overlay):
		loot_overlay.queue_free()
		loot_overlay=null
	player.set_physics_process(false)
	hint_label.text=""
	update_survival_hud()
	game_over_overlay=ColorRect.new()
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.color=Color(0.025,0.03,0.03,0.88)
	game_over_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	hud.add_child(game_over_overlay)
	var box:=VBoxContainer.new()
	box.position=Vector2(430,205)
	box.size=Vector2(420,300)
	box.alignment=BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation",18)
	game_over_overlay.add_child(box)
	var title:=Label.new()
	title.text="你没能活下来"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",38)
	title.add_theme_color_override("font_color",Color("c76b61"))
	box.add_child(title)
	var clock:=Survival.clock_parts(game_time_minutes)
	var detail:=Label.new()
	detail.text="存活至第 %d 天  %02d:%02d" % [clock.day,clock.hour,clock.minute]
	detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size",20)
	box.add_child(detail)
	var restart:=Button.new()
	restart.text="重新开始"
	restart.custom_minimum_size=Vector2(240,54)
	restart.pressed.connect(restart_game)
	box.add_child(restart)

func restart_game() -> void:
	get_tree().reload_current_scene()

func run_standard_test() -> void:
	await preload("res://scripts/layout_standard_test.gd").run(self)

func run_barrier_test() -> void:
	await preload("res://scripts/barrier_traversal_test.gd").run(self)

func run_safehouse_test() -> void:
	await preload("res://scripts/safehouse_sleep_test.gd").run(self)

func safehouse_capture() -> void:
	autosave_path_override = "user://ash_district_safehouse_capture.json"
	for zombie: Node2D in zombies:
		zombie.change_state(zombie.State.DEAD)
	var building: Node2D = world_map.blue_house
	var bed_index := -1
	for index: int in building.furniture.size():
		if "床" in str(building.furniture[index].title):
			bed_index = index
			break
	var bed: Dictionary = building.furniture[bed_index]
	player.position = world_map.map_to_world((bed.use_zone as Rect2).get_center())
	active_building = building
	active_loot = bed_index
	claim_safehouse_at_bed()
	needs.fatigue = 86.0
	needs.stamina = 14.0
	active_building = building
	active_loot = bed_index
	rest_at_bed()
	update_sleep(2.2)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/safehouse-sleep-v025.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	remove_save_files(autosave_path_override)
	print("SAFEHOUSE CAPTURE PASS: build/safehouse-sleep-v025.png")
	get_tree().quit()

func barrier_capture() -> void:
	var building: Node2D=world_map.blue_house
	var index:=2
	building.set_barricade_layers(index,1)
	building.windows[index].layer_hp[0]=32.0
	building.windows[index].state="broken"
	building.windows[index].glass_hp=0.0
	var midpoint: Vector2=(building.windows[index].a+building.windows[index].b)*0.5
	player.position=world_map.map_to_world(midpoint+Vector2(0,0.72))
	player.update_depth()
	building.update_player(player.position,0.0)
	open_crafting(building,index)
	DisplayServer.window_set_title("余烬街区 · 门窗攻防 0.24 · 翻越 / 加固 / 维修")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var output:=ProjectSettings.globalize_path("res://build/barrier-system-v024.png")
	get_viewport().get_texture().get_image().save_png(output)
	print("BARRIER CAPTURE PASS: build/barrier-system-v024.png")
	get_tree().quit()

func run_container_test() -> void:
	await preload("res://scripts/container_test.gd").run(self)

func run_survival_test() -> void:
	await preload("res://scripts/survival_test.gd").run(self)

func run_weapon_test() -> void:
	await preload("res://scripts/weapon_test.gd").run(self)

func run_save_test() -> void:
	await preload("res://scripts/save_test.gd").run(self)

func run_mobile_test() -> void:
	await preload("res://scripts/mobile_input_test.gd").run(self)

func run_exertion_test() -> void:
	await preload("res://scripts/exertion_sound_test.gd").run(self)

func run_injury_test() -> void:
	await preload("res://scripts/injury_test.gd").run(self)

func run_population_test() -> void:
	await preload("res://scripts/zombie_population_test.gd").run(self)

func run_firearm_test() -> void:
	await preload("res://scripts/firearm_test.gd").run(self)

func run_crafting_test() -> void:
	await preload("res://scripts/crafting_barricade_test.gd").run(self)

func run_product_test() -> void:
	await preload("res://scripts/product_shell_test.gd").run(self)

func run_loot_test() -> void:
	await preload("res://scripts/loot_item_test.gd").run(self)

func run_clothing_test() -> void:
	await preload("res://scripts/clothing_test.gd").run(self)

func run_utility_test() -> void:
	await preload("res://scripts/utility_test.gd").run(self)

func run_skill_test() -> void:
	await preload("res://scripts/skill_test.gd").run(self)

func run_vehicle_test() -> void:
	await preload("res://scripts/vehicle_test.gd").run(self)

func run_character_test() -> void:
	await preload("res://scripts/character_test.gd").run(self)

func show_product_shell() -> void:
	if is_instance_valid(product_shell):
		return
	simulation_paused = true
	product_shell = ProductShell.new()
	product_shell.name = "ProductShell"
	product_shell.game = self
	hud.add_child(product_shell)
	refresh_player_control()

func close_product_shell() -> void:
	if is_instance_valid(product_shell):
		product_shell.hide()
		product_shell.queue_free()
	product_shell = null
	simulation_paused = false
	game_started = true
	refresh_player_control()
	update_survival_hud()

func save_slot_path(slot: int) -> String:
	return "user://ash_district_slot_%d.json" % clampi(slot,1,3)

func autosave_slot_path(slot: int) -> String:
	if not autosave_path_override.is_empty():
		return autosave_path_override
	return "user://ash_district_slot_%d.autosave.json" % clampi(slot,1,3)

func load_best_slot(slot: int) -> Dictionary:
	var best := {"ok":false, "error":"没有可用存档"}
	var best_timestamp := -1
	for path: String in [save_slot_path(slot), autosave_slot_path(slot)]:
		var result: Dictionary = SaveSystem.load_file(path)
		if not bool(result.ok):
			continue
		var timestamp := maxi(int(result.data.get("saved_unix_time",0)), int(FileAccess.get_modified_time(path)))
		if timestamp >= best_timestamp:
			best = result
			best["autosave"] = path == autosave_slot_path(slot)
			best_timestamp = timestamp
	return best

func save_slot_summary(slot: int) -> Dictionary:
	var result: Dictionary = load_best_slot(slot)
	if not bool(result.ok):
		return {"exists":false,"text":"空槽位"}
	var summary := save_data_summary(result.data)
	if bool(result.get("autosave",false)):
		summary.text += "  ·  自动保存"
	return summary

func save_data_summary(data: Dictionary) -> Dictionary:
	var saved_time := int(data.get("saved_unix_time",0))
	var date_text := "未知时间"
	if saved_time > 0:
		var date: Dictionary = Time.get_datetime_dict_from_unix_time(saved_time)
		date_text = "%04d-%02d-%02d %02d:%02d" % [date.year,date.month,date.day,date.hour,date.minute]
	var clock: Dictionary = Survival.clock_parts(float(data.get("world",{}).get("game_time_minutes",0.0)))
	var health := roundi(float(data.get("needs",{}).get("health",100.0)))
	var profession:=CharacterRules.profession_name(data.get("character_profile",{}))
	return {"exists":true,"timestamp":saved_time,"text":"%s  ·  第 %d 天 %02d:%02d  ·  生命 %d  ·  %s" % [profession,clock.day,clock.hour,clock.minute,health,date_text]}

func latest_save_slot() -> int:
	var latest := -1
	var latest_time := -1
	for slot in range(1,4):
		var summary := save_slot_summary(slot)
		if bool(summary.exists) and int(summary.get("timestamp",0)) > latest_time:
			latest = slot
			latest_time = int(summary.get("timestamp",0))
	return latest

func start_new_game(slot: int,profile: Dictionary={}) -> void:
	active_save_slot = clampi(slot,1,3)
	delete_save_slot(active_save_slot)
	apply_character_start(CharacterRules.default_profile() if profile.is_empty() else profile)
	close_product_shell()
	combat_message = "%s · 新游戏槽位 %d" % [CharacterRules.profession_name(character_profile),active_save_slot]
	combat_message_time = 2.5
	save_game()

func character_modifier(key: String) -> float:
	return float(character_modifiers_cache.get(key,1.0))

func set_character_profile(profile: Dictionary) -> void:
	character_profile=CharacterRules.sanitize_profile(profile)
	character_modifiers_cache=CharacterRules.modifiers(character_profile)

func apply_character_start(profile: Dictionary) -> void:
	set_character_profile(profile)
	for item_id: String in Catalog.ITEMS.keys():
		inventory[item_id]=0
	inventory.crowbar=1
	var starting_items:=CharacterRules.initial_items(character_profile)
	for item_id: String in starting_items.keys():
		inventory[item_id]=int(inventory.get(item_id,0))+int(starting_items[item_id])
	weapon_durability={"crowbar":[],"baseball_bat":[],"kitchen_knife":[],"hand_axe":[],"pistol":[]}
	add_weapon_instances("crowbar",1)
	for item_id: String in starting_items.keys():
		if Catalog.is_weapon(item_id):
			add_weapon_instances(item_id,int(starting_items[item_id]))
	clothing_durability={"baseball_cap":[],"motorcycle_helmet":[],"denim_jacket":[],"leather_jacket":[],"jeans":[],"cargo_pants":[],"sneakers":[],"work_boots":[]}
	for item_id: String in starting_items.keys():
		if Catalog.is_clothing(item_id):
			for count: int in int(starting_items[item_id]):
				clothing_durability[item_id].append(ClothingRules.max_durability(item_id))
	equipment={"primary":"crowbar","secondary":""}
	clothing_equipment={"head":"","torso":"","legs":"","feet":""}
	active_weapon_slot="primary"
	firearm_loaded={"pistol":0}
	skills=CharacterRules.initial_skills(character_profile)
	needs={"health":100.0,"food":82.0,"water":78.0,"stamina":100.0,"fatigue":0.0,"bleeding":0.0,"pain":0.0,"infection":0.0,"pain_relief":0.0}
	injuries=InjuryRules.fresh_state()
	validate_equipment()
	if is_instance_valid(quickbar): quickbar.force_refresh()
	update_player_condition_effects()
	update_survival_hud()

func continue_slot(slot: int) -> void:
	if slot < 1 or slot > 3:
		return
	active_save_slot = slot
	if load_game():
		close_product_shell()
		combat_message = "已继续槽位 %d" % active_save_slot
		combat_message_time = 2.5

func delete_save_slot(slot: int) -> void:
	remove_save_files(save_slot_path(slot))
	remove_save_files(autosave_slot_path(slot))

func remove_save_files(path: String) -> void:
	for suffix in ["",".bak",".tmp"]:
		var candidate: String = path+suffix
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))

func quit_from_shell() -> void:
	if game_started and int(needs.health) > 0:
		autosave_game("退出游戏")
	get_tree().quit()

func product_capture() -> void:
	show_product_shell()
	await get_tree().create_timer(0.8).timeout
	var output := ProjectSettings.globalize_path("res://build/product-shell-v023.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	product_shell.push_screen("manage_slots")
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/product-slots-v023.png"))
	product_shell.pop_screen()
	product_shell.push_screen("settings")
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/product-settings-v023.png"))
	print("PRODUCT CAPTURE PASS: main menu, save slots and settings")
	get_tree().quit()

func prepare_crafting_demo() -> Dictionary:
	for item_id: String in ["bed_sheet","ripped_cloth","plank","nails","hammer"]:
		inventory[item_id] = 0
	inventory.bed_sheet = 2
	inventory.ripped_cloth = 2
	inventory.plank = 4
	inventory.nails = 12
	inventory.hammer = 1
	var building: Node2D = world_map.blue_house
	var index := 2
	building.set_barricade_layers(index,1)
	var midpoint: Vector2 = (building.windows[index].a+building.windows[index].b)*0.5
	player.position = world_map.map_to_world(midpoint+Vector2(0,1.4))
	player.update_depth()
	building.update_player(player.position,1.0)
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2(0.54,0.54)
	return {"building":building,"index":index}

func crafting_preview() -> void:
	var target := prepare_crafting_demo()
	DisplayServer.window_set_title("余烬街区 · 制作与路障 0.22 · K 制作 / E 操作窗户")
	open_crafting(target.building,target.index)
	crafting_overlay.message = "测试物资已放入背包：可制作撕布、绷带，并继续封窗或拆除。"
	crafting_overlay.rebuild()

func crafting_capture() -> void:
	var target := prepare_crafting_demo()
	await get_tree().create_timer(0.6).timeout
	var exterior_output := ProjectSettings.globalize_path("res://build/window-barricade-v022.png")
	DirAccess.make_dir_recursive_absolute(exterior_output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(exterior_output)
	open_crafting(target.building,target.index)
	crafting_overlay.message = "窗户已加固 1/2 层；材料与工具满足，可继续施工。"
	crafting_overlay.rebuild()
	await get_tree().create_timer(0.8).timeout
	var output := ProjectSettings.globalize_path("res://build/crafting-barricade-v022.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("CRAFTING CAPTURE PASS: build/window-barricade-v022.png, build/crafting-barricade-v022.png")
	get_tree().quit()

func mobile_capture() -> void:
	mobile_controls.visible = true
	mobile_controls.set_gameplay_enabled(true)
	inventory.food = 3
	inventory.water = 2
	inventory.bandage = 1
	inventory.parts = 4
	inventory.baseball_bat = 1
	add_weapon_instances("baseball_bat", 1, 68.0)
	equip_weapon("baseball_bat", "secondary")
	set_active_weapon_slot("primary")
	quickbar.visible = true
	quickbar.set_interactive(true)
	quickbar.force_refresh()
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/mobile-controls-v017.png")
	print("MOBILE CAPTURE PASS: build/mobile-controls-v017.png")
	get_tree().quit()

func mobile_settings_capture() -> void:
	mobile_controls.visible = true
	quickbar.visible = true
	open_mobile_settings()
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/mobile-settings-v018.png")
	print("SETTINGS CAPTURE PASS: build/mobile-settings-v018.png")
	get_tree().quit()

func exertion_capture() -> void:
	needs.stamina = 38.0
	needs.fatigue = 76.0
	stamina_recovery_delay = 100.0
	update_player_condition_effects()
	update_survival_hud()
	var listener: Node2D = zombies[0]
	listener.alerted = false
	listener.change_state(listener.State.IDLE)
	listener.position = world_map.map_to_world(world_map.world_to_map(player.position) + Vector2(6.0,2.0))
	emit_world_sound(player.position, 9.0, "melee")
	for zombie: Node2D in zombies:
		zombie.set_process(false)
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/exertion-sound-v018.png")
	print("EXERTION CAPTURE PASS: build/exertion-sound-v018.png")
	get_tree().quit()

func injury_capture() -> void:
	injuries = InjuryRules.fresh_state()
	injuries.torso = InjuryRules.make_wound("scratch", false, false, 0.0)
	injuries.arms = InjuryRules.make_wound("laceration", true, false, 0.0)
	injuries.legs = InjuryRules.make_wound("bite", false, true, 36.0)
	needs.health = 68.0
	needs.pain_relief = 0.0
	inventory.bandage = 3
	inventory.painkillers = 2
	InjuryRules.sync_needs(injuries, needs)
	update_player_condition_effects()
	update_survival_hud()
	open_health_panel()
	health_overlay.selected_part = "legs"
	health_overlay.refresh()
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/health-treatment-v019.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("INJURY CAPTURE PASS: build/health-treatment-v019.png")
	get_tree().quit()

func population_capture() -> void:
	for zombie: Node2D in zombies:
		zombie.set_process(false)
	var corpse: Node2D = zombies[0]
	corpse.position = player.position + world_map.map_to_world(Vector2(1.2, 0.2))
	corpse.corpse_inventory = {"food":1, "bandage":1, "painkillers":1}
	corpse.health = 0
	corpse.change_state(corpse.State.DEAD)
	player.position = corpse.position
	player.update_depth()
	open_corpse_loot(corpse)
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/corpse-search-v020.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("POPULATION CAPTURE PASS: build/corpse-search-v020.png")
	get_tree().quit()

func prepare_firearm_demo() -> void:
	inventory.pistol = 1
	inventory.pistol_magazine = 1
	inventory.pistol_ammo = 48
	if weapon_durability.get("pistol", []).is_empty():
		add_weapon_instances("pistol", 1)
	firearm_loaded.pistol = 12
	equip_weapon("pistol", "secondary")
	set_active_weapon_slot("secondary")
	quickbar.visible = true
	quickbar.set_interactive(true)
	quickbar.force_refresh()
	player.position = world_map.map_to_world(Vector2(36, 49))
	player.set_facing(world_map.map_to_world(Vector2.RIGHT))
	player.aim_visible = true
	player.update_depth()
	update_weapon_hud()

func firearm_preview() -> void:
	prepare_firearm_demo()
	DisplayServer.window_set_title("余烬街区 · 枪械测试 0.21 · 右键瞄准/左键射击 · R 装填")
	combat_message = "手枪已装备：右键瞄准、左键射击、R 装填；手机端拖动并松开右摇杆射击"
	combat_message_time = 8.0
	refresh_player_control()

func firearm_capture() -> void:
	prepare_firearm_demo()
	player.set_physics_process(false)
	for zombie: Node2D in zombies:
		zombie.set_process(false)
	player.muzzle_flash = 0.16
	combat_message = "手枪 · 弹匣 12/12 · 备弹 48 · 枪声会吸引 26 米内的僵尸"
	combat_message_time = 5.0
	await get_tree().create_timer(0.08).timeout
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/firearm-aim-v021.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("FIREARM CAPTURE PASS: build/firearm-aim-v021.png")
	get_tree().quit()

func save_game() -> bool:
	if int(needs.health) <= 0:
		return false
	var result: Dictionary = SaveSystem.write_atomic(save_slot_path(active_save_slot), SaveSystem.capture_state(self))
	if bool(result.ok):
		remove_save_files(autosave_slot_path(active_save_slot))
	combat_message = "进度已保存" if bool(result.ok) else "保存失败：" + str(result.error)
	combat_message_time = 2.0
	return bool(result.ok)

func autosave_game(reason: String) -> Dictionary:
	if int(needs.health) <= 0:
		return {"ok":false, "error":"角色已经死亡"}
	if not game_started and autosave_path_override.is_empty():
		return {"ok":true, "skipped":true}
	var result: Dictionary = SaveSystem.write_atomic(autosave_slot_path(active_save_slot), SaveSystem.capture_state(self))
	if bool(result.ok):
		autosave_cooldown = 12.0
		if game_started:
			show_combat_message("已自动保存 · " + reason, 1.8)
	return result

func load_game() -> bool:
	var result: Dictionary = load_best_slot(active_save_slot)
	if not bool(result.ok):
		combat_message = str(result.error)
		combat_message_time = 2.0
		return false
	if not SaveSystem.apply_state(self, result.data):
		combat_message = "存档内容无法应用"
		combat_message_time = 2.0
		return false
	last_player_building_id = current_player_building_id()
	combat_message = "已读取自动保存" if bool(result.get("autosave",false)) else ("已从备份恢复" if bool(result.recovered) else "进度已读取")
	combat_message_time = 2.0
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if game_started and int(needs.health) > 0:
			autosave_game("退出游戏")
		get_tree().quit()

func weapon_capture() -> void:
	simulation_paused=true
	inventory.baseball_bat=1
	inventory.kitchen_knife=1
	inventory.hand_axe=1
	add_weapon_instances("baseball_bat",1,63.0)
	add_weapon_instances("kitchen_knife",1,41.0)
	add_weapon_instances("hand_axe",1,58.0)
	equip_weapon("baseball_bat","secondary")
	set_active_weapon_slot("primary")
	open_backpack()
	backpack.selected="baseball_bat"
	backpack.message="选择武器后可装备到主武器或副武器；Q 在游戏中快速切换。"
	backpack.rebuild()
	await get_tree().create_timer(0.8).timeout
	var output:=ProjectSettings.globalize_path("res://build/weapons-v015.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	get_tree().quit()

func survival_capture() -> void:
	simulation_paused=true
	needs={"health":72.0,"food":38.0,"water":21.0,"bleeding":1.0}
	game_time_minutes=3380.0
	player.survival_speed_multiplier=Survival.movement_multiplier(needs)
	player.run_allowed=Survival.can_run(needs)
	world_tint.color=Survival.light_color(game_time_minutes)
	update_survival_hud()
	await get_tree().create_timer(0.8).timeout
	var output:=ProjectSettings.globalize_path("res://build/survival-v014.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	needs.health=0.0
	show_game_over()
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/death-v014.png"))
	get_tree().quit()

func loot_capture() -> void:
	simulation_paused = true
	for item_id: String in Catalog.ITEMS.keys():
		inventory[item_id] = 0
	inventory.fresh_food = 2
	inventory.canned_soup = 2
	inventory.energy_bar = 3
	inventory.soda = 2
	inventory.coffee = 1
	inventory.disinfectant = 1
	inventory.antibiotics = 1
	inventory.duct_tape = 2
	inventory.crowbar = 1
	weapon_durability.crowbar = [58.0]
	equipment.primary = "crowbar"
	active_weapon_slot = "primary"
	fresh_food_expiry_minutes = game_time_minutes + 2160.0
	open_backpack()
	backpack.selected = "fresh_food"
	backpack.message = "新版物资已按住宅、商店、浴室、仓储与尸体分类投放。"
	backpack.rebuild()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/loot-items-v026.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("LOOT CAPTURE PASS: build/loot-items-v026.png")
	get_tree().quit()

func clothing_capture() -> void:
	simulation_paused = true
	for item_id: String in Catalog.ITEMS.keys():
		inventory[item_id] = 0
	for item_id: String in Catalog.CLOTHING_IDS:
		inventory[item_id] = 1
		clothing_durability[item_id] = [ClothingRules.max_durability(item_id)]
	clothing_durability.leather_jacket = [63.0]
	clothing_durability.work_boots = [54.0]
	clothing_equipment = {"head":"motorcycle_helmet","torso":"leather_jacket","legs":"cargo_pants","feet":"work_boots"}
	open_backpack()
	backpack.selected = "leather_jacket"
	backpack.message = "穿戴后仍计入背包负重；点击左侧已穿戴部位可脱下。"
	backpack.rebuild()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/clothing-protection-v027.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("CLOTHING CAPTURE PASS: build/clothing-protection-v027.png")
	get_tree().quit()

func utility_capture() -> void:
	simulation_paused=true
	power_cutoff_minutes=game_time_minutes+1440.0
	water_cutoff_minutes=game_time_minutes+2880.0
	inventory.empty_bottle=3
	inventory.water=1
	needs.water=42.0
	var building: Node2D=world_map.blue_house
	var sink_index:=-1
	for index: int in building.furniture.size():
		if UtilityRules.is_sink(str(building.furniture[index].title)):
			sink_index=index
			break
	assert(sink_index>=0)
	player.position=world_map.map_to_world((building.furniture[sink_index].use_zone as Rect2).get_center())
	open_loot(sink_index,building)
	loot_overlay.message="水龙头可直接饮水，也可把喝完留下的空瓶重新灌满。"
	loot_overlay.rebuild()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output:=ProjectSettings.globalize_path("res://build/utilities-v028.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("UTILITY CAPTURE PASS: build/utilities-v028.png")
	get_tree().quit()

func skill_capture() -> void:
	simulation_paused=true
	skills=SkillRules.sanitize({
		"fitness":{"xp":135},
		"melee":{"xp":74},
		"scavenging":{"xp":228},
		"survival":{"xp":38},
	})
	open_skills_panel()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output:=ProjectSettings.globalize_path("res://build/skills-v029.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("SKILL CAPTURE PASS: build/skills-v029.png")
	get_tree().quit()

func vehicle_capture() -> void:
	simulation_paused=true
	var vehicle: Node2D=world_map.vehicles[0]
	player.position=vehicle.position+world_map.map_to_world(Vector2(0,2.4))
	player.update_depth()
	inventory.gas_can=1
	camera.position_smoothing_enabled=false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var exterior_output:=ProjectSettings.globalize_path("res://build/vehicle-exterior-v030.png")
	DirAccess.make_dir_recursive_absolute(exterior_output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(exterior_output)
	open_vehicle_panel(vehicle)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output:=ProjectSettings.globalize_path("res://build/vehicle-v030.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("VEHICLE CAPTURE PASS: build/vehicle-v030.png")
	get_tree().quit()

func character_capture() -> void:
	show_product_shell()
	product_shell.begin_character_creation(1)
	product_shell.selected_profession="mechanic"
	product_shell.selected_traits.clear()
	product_shell.selected_traits.append("strong")
	product_shell.selected_traits.append("noisy")
	product_shell.rebuild()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output:=ProjectSettings.globalize_path("res://build/character-creator-v031.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("CHARACTER CAPTURE PASS: build/character-creator-v031.png")
	get_tree().quit()

func run_house_flow(capture_frames: bool) -> void:
	await preload("res://scripts/house_flow_test.gd").run(self,capture_frames)

func item_name(key: String) -> String:
	return str(Catalog.item(key).get("name", key))

func layout_test() -> void:
	await get_tree().process_frame
	assert(world_map.validate_layout(),"Map layout or expansion grid validation failed")
	assert(world_map.get_node("Ground") != null)
	assert(world_map.get_node("Roads") != null)
	assert(world_map.get_node("Buildings") != null)
	assert(world_map.surfaces.size() >= 11)
	for surface in world_map.surfaces: assert(surface.texture != null)
	print("TERRAIN PASS: 512x576 map, textured surfaces, continuous roads and three enterable buildings")
	get_tree().quit()

func capture() -> void:
	player.position = world_map.map_to_world(Vector2(48,36))
	camera.zoom = Vector2(0.22,0.22)
	camera.position_smoothing_enabled = false
	await get_tree().create_timer(1.2).timeout
	var output := ProjectSettings.globalize_path("res://build/terrain-v02.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	get_tree().quit()

func house_capture() -> void:
	camera.zoom = Vector2(0.9,0.9)
	camera.position_smoothing_enabled = false
	camera.position = Vector2(-20,-135)
	player.position = world_map.map_to_world(Vector2(30,54))
	await get_tree().create_timer(1.0).timeout
	var output_dir := ProjectSettings.globalize_path("res://build")
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("blue-house-exterior-v04.png"))
	camera.position = Vector2(0,-25)
	player.position = world_map.map_to_world(Vector2(24,48))
	for i in 8: world_map.blue_house.update_player(player.position)
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("blue-house-interior-v04.png"))
	player.position = world_map.map_to_world(Vector2(28,47))
	world_map.blue_house.update_player(player.position)
	open_loot(1)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("blue-house-search-v04.png"))
	get_tree().quit()

func b01_capture() -> void:
	var building: Node2D = world_map.residential_b01
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2(0.58,0.58)
	camera.position = Vector2(0,-95)
	player.position = world_map.map_to_world(Vector2(65.3,143.3))
	player.update_depth()
	building.update_player(player.position,1.0)
	await get_tree().create_timer(0.8).timeout
	var output_dir := ProjectSettings.globalize_path("res://build")
	DirAccess.make_dir_recursive_absolute(output_dir)
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("residential-b01-exterior-v011.png"))
	door_open_for_capture(building)
	player.position = world_map.map_to_world(Vector2(58.7,137.4))
	player.update_depth()
	building.update_player(player.position,1.0)
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("residential-b01-interior-v011.png"))
	var target: int = building.nearest_furniture(player.position)
	if target >= 0:
		open_loot(target,building)
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(output_dir.path_join("residential-b01-search-v011.png"))
	get_tree().quit()

func b01_preview() -> void:
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2(0.44,0.44)
	camera.position = Vector2(0,-90)
	player.position = world_map.map_to_world(Vector2(65.3,143.3))
	player.update_depth()
	world_map.expansion.update_chunks(Vector2(65.3,143.3))

func run_player_controls_test() -> void:
	await preload("res://scripts/player_controls_test.gd").run(self)

func run_combat_test() -> void:
	await preload("res://scripts/combat_test.gd").run(self)

func combat_capture() -> void:
	player.set_physics_process(false)
	camera.position_smoothing_enabled=false
	camera.zoom=Vector2(0.72,0.72)
	camera.position=Vector2(0,-95)
	player.position=world_map.map_to_world(Vector2(36,49))
	var positions: Array[Vector2]=[Vector2(38.0,49.2),Vector2(39.8,51.5),Vector2(33.5,46.8),Vector2(41.0,47.0)]
	for i: int in zombies.size():
		zombies[i].set_process(false)
		if i >= positions.size():
			zombies[i].visible = false
			continue
		zombies[i].position=world_map.map_to_world(positions[i])
		zombies[i].alerted=true
		zombies[i].change_state(zombies[i].State.CHASE)
		zombies[i].queue_redraw()
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png("res://build/combat-v013.png")
	get_tree().quit()

var catalog_index := 0

func catalog_preview() -> void:
	close_loot()
	var house: Node2D=world_map.interactive_buildings[3+catalog_index]
	var point: Vector2=world_map.world_to_map(house.door_midpoint())+Vector2(0,4)
	player.position=world_map.map_to_world(point)
	player.update_depth()
	camera.position_smoothing_enabled=false
	world_map.expansion.update_chunks(point)
	DisplayServer.window_set_title("余烬街区 · "+str(house.config.title)+" · F6 下一栋 / E 开门搜索")

func catalog_capture() -> void:
	player.set_physics_process(false)
	for i in 8:
		catalog_index=i
		catalog_preview()
		player.set_physics_process(false)
		camera.zoom=Vector2(.44,.44)
		await get_tree().create_timer(.35).timeout
		var house: Node2D=world_map.interactive_buildings[3+i]
		get_viewport().get_texture().get_image().save_png("res://build/"+str(house.name)+"-exterior.png")
		house.door_component.opened=true
		player.position=house.door_midpoint()-world_map.map_to_world(Vector2(0,2))
		player.update_depth()
		house.update_player(player.position,1)
		await get_tree().create_timer(.35).timeout
		get_viewport().get_texture().get_image().save_png("res://build/"+str(house.name)+"-interior.png")
	get_tree().quit()

func door_open_for_capture(building: Node2D) -> void:
	building.door_component.opened = true
	building.door_component.amount = 1.0
	building.rear_door.opened = true
	building.rear_door.amount = 1.0

func run_store_flow(capture_frames: bool) -> void:
	await preload("res://scripts/store_flow_test.gd").run(self,capture_frames)

func run_expansion_test() -> void:
	await preload("res://scripts/expansion_test.gd").run(self)

func run_b01_test() -> void:
	await preload("res://scripts/residential_b01_test.gd").run(self)
