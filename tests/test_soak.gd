extends TestCase
## Seeded randomized soak: the bot plays whole runs for every species/class
## pair, checking invariants after every action. A failure names the seed,
## so it can be replayed exactly:  World.new_run(db, <seed>, <species>, <class>, "Soak").

const SEEDS_PER_PAIR := 2
const MAX_ACTIONS := 3000


func _invariant_problem(w: World) -> String:
	var m := w.current_floor()
	var p := w.player
	if p.hp > p.stat("max_hp"):
		return "player health %d above max %d" % [p.hp, p.stat("max_hp")]
	if w.state == World.State.PLAYING and p.hp <= 0:
		return "player alive with %d health" % p.hp
	if not m.is_walkable(p.pos):
		return "player on unwalkable tile %s" % str(p.pos)
	if p.inventory.size() > Actor.INVENTORY_LIMIT:
		return "pack over capacity"
	var seen := {}
	for a in m.actors:
		if not a.is_alive():
			if a.is_player and w.state == World.State.DEAD:
				continue
			return "dead %s left on the floor" % a.name
		if seen.has(a.pos):
			return "two actors on %s" % str(a.pos)
		if not m.is_walkable(a.pos):
			return "%s inside terrain at %s" % [a.name, str(a.pos)]
		if a.next_time < w.time and not a.is_player:
			return "%s scheduled in the past" % a.name
		seen[a.pos] = true
	return ""


func test_soak_runs_keep_invariants() -> void:
	var stats := {"won": 0, "dead": 0, "timeout": 0, "depth_sum": 0, "runs": 0}
	var by_pair := {}
	var species_ids := db().ids("species")
	var class_ids := db().ids("classes")
	var pairs: Array[Array] = []
	for si in species_ids.size():
		for offset in 3:
			var ci := (si + offset) % class_ids.size()
			pairs.append([species_ids[si], class_ids[ci]])
	for pr in pairs:
		var sp := String(pr[0])
		var cl := String(pr[1])
		var pair := "%s/%s" % [sp, cl]
		by_pair[pair] = [0, 0]
		for i in SEEDS_PER_PAIR:
			var seed_value := Rng.derive(i, "soak:" + pair)
			var w := World.new_run(db(), seed_value, sp, cl, "Soak")
			var bot := AutoPlayer.new(w)
			for _a in MAX_ACTIONS:
				if not bot.step():
					if w.state != World.State.PLAYING:
						break
					w.player_wait()
				var problem := _invariant_problem(w)
				if problem != "":
					fail("seed %d %s after %d turns: %s" % [seed_value, pair, w.turns, problem])
					return
			stats["runs"] += 1
			stats["depth_sum"] += w.depth
			match w.state:
				World.State.WON:
					stats["won"] += 1
					by_pair[pair][0] += 1
				World.State.DEAD:
					stats["dead"] += 1
				_:
					stats["timeout"] += 1
			by_pair[pair][1] += 1
	ok(stats["runs"] == pairs.size() * SEEDS_PER_PAIR, "all runs completed across all %d origins & %d callings" % [species_ids.size(), class_ids.size()])
	print("     soak: %d runs, %d won, %d died, %d timed out, mean final depth %.2f" % [
		stats["runs"], stats["won"], stats["dead"], stats["timeout"], float(stats["depth_sum"]) / stats["runs"]])
	var parts: PackedStringArray = []
	for pair in by_pair:
		parts.append("%s %d/%d" % [pair, by_pair[pair][0], by_pair[pair][1]])
	print("     wins: " + ", ".join(parts))
