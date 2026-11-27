extends SceneTree
## M8.10 performance, memory, and save/render benchmark:
##   ./.tools/godot --headless --path . --script res://tools/m8_perf_bench.gd


func _initialize() -> void:
	var t0 := Time.get_ticks_usec()
	var db := ContentDB.load_default()
	var t_db := (Time.get_ticks_usec() - t0) / 1000.0

	var t1 := Time.get_ticks_usec()
	var reg := AssetRegistry.new()
	for s in range(1, 8):
		reg.get_atlas("sphere_%d_%s" % [s, AudioManager.SPHERE_NAMES[s]])
	for a in ["avatars", "monsters", "npcs", "items", "icons", "emblems"]:
		reg.get_atlas(a)
	var frames := NarrativeFrames.new()
	frames.load_default()
	var t_pres := (Time.get_ticks_usec() - t1) / 1000.0

	var w := World.new_run(db, 810810, "human", "occultist", "Bench")
	var bot := AutoPlayer.new(w)
	var turn_times: Array[float] = []
	for _i in range(200):
		if w.state != World.State.PLAYING:
			break
		var ts := Time.get_ticks_usec()
		bot.step()
		turn_times.append((Time.get_ticks_usec() - ts) / 1000.0)
	turn_times.sort()
	var sum_t := 0.0
	for v in turn_times:
		sum_t += v
	var mean_t := sum_t / maxf(1.0, float(turn_times.size()))
	var p95_idx := clampi(int(floor(float(turn_times.size()) * 0.95)), 0, maxi(0, turn_times.size() - 1))
	var p95_t := turn_times[p95_idx] if not turn_times.is_empty() else 0.0

	# Compare tile vs glyph lookup/prep work over 100 simulated frames
	var fm := w.current_floor()
	var ts_glyph := Time.get_ticks_usec()
	for _f in range(100):
		for y in range(fm.height):
			for x in range(fm.width):
				var _t := fm.get_tile(Vector2i(x, y))
	var ms_glyph := (Time.get_ticks_usec() - ts_glyph) / 1000.0

	var ts_tile := Time.get_ticks_usec()
	var sp := clampi(int(w.current_floor_def().get("sphere", 1)), 1, 7)
	for _f in range(100):
		for y in range(fm.height):
			for x in range(fm.width):
				var tid := fm.get_tile(Vector2i(x, y))
				var _reg: Dictionary = reg.tile_region(sp, tid, 0)
	var ms_tile := (Time.get_ticks_usec() - ts_tile) / 1000.0

	var ts_save := Time.get_ticks_usec()
	var payload := JSON.stringify(w.to_dict())
	var ms_save := (Time.get_ticks_usec() - ts_save) / 1000.0
	var ts_load := Time.get_ticks_usec()
	var parsed: Variant = JSON.parse_string(payload)
	var errs := PackedStringArray()
	var w2 := World.from_dict(db, parsed, errs)
	var ms_load := (Time.get_ticks_usec() - ts_load) / 1000.0

	var mem_cur_mb := OS.get_static_memory_usage() / (1024.0 * 1024.0)
	var mem_peak_mb := OS.get_static_memory_peak_usage() / (1024.0 * 1024.0)

	print("M8_BENCH content_load_ms=%.2f pres_load_ms=%.2f" % [t_db, t_pres])
	print("M8_BENCH turns=%d turn_mean_ms=%.3f turn_p95_ms=%.3f" % [turn_times.size(), mean_t, p95_t])
	print("M8_BENCH prep_100frames_glyph_ms=%.2f prep_100frames_tile_ms=%.2f" % [ms_glyph, ms_tile])
	print("M8_BENCH save_bytes=%d save_ms=%.2f load_ms=%.2f valid_reload=%s" % [payload.length(), ms_save, ms_load, str(w2 != null and w2.turns == w.turns)])
	print("M8_BENCH static_mem_mb=%.2f peak_static_mem_mb=%.2f" % [mem_cur_mb, mem_peak_mb])
	quit(0)
