extends SceneTree
## Balance soak: the test bot plays many seeded runs and reports outcomes.
##   godot --headless --path . --script res://tools/soak.gd -- --seeds=20 [--salt=heldout]
## Tune with the default salt, then confirm on a different salt so numbers
## are not fitted to one set of seeds.
## Output is a measurement of the bot, not of human play: the bot knows the
## exit, never retreats and rests only when nothing is in view.


func _init() -> void:
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
				if w.state == World.State.WON:
					wins += 1
					pair_wins[pair] += 1
				elif w.state == World.State.DEAD:
					var key := "d%d %s" % [w.depth, w.death_cause]
					causes[key] = int(causes.get(key, 0)) + 1
				depths[w.depth] = int(depths.get(w.depth, 0)) + 1
	print("runs %d  wins %d (%.0f%%)  mean turns %d" % [runs, wins, 100.0 * wins / runs, turns_sum / runs])
	print("final depth: ", depths)
	print("wins by pair: ", pair_wins)
	var keys := causes.keys()
	keys.sort_custom(func(a, b): return causes[a] > causes[b])
	for k in keys:
		print("  died %-40s %d" % [k, causes[k]])
	quit(0)
