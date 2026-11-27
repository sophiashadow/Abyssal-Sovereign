class_name AudioManager
extends Node
## Presentation-only audio director (M8.7 + M8.8).
## Strictly separated from simulation RNG and turn outcomes: uses an isolated
## cosmetic RandomNumberGenerator for micro pitch variation and fails silently
## when audio is disabled, headless/Dummy driver is active, or tracks are absent.

const BUSES: Array[String] = ["Master", "Music", "Ambience", "Combat", "Interface", "Narrative"]
const SFX_POOL_SIZE := 6
const SPHERE_NAMES: Array[String] = ["", "moon", "mercury", "venus", "sun", "mars", "jupiter", "saturn"]
const SOUNDTRACK_MANIFEST_PATH := "res://content/presentation/soundtrack_manifest.json"

var audio_enabled: bool = true
var current_sphere: int = 0
var current_music_context: String = ""
var _paused: bool = false
var _last_event_serial: int = 0
var _cosmetic_rng := RandomNumberGenerator.new()

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _ambience_player: AudioStreamPlayer
var _music_decks: Array[AudioStreamPlayer] = []
var _active_deck: int = 0
var _stream_cache: Dictionary = {}
var _music_manifest: Dictionary = {}


func _ready() -> void:
	_cosmetic_rng.seed = 0x56454E45
	ensure_buses()
	_ensure_players()
	ensure_manifest()


func ensure_manifest() -> void:
	if not _music_manifest.is_empty():
		return
	var abs_path := ProjectSettings.globalize_path(SOUNDTRACK_MANIFEST_PATH)
	var text := ""
	if FileAccess.file_exists(SOUNDTRACK_MANIFEST_PATH):
		text = FileAccess.get_file_as_string(SOUNDTRACK_MANIFEST_PATH)
	elif FileAccess.file_exists(abs_path):
		text = FileAccess.get_file_as_string(abs_path)
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		for ctx in parsed.get("contexts", []):
			if ctx is Dictionary and ctx.has("context_id"):
				_music_manifest[String(ctx["context_id"])] = ctx


func manifest_contexts() -> Dictionary:
	ensure_manifest()
	return _music_manifest


func _exit_tree() -> void:
	for p in _sfx_pool:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	if _ambience_player != null and is_instance_valid(_ambience_player):
		_ambience_player.stop()
		_ambience_player.stream = null
	for m in _music_decks:
		if is_instance_valid(m):
			m.stop()
			m.stream = null
	_stream_cache.clear()


func ensure_buses() -> void:
	for b in BUSES:
		if b == "Master":
			continue
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, &"Master")


func _ensure_players() -> void:
	if _sfx_pool.is_empty():
		for i in range(SFX_POOL_SIZE):
			var p := AudioStreamPlayer.new()
			p.bus = &"Combat"
			add_child(p)
			_sfx_pool.append(p)
	if _ambience_player == null:
		_ambience_player = AudioStreamPlayer.new()
		_ambience_player.bus = &"Ambience"
		add_child(_ambience_player)
	if _music_decks.is_empty():
		for i in range(2):
			var m := AudioStreamPlayer.new()
			m.bus = &"Music"
			add_child(m)
			_music_decks.append(m)


func apply_settings(settings: GameSettings) -> void:
	ensure_buses()
	audio_enabled = settings.audio_enabled
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, (not audio_enabled) or _paused or settings.vol_master <= 0.001)
		AudioServer.set_bus_volume_db(master_idx, _lin_to_db(settings.vol_master))
	var vols := {
		"Music": settings.vol_music,
		"Ambience": settings.vol_ambience,
		"Combat": settings.vol_combat,
		"Interface": settings.vol_interface,
		"Narrative": settings.vol_narrative,
	}
	for bus_name in vols:
		var idx := AudioServer.get_bus_index(String(bus_name))
		if idx >= 0:
			var v := float(vols[bus_name])
			AudioServer.set_bus_mute(idx, (not audio_enabled) or v <= 0.001)
			AudioServer.set_bus_volume_db(idx, _lin_to_db(v))
	if not audio_enabled:
		if _ambience_player != null and _ambience_player.playing:
			_ambience_player.stop()
		for m in _music_decks:
			if m.playing:
				m.stop()


