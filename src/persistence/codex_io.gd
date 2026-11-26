class_name CodexIO
extends RefCounted
## Atomic persistence for the cross-run knowledge-only Codex (user://codex.json).
## Completely separate from user://run.save.json and never read by World.

const DEFAULT_PATH := "user://codex.json"


static func save(codex: Codex, path: String = DEFAULT_PATH) -> Error:
	if codex == null:
		return ERR_INVALID_PARAMETER
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(codex.to_dict()))
	f.close()
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return ERR_CANT_OPEN
	return dir.rename(tmp.get_file(), path.get_file())


static func load_codex(path: String = DEFAULT_PATH) -> Codex:
	if not FileAccess.file_exists(path):
		return Codex.new()
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		return Codex.new()
	return Codex.from_dict(json.data)


static func delete(path: String = DEFAULT_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
