class_name Settings
## Player settings from the pause menu (ghost, sound, outfit), kept in user://.

const PATH := "user://settings.cfg"

static var ghost_enabled := true
static var sound_enabled := true
## Name of the climber's outfit (Outfits.LIST).
static var outfit := "Classic"


static func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		ghost_enabled = cfg.get_value("settings", "ghost", true)
		sound_enabled = cfg.get_value("settings", "sound", true)
		outfit = cfg.get_value("settings", "outfit", "Classic")
	apply()


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "ghost", ghost_enabled)
	cfg.set_value("settings", "sound", sound_enabled)
	cfg.set_value("settings", "outfit", outfit)
	cfg.save(PATH)
	apply()


static func apply() -> void:
	AudioServer.set_bus_mute(0, not sound_enabled)