func set_paused(paused: bool) -> void:
	_paused = paused
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, paused or not audio_enabled)
	if _ambience_player != null:
		_ambience_player.stream_paused = paused
	for m in _music_decks:
		m.stream_paused = paused


func reset_event_cursor(serial: int) -> void:
	_last_event_serial = serial


func _lin_to_db(v: float) -> float:
	return -80.0 if v <= 0.001 else linear_to_db(clampf(v, 0.001, 1.0))


func _load_stream(res_path: String, want_loop: bool = false) -> AudioStream:
	if _stream_cache.has(res_path):
		return _stream_cache[res_path]
	var stream: AudioStream = null
	if ResourceLoader.exists(res_path):
		var loaded := ResourceLoader.load(res_path)
		if loaded is AudioStream:
			stream = loaded
	if stream == null:
		var abs_path := ProjectSettings.globalize_path(res_path)
		if FileAccess.file_exists(abs_path) and abs_path.ends_with(".ogg"):
			stream = AudioStreamOggVorbis.load_from_file(abs_path)
	if stream != null and want_loop and stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_stream_cache[res_path] = stream
	return stream


func play_sfx(sfx_id: String, bus: String = "Combat", pitch_jitter: float = 0.05) -> bool:
	if not audio_enabled or _paused:
		return false
	_ensure_players()
	var path := "res://assets/audio/sfx/%s.ogg" % sfx_id
	var stream := _load_stream(path, false)
	if stream == null or _sfx_pool.is_empty():
		return false
	var player := _sfx_pool[_sfx_cursor % _sfx_pool.size()]
	_sfx_cursor += 1
	player.bus = StringName(bus if BUSES.has(bus) else "Combat")
	player.stream = stream
	player.pitch_scale = 1.0 + _cosmetic_rng.randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 1.0
	player.play()
	return true


func play_ui(sfx_id: String = "ui_click") -> bool:
	return play_sfx(sfx_id, "Interface", 0.02)


func set_ambience_sphere(sphere_num: int) -> bool:
	if sphere_num == current_sphere and _ambience_player != null and (_ambience_player.playing or not audio_enabled):
		return true
	current_sphere = sphere_num
	_ensure_players()
	if sphere_num < 1 or sphere_num >= SPHERE_NAMES.size() or not audio_enabled:
		if _ambience_player != null and _ambience_player.playing:
			_ambience_player.stop()
		return false
	var sid := SPHERE_NAMES[sphere_num]
	var path := "res://assets/audio/ambience/sphere_%d_%s.ogg" % [sphere_num, sid]
	var stream := _load_stream(path, true)
	if stream == null:
		if _ambience_player.playing:
			_ambience_player.stop()
		return false
	if _ambience_player.stream != stream or not _ambience_player.playing:
		_ambience_player.stream = stream
		_ambience_player.play()
	return true


func play_music_context(context_id: String, fade_sec: float = 1.2) -> bool:
	ensure_manifest()
	if not _music_manifest.has(context_id):
		return play_music_track(context_id, "", fade_sec, true)
	var ctx: Dictionary = _music_manifest[context_id]
	var path := String(ctx.get("track_path", ""))
	var want_loop := bool(ctx.get("loop", true))
	return play_music_track(context_id, path, fade_sec, want_loop)


