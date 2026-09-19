extends RefCounted

const PATH := "user://ash_district_settings.cfg"
const DEFAULTS := {
	"master_volume":0.82,
	"sfx_volume":0.86,
	"fullscreen":false,
	"mobile_layout":"standard",
}

static func sanitize(values: Dictionary) -> Dictionary:
	return {
		"master_volume":clampf(float(values.get("master_volume",DEFAULTS.master_volume)),0.0,1.0),
		"sfx_volume":clampf(float(values.get("sfx_volume",DEFAULTS.sfx_volume)),0.0,1.0),
		"fullscreen":bool(values.get("fullscreen",DEFAULTS.fullscreen)),
		"mobile_layout":str(values.get("mobile_layout",DEFAULTS.mobile_layout)) if str(values.get("mobile_layout",DEFAULTS.mobile_layout)) in ["standard","compact","mirrored"] else "standard",
	}

static func load_values() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return DEFAULTS.duplicate(true)
	return sanitize({
		"master_volume":config.get_value("audio","master_volume",DEFAULTS.master_volume),
		"sfx_volume":config.get_value("audio","sfx_volume",DEFAULTS.sfx_volume),
		"fullscreen":config.get_value("display","fullscreen",DEFAULTS.fullscreen),
		"mobile_layout":config.get_value("controls","mobile_layout",DEFAULTS.mobile_layout),
	})

static func save_values(values: Dictionary) -> int:
	var clean := sanitize(values)
	var config := ConfigFile.new()
	config.set_value("audio","master_volume",clean.master_volume)
	config.set_value("audio","sfx_volume",clean.sfx_volume)
	config.set_value("display","fullscreen",clean.fullscreen)
	config.set_value("controls","mobile_layout",clean.mobile_layout)
	return config.save(PATH)

static func apply(values: Dictionary,allow_window_change := true) -> Dictionary:
	var clean := sanitize(values)
	set_bus_volume("Master",float(clean.master_volume))
	set_bus_volume("SFX",float(clean.sfx_volume))
	if allow_window_change and not OS.has_feature("mobile") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(clean.fullscreen) else DisplayServer.WINDOW_MODE_WINDOWED)
	return clean

static func set_bus_volume(bus_name: String,value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index,value <= 0.001)
	AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.001)))
