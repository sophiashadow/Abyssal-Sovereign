extends TestCase

const SEEDS_PER_FLOOR := 300


func _signature(m: FloorMap) -> String:
	return Marshalls.raw_to_base64(m.tiles) + JSON.stringify(m.spawns)


func test_generation_is_deterministic() -> void:
	var fd := db().floor_for_depth(1)
	for s in [1, 99, 123456789]:
		eq(_signature(DungeonGen.generate(fd, s)), _signature(DungeonGen.generate(fd, s)), "seed %d repeatable" % s)
	ok(_signature(DungeonGen.generate(fd, 1)) != _signature(DungeonGen.generate(fd, 2)), "different seeds differ")


func test_world_floors_are_deterministic_per_run_seed() -> void:
	var a := World.new_run(db(), 777, "human", "assassin", "A")
	var b := World.new_run(db(), 777, "human", "assassin", "B")
	eq(Marshalls.raw_to_base64(a.current_floor().tiles), Marshalls.raw_to_base64(b.current_floor().tiles), "same run seed, same floor")
	eq(a.player.pos, b.player.pos, "same start")


## Every walkable tile is reachable from the start; the exit is reachable.
func test_connectivity_and_spawns_across_many_seeds() -> void:
	for depth in range(1, db().max_depth() + 1):
		var fd := db().floor_for_depth(depth)
		for s in SEEDS_PER_FLOOR:
			var seed_value := Rng.derive(s, "dungeon-test:%d" % depth)
			var m := DungeonGen.generate(fd, seed_value)
			var problem := _check_floor(m, fd)
			if problem != "":
				fail("depth %d seed %d: %s" % [depth, seed_value, problem])
				return
	ok(true, "all seeds valid")


func _check_floor(m: FloorMap, fd: Dictionary) -> String:
	if m.get_tile(m.up_pos) != Tiles.STAIRS_UP:
		return "start is not on up stairs"
	var dist := Pathing.distance_map(m, m.up_pos)
	for y in m.height:
		for x in m.width:
			var p := Vector2i(x, y)
			if (x == 0 or y == 0 or x == m.width - 1 or y == m.height - 1) and m.get_tile(p) != Tiles.WALL:
				return "border breach at %s" % p
			if m.is_walkable(p) and dist[m.idx(p)] < 0:
				return "unreachable walkable tile %s" % p
	if fd["exit"] == "stairs":
		if m.get_tile(m.down_pos) != Tiles.STAIRS_DOWN or dist[m.idx(m.down_pos)] <= 0:
			return "down stairs missing or unreachable"
	else:
		if m.get_tile(m.exit_pos) != Tiles.DOOR_SEALED:
			return "sealed door missing"
		var reachable_side := false
		for d in Grid.DIRS_8:
			if dist[m.idx(m.exit_pos + d)] >= 0:
				reachable_side = true
		if not reachable_side:
			return "door unreachable"
	var seen := {}
	var guardians := 0
	var monsters := 0
	for s in m.spawns:
		var p: Vector2i = s["pos"]
		if m.get_tile(p) != Tiles.FLOOR:
			return "spawn on non-floor tile %s (%s)" % [p, s["id"]]
		if seen.has(p):
			return "two spawns share %s" % p
		seen[p] = true
		if s["kind"] == "monster":
			monsters += 1
			if s.get("guardian", false):
				guardians += 1
				if Grid.chebyshev(p, m.exit_pos) != 1:
					return "guardian not beside the door"
			elif m.rooms[0].has_point(p):
				return "monster in the starting room at %s" % p
			if not db().has("monsters", s["id"]):
				return "unknown monster %s" % s["id"]
		elif not db().has("items", s["id"]):
			return "unknown item %s" % s["id"]
	if fd["exit"] == "sealed_door" and guardians != 1:
		return "expected one guardian, got %d" % guardians
	if monsters < int(fd["monsters_min"]) / 2:
		return "too few monsters placed (%d)" % monsters
	return ""


func test_player_starts_beside_up_stairs() -> void:
	var w := World.new_run(db(), 777, "human", "assassin", "A")
	var m := w.current_floor()
	ok(w.player.pos != m.up_pos, "player does not hide up stairs at spawn")
	ok(Grid.is_adjacent(w.player.pos, m.up_pos), "player starts beside up stairs")
	ok(m.is_walkable(w.player.pos), "player starts on walkable tile")
