class_name GameSettings
extends RefCounted
## Player preferences, stored in user://settings.cfg. Separate from the run
## save: deleting a run on death never touches settings.

const PATH := "user://settings.cfg"
const TEXT_SCALES: Array[float] = [0.85, 1.0, 1.15, 1.3, 1.5, 1.75]
const TILE_SIZES: Array[int] = [16, 20, 24, 28, 32, 40, 48, 64]
const ZOOM_LEVELS: Array[float] = [0.75, 1.0, 1.25, 1.5, 2.0]
const COLOR_MODES: Array[String] = ["Standard", "Deutan/Protan", "Tritan"]
const ANIM_SPEEDS: Array[float] = [0.5, 1.0, 1.5, 2.0]
const FLASH_LEVELS: Array[float] = [0.0, 0.3, 0.6, 1.0]

var text_scale_index: int = 1
var tile_size_index: int = 4
## M8.2 presentation & accessibility preferences (never affect simulation).
var render_mode: String = "tiles" ## "tiles" or "glyph"
var integer_scale: bool = true
var camera_zoom: float = 1.0
var decorative_lighting: bool = true
var color_mode: int = 0 ## 0=Standard, 1=R/G-safe, 2=B/Y-safe
var high_contrast: bool = false
var left_handed: bool = false
## M8.6 motion & visual feedback preferences.
var anim_speed: float = 1.0
var instant_actions: bool = false
var reduced_motion: bool = false
var screen_shake: bool = true
var particles: bool = true
var floating_text: bool = true
var flash_intensity: float = 0.6
## On-screen d-pad and action buttons. Defaults on for touch devices.
var touch_controls: bool = false
## Steps per second while travelling or auto-exploring.
var travel_speed: int = 20
## When true, auto-explore and travel run to their stop in one go instead of animating.
var instant_auto: bool = false
## Advisory lines on the Sphere Gate screen (under-levelled, low health, no healing).
var warn_descent: bool = true
## M7.8 onboarding: optional one-time hints, and the profile last chosen.
var hints_on: bool = true
var hints_seen: Dictionary = {}
var last_profile: String = "exile"
## Ask before irreversible choices (Transmute, abandoning a thread, dropping a relic or rare item).
var confirm_destructive: bool = true
## Which message kinds the log shows; indexes LOG_FILTERS.
var log_filter_index: int = 0
## Pack view: indexes Assist.SORTS and Assist.FILTERS.
var inv_sort_index: int = 0
var inv_filter_index: int = 0
## Rebound keys: action id -> keycode. Missing actions use SHORTCUT_DEFAULTS.
var shortcuts: Dictionary = {}

const LOG_FILTERS: Array = [
	{"name": "All", "kinds": []},
	{"name": "Combat", "kinds": ["combat", "danger", "good"]},
	{"name": "Dangers", "kinds": ["danger"]},
	{"name": "Story", "kinds": ["lore", "good"]},
]
## Rebindable commands, in menu order: id -> [label, default key]. Movement,
## wait, stairs, talent numbers 1-6 and Esc are fixed.
const SHORTCUT_ORDER: Array[String] = ["pickup", "inventory", "rest", "explore", "look", "build", "abilities", "fire",
		"search", "interact", "masks", "atlas", "people", "threads", "codex", "logfilter"]
const SHORTCUT_DEFAULTS := {
	"pickup": ["Get", KEY_G], "inventory": ["Bag", KEY_I], "rest": ["Rest", KEY_R], "explore": ["Auto-explore", KEY_O],
	"look": ["Look", KEY_X], "build": ["Build", KEY_C], "abilities": ["Abilities", KEY_A], "fire": ["Fire", KEY_F],
	"search": ["Search", KEY_S], "interact": ["Use feature", KEY_E], "masks": ["Masks", KEY_M], "atlas": ["Atlas", KEY_TAB],
	"people": ["People", KEY_P], "threads": ["Threads", KEY_T], "codex": ["Codex", KEY_Z], "logfilter": ["Log filter", KEY_Q],
}
## Keys that movement already owns; never offered for rebinding.
const RESERVED_KEYS: Array[int] = [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_PERIOD, KEY_COMMA,
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_H, KEY_J, KEY_K, KEY_L, KEY_Y, KEY_U, KEY_B, KEY_N,
		KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9, KEY_KP_PERIOD,
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]


