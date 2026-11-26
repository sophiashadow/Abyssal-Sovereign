class_name GameSettings
extends RefCounted
## Player preferences, stored in user://settings.cfg. Separate from the run
## save: deleting a run on death never touches settings.

const PATH := "user://settings.cfg"
const TEXT_SCALES: Array[float] = [0.85, 1.0, 1.15, 1.3, 1.5, 1.75]
const TILE_SIZES: Array[int] = [16, 20, 24, 28, 32, 40, 48]

var text_scale_index: int = 1
var tile_size_index: int = 2
## On-screen d-pad and action buttons. Defaults on for touch devices.
var touch_controls: bool = false
## Steps per second while travelling to a tapped tile.
var travel_speed: int = 20


func _init() -> void:
	touch_controls = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if OS.has_feature("mobile"):
		text_scale_index = 2
		tile_size_index = 4


func text_scale() -> float:
	return TEXT_SCALES[clampi(text_scale_index, 0, TEXT_SCALES.size() - 1)]


func tile_size() -> int:
	return TILE_SIZES[clampi(tile_size_index, 0, TILE_SIZES.size() - 1)]


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	text_scale_index = clampi(int(cfg.get_value("display", "text_scale_index", text_scale_index)), 0, TEXT_SCALES.size() - 1)
	tile_size_index = clampi(int(cfg.get_value("display", "tile_size_index", tile_size_index)), 0, TILE_SIZES.size() - 1)
	touch_controls = bool(cfg.get_value("input", "touch_controls", touch_controls))
	travel_speed = clampi(int(cfg.get_value("input", "travel_speed", travel_speed)), 5, 60)


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "text_scale_index", text_scale_index)
	cfg.set_value("display", "tile_size_index", tile_size_index)
	cfg.set_value("input", "touch_controls", touch_controls)
	cfg.set_value("input", "travel_speed", travel_speed)
	cfg.save(PATH)
