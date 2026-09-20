extends RefCounted

const DEFAULT_POWER_CUTOFF_MINUTES := 5400.0
const DEFAULT_WATER_CUTOFF_MINUTES := 7680.0
const OUTAGE_FRESH_FOOD_GRACE_MINUTES := 720.0

static func power_on(game_minutes: float, cutoff_minutes: float) -> bool:
	return game_minutes < cutoff_minutes

static func water_on(game_minutes: float, cutoff_minutes: float) -> bool:
	return game_minutes < cutoff_minutes

static func is_sink(title: String) -> bool:
	return "厨房橱柜" in title or "浴室柜" in title or "洗手池" in title or "水槽" in title

static func is_refrigerator(title: String) -> bool:
	return "冰箱" in title or "冷柜" in title

static func cutoff_clock_text(cutoff_minutes: float) -> String:
	var whole := maxi(0, int(floor(cutoff_minutes)))
	return "第%d天 %02d:%02d" % [whole / 1440 + 1, (whole % 1440) / 60, whole % 60]

static func service_text(name: String, available: bool, cutoff_minutes: float) -> String:
	return "%s：正常 · %s中断" % [name, cutoff_clock_text(cutoff_minutes)] if available else "%s：已中断" % name

static func darken_for_unpowered_interior(base: Color, game_minutes: float, inside: bool, available: bool) -> Color:
	var minute_of_day := fmod(game_minutes, 1440.0)
	var night := minute_of_day < 360.0 or minute_of_day >= 1200.0
	if available or not inside or not night:
		return base
	return Color(base.r * 0.55, base.g * 0.58, base.b * 0.68, base.a)
