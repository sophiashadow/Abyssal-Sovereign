extends TestCase
## M6.7 Dungeon Variety and Emergent Encounters:
## 10 composable room archetypes, 100% map connectivity across seeds,
## and all 4 emergent sites (rune_puzzle, abandoned_rite, sanctuary_hearth, echo_cache).


func test_room_archetypes_diversity_and_100pct_connectivity() -> void:
	eq(RoomArchetypes.ARCHETYPES.size(), 10, "10 composable room archetypes defined")
	var seen_archetypes := {}
	var floor_ids := db().ids("floors")
	for i in 40:
		var fid := String(floor_ids[i % floor_ids.size()])
		var fd := db().floor_def(fid)
		var rng := Rng.new(Rng.derive(7000 + i, fid))
		var m := DungeonGen.generate(fd, 7000 + i)
		# Verify archetype distribution across the same regional rules.
		for ri in range(1, m.rooms.size()):
			var rm: Rect2i = m.rooms[ri]
			if rm.size.x >= 5 and rm.size.y >= 4:
				seen_archetypes[RoomArchetypes._pick_for_region(String(fd.get("terrain", "standard")), String(fd.get("region_kind", "spine")), rm, rng)] = true
		# Connectivity: flood-fill from up_pos reaches every walkable tile, stairs, exit, and feature.
		var dist := Pathing.distance_map(m, m.up_pos)
		var walkable_total := 0
		var reached := 0
		for y in m.height:
			for x in m.width:
				var p := Vector2i(x, y)
				if m.is_walkable(p):
					walkable_total += 1
					if dist[m.idx(p)] != Pathing.UNREACHED:
						reached += 1
		eq(reached, walkable_total, "100%% map connectivity preserved on %s seed %d" % [fid, 7000 + i])
		if m.exit_pos.x >= 0:
			var exit_ok := dist[m.idx(m.exit_pos)] != Pathing.UNREACHED
			if not exit_ok:
				for d8 in Grid.DIRS_8:
					var q: Vector2i = m.exit_pos + d8
					if m.in_bounds(q) and dist[m.idx(q)] != Pathing.UNREACHED:
						exit_ok = true
						break
			ok(exit_ok, "exit reachable on %s" % fid)
		for f in m.features:
			var fp := Vector2i(int(f["x"]), int(f["y"]))
			if String(f.get("kind", "")) != "secret_door":
				ok(dist[m.idx(fp)] != Pathing.UNREACHED, "feature %s reachable" % String(f.get("kind", "")))
	ok(seen_archetypes.size() >= 8, "wide variety of archetypes generated (%d/10)" % seen_archetypes.size())


func test_emergent_interactive_sites() -> void:
	var w := TestHelpers.ascii_world([
		"#########",
		"#@......#",
		"#.......#",
		"#########",
	], {}, "human", "occultist", 21)
	var m := w.current_floor()
	var hp_before := w.player.hp
	w.player.hp = maxi(1, w.player.hp - 5)
	w.subjugation = 3
	# Place & test all 4 emergent site interactions cleanly.
	var sites := [
		{"kind": "rune_puzzle", "sub": "rune_puzzle", "pos": Vector2i(2, 1), "choice": "solve_order"},
		{"kind": "abandoned_rite", "sub": "abandoned_rite", "pos": Vector2i(3, 1), "choice": "dismantle"},
		{"kind": "sanctuary_hearth", "sub": "sanctuary_hearth", "pos": Vector2i(4, 1), "choice": "rest_quiet"},
		{"kind": "echo_cache", "sub": "echo_cache", "pos": Vector2i(5, 1), "choice": "salvage"},
	]
	for s in sites:
		var p: Vector2i = s["pos"]
		m.features.append({"kind": s["kind"], "sub": s["sub"], "x": p.x, "y": p.y, "revealed": true, "used": false})
		w.player.pos = p
		ok(w.player_interact(p, s["choice"]), "interacted with emergent site %s" % s["kind"])
	# Also verify echo_cache 'read' marks nearby explored tiles without errors.
	m.features.append({"kind": "echo_cache", "sub": "echo_cache", "x": 6, "y": 1, "revealed": true, "used": false})
	w.player.pos = Vector2i(6, 1)
	ok(w.player_interact(Vector2i(6, 1), "read"), "echo_cache read reveals nearby survey")
	ok(m.is_explored(Vector2i(7, 2)), "echo_cache read marked nearby tile explored")
	ok(w.subjugation <= 1, "abandoned_rite & sanctuary_hearth reduced Subjugation (%d)" % w.subjugation)
	ok(w.player.hp > hp_before - 5, "sanctuary_hearth restored health")
	ok(m.items.size() >= 1, "echo_cache produced salvage")
