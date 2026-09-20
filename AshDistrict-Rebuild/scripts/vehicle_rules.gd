extends RefCounted

const MAX_FUEL_LITERS := 45.0
const MAX_FORWARD_MPS := 15.0
const MAX_REVERSE_MPS := 5.0
const ACCELERATION_MPS2 := 4.8
const BRAKE_MPS2 := 9.0
const COAST_DRAG_MPS2 := 2.2
const STEERING_RADIANS_PER_SECOND := 1.28
const FUEL_LITERS_PER_METER := 0.00012
const TRUNK_MAX_WEIGHT := 45.0
const TRUNK_MAX_SLOTS := 40

static func next_speed(current: float, throttle: float, delta: float, has_fuel: bool) -> float:
	var input := clampf(throttle,-1.0,1.0) if has_fuel else 0.0
	if absf(input)<0.05:
		return move_toward(current,0.0,COAST_DRAG_MPS2*delta)
	var target := MAX_FORWARD_MPS*input if input>=0.0 else MAX_REVERSE_MPS*input
	var rate := BRAKE_MPS2 if current*input<0.0 else ACCELERATION_MPS2
	return move_toward(current,target,rate*delta)

static func steering_delta(speed_mps: float, steer: float, delta: float) -> float:
	var response := clampf(absf(speed_mps)/3.0,0.18,1.0)
	return clampf(steer,-1.0,1.0)*STEERING_RADIANS_PER_SECOND*response*delta*(1.0 if speed_mps>=0.0 else -1.0)

static func fuel_for_distance(distance_meters: float) -> float:
	return maxf(0.0,distance_meters)*FUEL_LITERS_PER_METER

static func collision_condition_loss(speed_mps: float) -> float:
	return maxf(0.0,absf(speed_mps)-2.0)*0.9

static func impact_damage(speed_mps: float) -> int:
	return roundi(maxf(0.0,absf(speed_mps)-2.0)*8.0)

static func speed_kph(speed_mps: float) -> int:
	return roundi(absf(speed_mps)*3.6)
