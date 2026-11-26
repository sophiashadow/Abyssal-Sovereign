class_name SaveIO
extends RefCounted
## One save slot: the unfinished run. Written atomically (temp file, then
## rename) so a crash or an Android process kill mid-write leaves the
## previous save intact. Deleted on death or victory: permadeath.

const DEFAULT_PATH := "user://run.save.json"


static func exists(path: String = DEFAULT_PATH) -> bool:
	return FileAccess.file_exists(path)


static func save(world: World, path: String = DEFAULT_PATH) -> Error:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(world.to_dict()))
	f.close()
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return ERR_CANT_OPEN
	var err := dir.rename(tmp.get_file(), path.get_file())
	return err


static func load_world(db: ContentDB, errors: PackedStringArray, path: String = DEFAULT_PATH) -> World:
	if not FileAccess.file_exists(path):
		errors.append("no saved run")
		return null
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		errors.append("the saved run is unreadable (line %d: %s)" % [json.get_error_line() + 1, json.get_error_message()])
		return null
	return World.from_dict(db, json.data, errors)


static func delete(path: String = DEFAULT_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
