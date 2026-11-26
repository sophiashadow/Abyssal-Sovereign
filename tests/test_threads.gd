extends TestCase
## M6.6 Threads Beneath the Record:
## 24 organic threads, seeded non-completionist subset per run,
## multi-stage progression, alternative resolution (goal/sacrifice/refusal/abandonment),
## delayed aftermath ticks, non-spoiler state, and save v11 round-trip.


func test_threads_catalog_and_seeded_subset() -> void:
	eq(db().ids("threads").size(), 24, "24 world threads defined")
	var w1 := World.new_run(db(), 6601, "human", "occultist", "T1")
	var w2 := World.new_run(db(), 6601, "human", "occultist", "T2")
	var w3 := World.new_run(db(), 6699, "human", "occultist", "T3")
	var p1: Array = w1.threads_state.get("pool", [])
	var p2: Array = w2.threads_state.get("pool", [])
	var p3: Array = w3.threads_state.get("pool", [])
	eq(p1.size(), 8, "deterministic subset of 8 threads chosen per run")
	eq(JSON.stringify(p1), JSON.stringify(p2), "same seed picks identical thread pool")
	ok(JSON.stringify(p1) != JSON.stringify(p3), "different seed picks varied thread pool")


func test_thread_lifecycle_alternative_resolutions_and_delayed_aftermath() -> void:
	# 1. Floor discovery + goal completion via kill_monster.
	var w := TestHelpers.ascii_world([
		"#########",
		"#@....k.#",
		"#.......#",
		"#########",
	], {"k": "marshal_krell"}, "human", "fallen_knight", 21)
	w.threads_state["pool"] = ["honest_blade_inspection", "hide_from_procession", "unfiled_census_leaf"]
	ok(w.discover_thread("honest_blade_inspection"), "thread discovered organically")
	ok(w.active_thread_ids().has("honest_blade_inspection"), "thread now active")
	var stat_pts_before := w.player.stat_points
	var krell := TestHelpers.monster(w, "marshal_krell")
	w.apply_damage(krell, 9999, "test")
	ok((w.threads_state.get("completed", []) as Array).has("honest_blade_inspection"), "killing goal boss completed thread")
	eq(w.player.stat_points >= stat_pts_before + 1, true, "thread reward granted stat point (alongside level XP)")

	# 2. Alternative sacrifice resolution vs explicit refusal + delayed consequence.
	ok(w.discover_thread("hide_from_procession"), "discovered Tanner's Cold Mark")
	var way_before := w.way_serpent
	ok(w.resolve_thread("hide_from_procession", "sacrifice"), "settled thread by blood sacrifice")
	ok((w.threads_state.get("completed", []) as Array).has("hide_from_procession"), "sacrifice marks thread completed")
	ok(w.way_serpent > way_before, "sacrifice resolution granted Serpent's Way shift")

	ok(w.discover_thread("unfiled_census_leaf"), "discovered Loose Leaf Below the Stair")
	var sub_before := w.subjugation
	ok(w.refuse_thread("unfiled_census_leaf"), "explicit refusal accepted")
	ok((w.threads_state.get("refused", []) as Array).has("unfiled_census_leaf"), "thread recorded in refused")
	ok(not (w.threads_state.get("pending", []) as Array).is_empty(), "delayed refusal consequence queued")
	for _t in 14:
		w.player_wait()
	ok(w.subjugation > sub_before, "delayed refusal consequence fired after delay_turns (%d -> %d)" % [sub_before, w.subjugation])

	# 3. Save v11 round-trip preserves threads_state cleanly.
	var json_str := JSON.stringify(w.to_dict())
	var errors: PackedStringArray = []
	var w_loaded := World.from_dict(db(), JSON.parse_string(json_str), errors)
	eq(errors.size(), 0, "v11 save loads cleanly: %s" % ", ".join(errors))
	ok(w_loaded != null and (w_loaded.threads_state.get("completed", []) as Array).has("honest_blade_inspection"), "completed threads preserved")
	ok((w_loaded.threads_state.get("refused", []) as Array).has("unfiled_census_leaf"), "refused threads preserved")
