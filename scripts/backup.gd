class_name Backup
## All saved progress as one text code, to carry it to another browser or the
## installed app (Safari and the home screen app keep separate storage):
## best times and splits, statistics and finish history, settings, tuning
## and tuning sets. Ghosts stay behind (too big). "GCB1:" + base64 of the
## deflated files.
## Pasting a code back only takes plain values (numbers, text, lists): a
## code from elsewhere cannot smuggle objects into the game.

const PREFIX := "GCB1:"
const FILES := ["user://records.cfg", "user://stats.cfg", "user://history.cfg", "user://settings.cfg",
		"user://tuning_v3.cfg", "user://tuning_presets.cfg"]
const MAX_DATA := 1024 * 1024
const PLAIN_TYPES := [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME,
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,
		TYPE_PACKED_STRING_ARRAY]


static func code() -> String:
	var files := {}
	for path: String in FILES:
		if FileAccess.file_exists(path):
			files[path.get_file()] = FileAccess.get_file_as_string(path)
	var packed := JSON.stringify(files).to_utf8_buffer().compress(FileAccess.COMPRESSION_DEFLATE)
	return PREFIX + Marshalls.raw_to_base64(packed)


## Writes the saved files from a code (found anywhere in the text). Returns
## the number of files restored, -1 if there is no valid code.
static func restore(text: String) -> int:
	var found := RegEx.create_from_string(PREFIX + "([A-Za-z0-9+/=]+)").search(text)
	if found == null:
		return -1
	var packed := Marshalls.base64_to_raw(found.get_string(1))
	if packed.is_empty():
		return -1
	var data := packed.decompress_dynamic(MAX_DATA, FileAccess.COMPRESSION_DEFLATE)
	var files: Variant = JSON.parse_string(data.get_string_from_utf8())
	if not files is Dictionary:
		return -1
	var restored := 0
	for path: String in FILES:
		var content: Variant = files.get(path.get_file())
		if not content is String:
			continue
		var cfg := ConfigFile.new()
		if cfg.parse(content) != OK:
			continue
		var clean := ConfigFile.new()
		for section in cfg.get_sections():
			for key in cfg.get_section_keys(section):
				var value: Variant = cfg.get_value(section, key)
				if is_plain(value):
					clean.set_value(section, key, value)
		clean.save(path)
		restored += 1
	return restored


## Only numbers, text, booleans, and lists and dictionaries of them.
static func is_plain(value: Variant) -> bool:
	if typeof(value) in PLAIN_TYPES:
		return true
	if value is Array:
		return (value as Array).all(is_plain)
	if value is Dictionary:
		for k: Variant in value:
			if not is_plain(k) or not is_plain(value[k]):
				return false
		return true
	return false
