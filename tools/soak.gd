extends SceneTree
## Balance soak: the test bot plays many seeded runs and reports outcomes.
##   godot --headless --path . --script res://tools/soak.gd -- --seeds=20 [--salt=heldout]
## Tune with the default salt, then confirm on a different salt so numbers
## are not fitted to one set of seeds.
## Output is a measurement of the bot, not of human play: the bot knows the
## exit, never retreats, and interacts opportunistically when standing on sites.


func _init() -> void:
	var started_ms := Time.get_ticks_msec()
	var seeds := 20
	var salt := "balance"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--salt="):
			salt = arg.substr(7)
		if arg.begins_with("--seeds="):
			seeds = arg.substr(8).to_int()
	var db := ContentDB.load_default()
	if not db.is_valid():
		print("content invalid: ", db.errors)
		quit(2)
		return
	var causes := {}
	var depths := {}
	var turns_sum := 0
	var runs := 0
	var wins := 0
	var pair_wins := {}
	var species_wins := {}
	var species_runs := {}
	var class_wins := {}
	var class_runs := {}
	var distinct_floors := {}
	var branch_visits := 0
	var npcs_met_sum := 0
	var threads_active_sum := 0
	var threads_settled_sum := 0
	var talents_learned_sum := 0
	for sp in db.ids("species"):
		species_wins[sp] = 0
		species_runs[sp] = 0
	for cl in db.ids("classes"):
		class_wins[cl] = 0
		class_runs[cl] = 0
	for sp in db.ids("species"):
		for cl in db.ids("classes"):
			var pair := "%s/%s" % [sp, cl]
			pair_wins[pair] = 0
			for i in seeds:
				var w := World.new_run(db, Rng.derive(i, salt + ":" + pair), sp, cl, "Soak")
				var bot := AutoPlayer.new(w)
				bot.play(4000)
				runs += 1
				turns_sum += w.turns
				species_runs[sp] = int(species_runs[sp]) + 1
				class_runs[cl] = int(class_runs[cl]) + 1
				for fid in w.visited_floors:
					distinct_floors[fid] = true
					if String(db.floor_def(fid).get("region_kind", "spine")) != "spine":
						branch_visits += 1
				npcs_met_sum += w.npcs_met.size()
				threads_settled_sum += w.resolved_thread_count()
				threads_active_sum += w.active_thread_ids().size() + w.resolved_thread_count() + (w.threads_state.get("refused", []) as Array).size()
				talents_learned_sum += w.player.talents.size()
				if w.state == World.State.WON:
					wins += 1
					pair_wins[pair] += 1
					species_wins[sp] = int(species_wins[sp]) + 1
					class_wins[cl] = int(class_wins[cl]) + 1
				elif w.state == World.State.DEAD:
					var key := "d%d %s" % [w.depth, w.death_cause]
					causes[key] = int(causes.get(key, 0)) + 1
				depths[w.depth] = int(depths.get(w.depth, 0)) + 1
	var elapsed_s := float(Time.get_ticks_msec() - started_ms) / 1000.0
	print("runs %d  wins %d (%.0f%%)  mean turns %d  elapsed %.1fs" % [runs, wins, 100.0 * wins / runs, turns_sum / runs, elapsed_s])
	print("telemetry: distinct_floors=%d/%d  branch_visits=%d  avg_npcs=%.2f  avg_threads_seen=%.2f  avg_threads_settled=%.2f  avg_talents=%.2f" % [
		distinct_floors.size(), db.ids("floors").size(), branch_visits,
		float(npcs_met_sum) / runs, float(threads_active_sum) / runs,
		float(threads_settled_sum) / runs, float(talents_learned_sum) / runs,
	])
	var sp_summary: PackedStringArray = []
	for sp in db.ids("species"):
		sp_summary.append("%s %d/%d" % [sp, species_wins[sp], species_runs[sp]])
	print("wins by origin: ", ", ".join(sp_summary))
	var cl_summary: PackedStringArray = []
	for cl in db.ids("classes"):
		cl_summary.append("%s %d/%d" % [cl, class_wins[cl], class_runs[cl]])
	print("wins by calling: ", ", ".join(cl_summary))
	print("final depth: ", depths)
	print("wins by pair: ", pair_wins)
	var keys := causes.keys()
	keys.sort_custom(func(a, b): return causes[a] > causes[b])
	for k in keys:
		print("  died %-40s %d" % [k, causes[k]])
	quit(0)
