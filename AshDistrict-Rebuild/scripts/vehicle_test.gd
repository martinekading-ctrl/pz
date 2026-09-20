extends RefCounted

const Rules=preload("res://scripts/vehicle_rules.gd")
const SaveSystem=preload("res://scripts/save_system.gd")

static func run(game: Node2D) -> void:
	var vehicle: Node2D=game.world_map.vehicles[0]
	assert(Rules.next_speed(0.0,1.0,1.0,true)>4.0 and Rules.next_speed(4.0,-1.0,1.0,true)<4.0,"Throttle and braking must be deterministic")
	assert(Rules.impact_damage(8.0)>0 and Rules.fuel_for_distance(1000.0)>0.0,"Impacts and distance must have costs")
	game.player.position=vehicle.position+game.world_map.map_to_world(Vector2(0.0,2.4))
	game.player.update_depth()
	game.inventory.food=2
	game.inventory.gas_can=1
	vehicle.trunk.clear()
	vehicle.fuel_liters=8.0
	game.open_vehicle_panel(vehicle)
	assert(is_instance_valid(game.vehicle_overlay) and not game.player.is_physics_processing(),"Vehicle page must lock walking")
	assert(game.transfer_vehicle_item(vehicle,"food",1,false).moved==1 and int(vehicle.trunk.food)==1,"Supplies must move into the trunk")
	assert(game.transfer_vehicle_item(vehicle,"food",1,true).moved==1 and int(vehicle.trunk.get("food",0))==0,"Supplies must return without duplication")
	var fuel_before: float=vehicle.fuel_liters
	assert(game.refuel_vehicle(vehicle).ok and vehicle.fuel_liters>fuel_before and int(game.inventory.gas_can)==0,"Fuel cans must refuel and be consumed")
	game.enter_vehicle(vehicle)
	assert(game.active_vehicle==vehicle and vehicle.occupied and not game.player.visible,"Entering must transfer control to the vehicle")
	var position_before:=vehicle.position
	game.game_input.set_touch_move(Vector2(0,-1))
	vehicle._physics_process(0.5)
	game.game_input.set_touch_move(Vector2.ZERO)
	assert(vehicle.position.distance_to(position_before)>0.1 and vehicle.fuel_liters<fuel_before+10.0,"Driving must move and consume fuel")
	vehicle.speed_mps=0.0
	game.exit_vehicle()
	assert(game.active_vehicle==null and game.player.visible,"Exiting must restore the survivor")
	var state:=SaveSystem.capture_state(game)
	assert(not state.vehicles.is_empty() and state.vehicles[0].has("fuel_liters"),"Vehicle state must save")
	var legacy:=state.duplicate(true)
	legacy.version=6
	legacy.erase("vehicles")
	legacy.erase("active_vehicle_id")
	var migrated:=SaveSystem.migrate(legacy)
	assert(int(migrated.version)==SaveSystem.SAVE_VERSION and migrated.has("vehicles"),"Version 6 saves must migrate to vehicle state")
	print("VEHICLE PASS: driving, collision rules, fuel, trunk, enter/exit and save migration")
	game.get_tree().quit()
