extends TestCase
## M8.7 + M8.8 audio subsystem tests:
## - 6 AudioServer buses present and wired.
## - All 24 SFX, 7 Sphere ambience loops, and 16 liturgical soundtrack stems exist
##   and carry provenance metadata with honest provisional/placeholder status.
## - AudioManager degrades gracefully when disabled or missing tracks, and never
##   affects simulation RNG or determinism.


func test_audio_buses_and_manifest_coverage() -> void:
	var am := AudioManager.new()
	am.ensure_buses()
	am.ensure_manifest()
	for bus in AudioManager.BUSES:
		ok(AudioServer.get_bus_index(bus) >= 0, "bus %s present" % bus)

	var contexts := am.manifest_contexts()
	eq(contexts.size(), 16, "all 16 liturgical soundtrack contexts documented")
	var expected := [
		"main_title", "character_creation",
		"sphere_moon", "sphere_mercury", "sphere_venus", "sphere_sun", "sphere_mars", "sphere_jupiter", "sphere_saturn",
		"sanctuaries", "boss_encounters",
		"ending_serpents_way", "ending_way_of_return", "ending_unwritten_door", "ending_apotheosis", "death_named_losses",
	]
	for cid in expected:
		ok(contexts.has(cid), "manifest has context %s" % cid)
		var entry: Dictionary = contexts[cid]
		eq(String(entry.get("status", "")), "placeholder_liturgical_temp", "%s marked placeholder_liturgical_temp" % cid)
		var abs_track := ProjectSettings.globalize_path(String(entry.get("track_path", "")))
		ok(FileAccess.file_exists(abs_track), "track file exists for %s" % cid)
	am.free()


func test_audio_provenance_complete_and_valid() -> void:
	var prov: Variant = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://content/presentation/asset_provenance.json")))
	ok(prov is Dictionary and prov.has("entries"), "provenance parses cleanly")
	var by_id := {}
	for e in prov["entries"]:
		by_id[String(e.get("asset_id", ""))] = e

	var sfx_ids := [
		"step_stone", "step_water", "step_grate", "melee_hit", "melee_crit", "melee_miss",
		"ranged_fire", "spell_cast", "heal", "door_open", "trap_trigger", "chain_strike",
		"seal_break", "discovery", "identify", "relic_work", "relic_transmute", "mask_switch",
		"contract_sign", "boss_attack", "ui_click", "ui_confirm", "death", "victory",
	]
	for s in sfx_ids:
		ok(by_id.has("sfx_" + s), "provenance covers sfx_%s" % s)
		ok(FileAccess.file_exists(ProjectSettings.globalize_path("res://assets/audio/sfx/%s.ogg" % s)), "sfx %s exists" % s)

	for i in range(1, 8):
		var sid := AudioManager.SPHERE_NAMES[i]
		ok(by_id.has("ambience_" + sid), "provenance covers ambience_%s" % sid)
		ok(FileAccess.file_exists(ProjectSettings.globalize_path("res://assets/audio/ambience/sphere_%d_%s.ogg" % [i, sid])), "ambience %s exists" % sid)

	for e in by_id.values():
		ok(not String(e.get("license_status", "")).is_empty(), "license_status set on %s" % String(e.get("asset_id", "")))
		ok(String(e.get("approval_status", "")) in ["provisional_m8_asset", "placeholder_liturgical_temp", "approved"],
			"honest approval status on %s" % String(e.get("asset_id", "")))


func test_audio_graceful_degradation_and_determinism() -> void:
	var a := World.new_run(db(), 7171, "human", "occultist", "AudA")
	var b := World.new_run(db(), 7171, "human", "occultist", "AudB")
	var am := AudioManager.new()
	am.ensure_buses()
	am.ensure_manifest()
	var gs := GameSettings.new()
	gs.audio_enabled = false
	am.apply_settings(gs)

	ok(not am.play_sfx("melee_hit"), "play_sfx silent when disabled")
	ok(not am.play_sfx("nonexistent_sfx_id"), "missing sfx degrades safely")
	ok(not am.set_ambience_sphere(99), "invalid sphere degrades safely")
	ok(not am.play_music_context("nonexistent_context"), "missing context degrades safely")

	AutoPlayer.new(a).play(60)
	AutoPlayer.new(b).play(60)
	am.handle_events(a, false)
	eq(a.rng.get_state_string(), b.rng.get_state_string(), "audio never affects sim RNG")
	am.free()