func play_music_track(context_id: String, res_path: String, fade_sec: float = 1.2, want_loop: bool = true) -> bool:
	if context_id == current_music_context and not _music_decks.is_empty() and _music_decks[_active_deck].playing:
		return true
	current_music_context = context_id
	_ensure_players()
	if not audio_enabled or res_path.is_empty():
		for m in _music_decks:
			if m.playing:
				m.stop()
		return false
	var stream := _load_stream(res_path, want_loop)
	if stream == null:
		for m in _music_decks:
			if m.playing:
				m.stop()
		return false
	var prev := _music_decks[_active_deck]
	_active_deck = (_active_deck + 1) % _music_decks.size()
	var next_deck := _music_decks[_active_deck]
	next_deck.stream = stream
	if prev.playing and fade_sec > 0.05 and is_inside_tree():
		next_deck.volume_db = -32.0
		next_deck.play()
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(next_deck, "volume_db", 0.0, fade_sec)
		tw.tween_property(prev, "volume_db", -36.0, fade_sec)
		tw.chain().tween_callback(func() -> void:
			if is_instance_valid(prev) and prev != _music_decks[_active_deck]:
				prev.stop()
				prev.volume_db = 0.0)
	else:
		if prev.playing:
			prev.stop()
		next_deck.volume_db = 0.0
		next_deck.play()
	return true


func handle_events(world: World, skip_steps: bool = false) -> int:
	if world == null:
		return 0
	var count := 0
	var moved_sfx := ""
	for ev in world.events:
		var ser := int(ev.get("serial", 0))
		if ser <= _last_event_serial:
			continue
		_last_event_serial = ser
		if not audio_enabled or _paused:
			continue
		var kind := String(ev.get("kind", ""))
		match kind:
			"move":
				if not skip_steps and bool(ev.get("is_player", false)):
					var to: Vector2i = ev.get("to", Vector2i(-1, -1))
					var tile := int(ev.get("tile", world.current_floor().get_tile(to) if world.current_floor() != null else Tiles.FLOOR))
					if tile == Tiles.WATER_SHALLOW:
						moved_sfx = "step_water"
					elif tile == Tiles.IRON_GRATE:
						moved_sfx = "step_grate"
					else:
						moved_sfx = "step_stone"
			"melee_hit":
				var is_player_atk := bool(ev.get("is_player", false))
				var dmg := int(ev.get("amount", 0))
				var from_p: Vector2i = ev.get("from", Vector2i(-1, -1))
				if not is_player_atk and _is_boss_at(world, from_p):
					play_sfx("boss_attack", "Combat")
				elif dmg >= 14 or bool(ev.get("crit", false)):
					play_sfx("melee_crit", "Combat")
				else:
					play_sfx("melee_hit", "Combat")
				count += 1
			"melee_miss":
				play_sfx("melee_miss", "Combat", 0.08)
				count += 1
			"ranged_shot":
				play_sfx("ranged_fire", "Combat")
				count += 1
			"door_open":
				play_sfx("door_open", "Combat", 0.04)
				count += 1
			"trap_trigger":
				play_sfx("trap_trigger", "Combat")
				count += 1
			"relic_work":
				play_sfx("relic_work", "Narrative", 0.02)
				count += 1
			"relic_transmute":
				play_sfx("relic_transmute", "Narrative", 0.02)
				count += 1
			"mask_switch":
				play_sfx("mask_switch", "Narrative", 0.03)
				count += 1
			"subjugation", "entangled":
				play_sfx("chain_strike", "Combat")
				count += 1
			"status_apply":
				var sid := String(ev.get("status", ""))
				if sid in ["mended", "warded", "blessed", "braced"]:
					play_sfx("heal", "Combat", 0.02)
				else:
					play_sfx("spell_cast", "Combat", 0.04)
				count += 1
			"death":
				play_sfx("death", "Narrative", 0.0)
				count += 1
			"victory":
				play_sfx("victory", "Narrative", 0.0)
				count += 1
	if not moved_sfx.is_empty():
		play_sfx(moved_sfx, "Combat", 0.06)
		count += 1
	return count


func _is_boss_at(world: World, p: Vector2i) -> bool:
	var fl := world.current_floor()
	if fl == null:
		return false
	for a in fl.actors:
		if a.pos == p and not a.is_player:
			return a.is_boss or not String(a.elite).is_empty()
	return false
