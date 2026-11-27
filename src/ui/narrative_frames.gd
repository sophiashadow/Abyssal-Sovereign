class_name NarrativeFrames
extends RefCounted
## Presentation-only loader for M8.9 narrative framing copy and localization keys.

const PATH := "res://content/presentation/narrative_frames.json"

var data: Dictionary = {}


func load_default() -> void:
	var text := ""
	if FileAccess.file_exists(PATH):
		text = FileAccess.get_file_as_string(PATH)
	else:
		var abs_path := ProjectSettings.globalize_path(PATH)
		if FileAccess.file_exists(abs_path):
			text = FileAccess.get_file_as_string(abs_path)
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		data = parsed


func opening_frame() -> Dictionary:
	return data.get("opening_descent", {})


func sphere_frame(sphere_num: int) -> Dictionary:
	var spheres: Variant = data.get("spheres", {})
	if spheres is Dictionary:
		return spheres.get(str(clampi(sphere_num, 1, 7)), {})
	return {}


func boss_kicker() -> String:
	var bs: Variant = data.get("boss_sighting", {})
	if bs is Dictionary:
		return String(bs.get("kicker", "ADVERSARY AT THE SEAL"))
	return "ADVERSARY AT THE SEAL"
