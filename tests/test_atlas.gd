extends TestCase
## M6.1 The Atlas of Terra Tenebrae: multi-region 28-floor dungeon architecture,
## deterministic per-run branch selection, bidirectional portals, alternate inter-Sphere
## descent with Sphere Gates, regional terrain rules, and save/resume inside branches.


func test_atlas_has_all_spheres_and_branches() -> void:
	var d := db()
	eq(d.max_depth(), 7, "seven cosmological spheres preserved")
	eq(d.all_floor_ids().size(), 28, "28 total discoverable floors (7 spine + 21 regional)")
	for depth in range(1, 8):
		var spine := d.floor_for_depth(depth)
		ok(not spine.is_empty(), "spine floor exists at depth %d" % depth)
		eq(String(spine.get("region_kind", "spine")), "spine", "depth %d spine is spine" % depth)
		var branches := d.branch_floors_for_depth(depth)
		eq(branches.size(), 3, "depth %d has 3 regional branches" % depth)


func test_atlas_selection_varies_by_seed_and_is_deterministic() -> void:
	var w1 := World.new_run(db(), 101, "human", "fallen_knight", "A1")
	var w2 := World.new_run(db(), 101, "human", "fallen_knight", "A2")
	eq(JSON.stringify(w1.atlas), JSON.stringify(w2.atlas), "same seed builds identical atlas")
	var diff := false
	for s in [202, 303, 404, 505, 606]:
		var w3 := World.new_run(db(), s, "human", "fallen_knight", "A3")
		if JSON.stringify(w3.atlas) != JSON.stringify(w1.atlas):
			diff = true
			break
	ok(diff, "different seeds select different regional branch combinations")


func test_all_28_floors_generate_valid_connected_maps() -> void:
	var d := db()
	for fid in d.all_floor_ids():
		var fd := d.floor_def(fid)
		for i in 5:
			var seed_val := Rng.derive(i, "atlas-check:" + fid)
			var m := DungeonGen.generate(fd, seed_val)
			var dist := Pathing.distance_map(m, m.up_pos)
			for y in m.height:
				for x in m.width:
					var p := Vector2i(x, y)
					if (x == 0 or y == 0 or x == m.width - 1 or y == m.height - 1) and m.get_tile(p) != Tiles.WALL:
						fail("%s seed %d border breach at %s" % [fid, seed_val, p])
						return
					if m.is_walkable(p) and dist[m.idx(p)] < 0:
						fail("%s seed %d unreachable walkable tile %s" % [fid, seed_val, p])
						return
			if String(fd["exit"]) == "stairs":
				ok(m.get_tile(m.down_pos) == Tiles.STAIRS_DOWN and dist[m.idx(m.down_pos)] > 0, "%s down stairs reachable" % fid)
			elif String(fd["exit"]) == "sealed_door":
				ok(m.get_tile(m.exit_pos) == Tiles.DOOR_SEALED, "%s sealed door present" % fid)
			else:
				ok(m.get_tile(m.up_pos) == Tiles.BRANCH_OUT, "%s branch_end has return passage" % fid)
				ok(m.portals.size() >= 1, "%s has return portal" % fid)


