extends RefCounted

const MAX_STAMINA := 100.0
const RUN_DRAIN_PER_SECOND := 11.0
const BASE_REGEN_PER_SECOND := 16.0
const RECOVERY_DELAY_SECONDS := 0.85
const MIN_RUN_STAMINA := 8.0
const BASE_ATTACK_COST := 9.0
const ATTACK_WEIGHT_COST := 2.3

static func advance_stamina(needs: Dictionary, real_seconds: float, running: bool, recovery_delay: float, drain_multiplier: float = 1.0, regen_multiplier: float = 1.0) -> float:
	var stamina := clampf(float(needs.get("stamina", MAX_STAMINA)), 0.0, MAX_STAMINA)
	if running:
		needs.stamina = maxf(0.0, stamina - RUN_DRAIN_PER_SECOND * maxf(0.0,drain_multiplier) * real_seconds)
		return RECOVERY_DELAY_SECONDS
	var remaining_delay := recovery_delay - real_seconds
	if remaining_delay < 0.0:
		var fatigue := clampf(float(needs.get("fatigue", 0.0)), 0.0, 100.0)
		var fatigue_factor := lerpf(1.0, 0.42, fatigue / 100.0)
		needs.stamina = minf(MAX_STAMINA, stamina + BASE_REGEN_PER_SECOND * fatigue_factor * maxf(0.0,regen_multiplier) * -remaining_delay)
	return maxf(0.0, remaining_delay)

static func attack_cost(weapon_weight: float) -> float:
	return BASE_ATTACK_COST + maxf(0.0, weapon_weight) * ATTACK_WEIGHT_COST

static func spend_attack(needs: Dictionary, cost: float) -> bool:
	var stamina := float(needs.get("stamina", MAX_STAMINA))
	if stamina + 0.001 < cost:
		return false
	needs.stamina = maxf(0.0, stamina - cost)
	return true

static func can_run(needs: Dictionary) -> bool:
	return float(needs.get("stamina", MAX_STAMINA)) >= MIN_RUN_STAMINA and float(needs.get("fatigue", 0.0)) < 90.0

static func movement_noise_radius(running: bool, crouching: bool) -> float:
	if crouching:
		return 1.8
	return 10.0 if running else 4.5

static func movement_noise_interval(running: bool, crouching: bool) -> float:
	if crouching:
		return 0.82
	return 0.32 if running else 0.58

static func fatigue_speed_multiplier(needs: Dictionary) -> float:
	var fatigue := float(needs.get("fatigue", 0.0))
	if fatigue >= 90.0:
		return 0.72
	if fatigue >= 75.0:
		return 0.86
	return 1.0