func _init() -> void:
	touch_controls = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if OS.has_feature("mobile"):
		text_scale_index = 2
		tile_size_index = 4


func text_scale() -> float:
	return TEXT_SCALES[clampi(text_scale_index, 0, TEXT_SCALES.size() - 1)]


func tile_size() -> int:
	return TILE_SIZES[clampi(tile_size_index, 0, TILE_SIZES.size() - 1)]


func log_kinds() -> Array:
	return LOG_FILTERS[clampi(log_filter_index, 0, LOG_FILTERS.size() - 1)]["kinds"]


func log_filter_name() -> String:
	return String(LOG_FILTERS[clampi(log_filter_index, 0, LOG_FILTERS.size() - 1)]["name"])


func key_for(action: String) -> int:
	if shortcuts.has(action):
		return int(shortcuts[action])
	return int(SHORTCUT_DEFAULTS[action][1]) if SHORTCUT_DEFAULTS.has(action) else KEY_NONE


## The action bound to `keycode`, or "".
func action_for(keycode: int) -> String:
	for a in SHORTCUT_ORDER:
		if key_for(a) == keycode:
			return a
	return ""


## Rebinds `action` to `keycode`. Returns "" on success, else why not.
func rebind(action: String, keycode: int) -> String:
	if not SHORTCUT_DEFAULTS.has(action):
		return "Unknown command."
	if RESERVED_KEYS.has(keycode):
		return "%s is used for movement or menus." % OS.get_keycode_string(keycode)
	var other := action_for(keycode)
	if other != "" and other != action:
		return "%s is already %s." % [OS.get_keycode_string(keycode), String(SHORTCUT_DEFAULTS[other][0])]
	shortcuts[action] = keycode
	return ""


