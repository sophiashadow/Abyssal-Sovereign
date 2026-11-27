extends SceneTree
## M8.10 presentation mode matrix smoke test:
## Verifies glyph mode, tiles mode, reduced motion, high contrast, colorblind
## modes, audio disabled, and VFX/audio event consumption without simulation drift.


func _initialize() -> void:
	var db := ContentDB.load_default()
	var reg := AssetRegistry.new()
	var gs := GameSettings.new()
	var mv := MapView.new()
	mv.registry = reg
	mv.custom_minimum_size = Vector2(800, 600)
	var am := AudioManager.new()
	am.ensure_buses()
	am.ensure_manifest()
	root.add_child(mv)
	root.add_child(am)

	var base_w := World.new_run(db, 909090, "human", "occultist", "ModeBase")
	AutoPlayer.new(base_w).play(40)
	var expected_rng := base_w.rng.get_state_string()

	var modes := [
		{"name": "tiles_std", "rm": "tiles", "hc": false, "cm": 0, "red": false, "aud": true},
		{"name": "glyph_hc", "rm": "glyph", "hc": true, "cm": 0, "red": false, "aud": true},
		{"name": "tiles_deutan_reduced_silent", "rm": "tiles", "hc": false, "cm": 1, "red": true, "aud": false},
		{"name": "glyph_tritan_reduced_silent", "rm": "glyph", "hc": true, "cm": 2, "red": true, "aud": false},
	]
	for m in modes:
		gs.render_mode = m["rm"]
		gs.high_contrast = m["hc"]
		gs.color_mode = m["cm"]
		gs.reduced_motion = m["red"]
		gs.audio_enabled = m["aud"]
		am.apply_settings(gs)
		mv.render_mode = gs.render_mode
		mv.high_contrast = gs.high_contrast
		mv.color_mode = gs.color_mode
		mv.vfx.reduced_motion = gs.reduced_motion
		var w := World.new_run(db, 909090, "human", "occultist", "ModeTest")
		mv.world = w
		mv.vfx.clear()
		am.reset_event_cursor(0)
		AutoPlayer.new(w).play(40)
		mv.pump_events(false)
		am.handle_events(w, false)
		am.set_ambience_sphere(int(w.current_floor_def().get("sphere", 1)))
		am.play_music_context("sphere_moon")
		if w.rng.get_state_string() != expected_rng:
			printerr("M8 mode smoke drift in mode: ", m["name"])
			quit(1)
			return
	print("M8_MODE_SMOKE: %d combinations passed, RNG invariant (%s)" % [modes.size(), expected_rng])
	mv.queue_free()
	am.queue_free()
	quit(0)