func test_branch_portals_alternate_route_and_save_resume() -> void:
	var w := World.new_run(db(), 777, "human", "assassin", "Trav")
	var start_fid := w.floor_id
	var spine_map := w.current_floor()
	var branch_pt := {}
	for pt in spine_map.portals:
		if String(pt.get("kind", "")) == "branch_in":
			branch_pt = pt
			break
	ok(not branch_pt.is_empty(), "starting spine floor has a branch_in portal")
	w.player.pos = Vector2i(int(branch_pt["x"]), int(branch_pt["y"]))
	ok(w.player_stairs(), "entered regional branch via portal")
	var branch_fid := w.floor_id
	ok(branch_fid != start_fid, "moved to branch floor '%s'" % branch_fid)
	ok(w.visited_floors.has(branch_fid), "visited_floors records branch")

	# Save and reload while inside branch, then return to spine.
	var saved_json := JSON.stringify(w.to_dict())
	var parsed: Variant = JSON.parse_string(saved_json)
	var errs: PackedStringArray = []
	var w2 := World.from_dict(db(), parsed, errs)
	eq(errs.size(), 0, "branch save loads with zero errors: %s" % ", ".join(errs))
	ok(w2 != null and w2.floor_id == branch_fid, "reloaded world stays in branch")
	if w2 != null:
		eq(JSON.stringify(w2.to_dict()), saved_json, "branch save round-trip is identical")
		var bmap := w2.current_floor()
		w2.player.pos = bmap.up_pos
		ok(w2.player_stairs(), "crossed return passage back to parent spine")
		eq(w2.floor_id, start_fid, "returned to parent spine floor")

	# Alternate route descent triggers Sphere Gate when entering a deeper Sphere.
	var alt_seed := -1
	for s in 50:
		var tw := World.new_run(db(), s, "human", "fallen_knight", "Alt")
		for k in tw.atlas:
			for p in tw.atlas[k]:
				if String(p.get("kind", "")) == "alt_down":
					alt_seed = s
					break
			if alt_seed >= 0:
				break
		if alt_seed >= 0:
			break
	ok(alt_seed >= 0, "found seed with active alt_down route")
	var wa := World.new_run(db(), alt_seed, "human", "fallen_knight", "Alt")
	var src_fid := ""
	var dst_fid := ""
	for k in wa.atlas:
		for p in wa.atlas[k]:
			if String(p.get("kind", "")) == "alt_down":
				src_fid = String(k)
				dst_fid = String(p["target"])
				break
		if src_fid != "":
			break
	wa._enter_floor_by_id(src_fid, "portal")
	var src_map := wa.current_floor()
	var alt_pt := {}
	for p in src_map.portals:
		if String(p.get("kind", "")) == "alt_down":
			alt_pt = p
			break
	ok(not alt_pt.is_empty(), "alt_down portal placed on %s" % src_fid)
	wa.player.pos = Vector2i(int(alt_pt["x"]), int(alt_pt["y"]))
	ok(wa.needs_gate_to_descend(), "alt_down into deeper unvisited Sphere requires Sphere Gate")
	ok(wa.player_descend_gate("by_name"), "descended via alt_down Sphere Gate")
	eq(wa.floor_id, dst_fid, "arrived at alt_down destination '%s'" % dst_fid)


func test_regional_terrain_rules_water_sanctuary_and_iron_grate() -> void:
	var w := TestHelpers.ascii_world([
		"#########",
		"#@~,:...#",
		"#......r#",
		"#########",
	], {"r": "warren_rat"}, "human", "fallen_knight", 91)
	var m := w.current_floor()
	m.set_tile(Vector2i(2, 1), Tiles.WATER_SHALLOW)
	m.set_tile(Vector2i(3, 1), Tiles.SANCTUARY_FLOOR)
	m.set_tile(Vector2i(4, 1), Tiles.IRON_GRATE)

	# Water extinguishes burning and amplifies cold damage by +25%.
	w.apply_status(w.player, "burning")
	var t0 := w.time
	ok(w.player_move(Vector2i(1, 0)), "stepped into shallow water")
	ok(not w.player.has_status("burning"), "shallow water doused burning")
	ok(w.time - t0 >= World.COST_MOVE + 25, "shallow water imposes +25 movement cost")
	var hp0 := w.player.hp
	w.apply_damage(w.player, 4, "frost", "cold")
	eq(w.player.hp, hp0 - 5, "shallow water amplifies cold damage by +25% (4 -> 5)")

	# Sanctuary flagstones double regen rate and cushion Subjugation gain by 1.
	ok(w.player_move(Vector2i(1, 0)), "stepped onto sanctuary flagstones")
	w.subjugation = 1
	w._chain_hit("debility")
	eq(w.subjugation, 1, "sanctuary flagstones cushion Subjugation gain by 1")
	w.player.hp = w.player.stat("max_hp") - 2
	w.turns = 3
	w._natural_regen()
	eq(w.player.hp, w.player.stat("max_hp") - 1, "sanctuary flagstones halve regen interval (heals on turn 3)")

	# Iron grate wakes unaware monsters within radius 5.
	var rat := TestHelpers.monster(w, "warren_rat")
	rat.awake = false
	ok(w.player_move(Vector2i(1, 0)), "stepped onto iron grate")
	ok(rat.awake, "iron grate clangs and wakes nearby unaware monster")