func reset_shortcuts() -> void:
	shortcuts.clear()


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	text_scale_index = clampi(int(cfg.get_value("display", "text_scale_index", text_scale_index)), 0, TEXT_SCALES.size() - 1)
	tile_size_index = clampi(int(cfg.get_value("display", "tile_size_index", tile_size_index)), 0, TILE_SIZES.size() - 1)
	var rm := String(cfg.get_value("display", "render_mode", render_mode))
	render_mode = rm if rm in ["tiles", "glyph"] else "tiles"
	integer_scale = bool(cfg.get_value("display", "integer_scale", integer_scale))
	camera_zoom = clampf(float(cfg.get_value("display", "camera_zoom", camera_zoom)), 0.75, 2.0)
	decorative_lighting = bool(cfg.get_value("display", "decorative_lighting", decorative_lighting))
	color_mode = clampi(int(cfg.get_value("accessibility", "color_mode", color_mode)), 0, COLOR_MODES.size() - 1)
	high_contrast = bool(cfg.get_value("accessibility", "high_contrast", high_contrast))
	left_handed = bool(cfg.get_value("accessibility", "left_handed", left_handed))
	anim_speed = clampf(float(cfg.get_value("motion", "anim_speed", anim_speed)), 0.5, 2.0)
	instant_actions = bool(cfg.get_value("motion", "instant_actions", instant_actions))
	reduced_motion = bool(cfg.get_value("motion", "reduced_motion", reduced_motion))
	screen_shake = bool(cfg.get_value("motion", "screen_shake", screen_shake))
	particles = bool(cfg.get_value("motion", "particles", particles))
	floating_text = bool(cfg.get_value("motion", "floating_text", floating_text))
	flash_intensity = clampf(float(cfg.get_value("motion", "flash_intensity", flash_intensity)), 0.0, 1.0)
	touch_controls = bool(cfg.get_value("input", "touch_controls", touch_controls))
	travel_speed = clampi(int(cfg.get_value("input", "travel_speed", travel_speed)), 5, 60)
	instant_auto = bool(cfg.get_value("input", "instant_auto", instant_auto))
	warn_descent = bool(cfg.get_value("assist", "warn_descent", warn_descent))
	hints_on = bool(cfg.get_value("assist", "hints_on", hints_on))
	last_profile = String(cfg.get_value("assist", "last_profile", last_profile))
	hints_seen.clear()
	if cfg.has_section("hints"):
		for h in cfg.get_section_keys("hints"):
			if bool(cfg.get_value("hints", h, false)):
				hints_seen[h] = true
	confirm_destructive = bool(cfg.get_value("assist", "confirm_destructive", confirm_destructive))
	log_filter_index = clampi(int(cfg.get_value("assist", "log_filter_index", log_filter_index)), 0, LOG_FILTERS.size() - 1)
	inv_sort_index = clampi(int(cfg.get_value("assist", "inv_sort_index", inv_sort_index)), 0, Assist.SORTS.size() - 1)
	inv_filter_index = clampi(int(cfg.get_value("assist", "inv_filter_index", inv_filter_index)), 0, Assist.FILTERS.size() - 1)
	shortcuts.clear()
	if cfg.has_section("shortcuts"):
		for a in cfg.get_section_keys("shortcuts"):
			var kc := int(cfg.get_value("shortcuts", a, KEY_NONE))
			if SHORTCUT_DEFAULTS.has(a) and kc != KEY_NONE and not RESERVED_KEYS.has(kc):
				shortcuts[a] = kc
	# A hand-edited file must not bind one key to two commands.
	var seen := {}
	for a in SHORTCUT_ORDER:
		var kc := key_for(a)
		if seen.has(kc):
			shortcuts.erase(a)
		seen[kc] = true


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "text_scale_index", text_scale_index)
	cfg.set_value("display", "tile_size_index", tile_size_index)
	cfg.set_value("display", "render_mode", render_mode)
	cfg.set_value("display", "integer_scale", integer_scale)
	cfg.set_value("display", "camera_zoom", camera_zoom)
	cfg.set_value("display", "decorative_lighting", decorative_lighting)
	cfg.set_value("accessibility", "color_mode", color_mode)
	cfg.set_value("accessibility", "high_contrast", high_contrast)
	cfg.set_value("accessibility", "left_handed", left_handed)
	cfg.set_value("motion", "anim_speed", anim_speed)
	cfg.set_value("motion", "instant_actions", instant_actions)
	cfg.set_value("motion", "reduced_motion", reduced_motion)
	cfg.set_value("motion", "screen_shake", screen_shake)
	cfg.set_value("motion", "particles", particles)
	cfg.set_value("motion", "floating_text", floating_text)
	cfg.set_value("motion", "flash_intensity", flash_intensity)
	cfg.set_value("input", "touch_controls", touch_controls)
	cfg.set_value("input", "travel_speed", travel_speed)
	cfg.set_value("input", "instant_auto", instant_auto)
	cfg.set_value("assist", "warn_descent", warn_descent)
	cfg.set_value("assist", "hints_on", hints_on)
	cfg.set_value("assist", "last_profile", last_profile)
	for h in hints_seen:
		cfg.set_value("hints", String(h), true)
	cfg.set_value("assist", "confirm_destructive", confirm_destructive)
	cfg.set_value("assist", "log_filter_index", log_filter_index)
	cfg.set_value("assist", "inv_sort_index", inv_sort_index)
	cfg.set_value("assist", "inv_filter_index", inv_filter_index)
	for a in shortcuts:
		cfg.set_value("shortcuts", String(a), int(shortcuts[a]))
	cfg.save(PATH)
