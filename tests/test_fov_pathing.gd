extends TestCase


func test_fov_open_room_and_walls() -> void:
	var w := TestHelpers.ascii_world([
		"###########",
		"#.........#",
		"#....@....#",
		"#.........#",
		"#####.#####",
		"#.........#",
		"###########",
	])
	var m := w.current_floor()
	ok(m.is_visible(Vector2i(1, 1)), "room corner visible")
	ok(m.is_visible(Vector2i(9, 3)), "far room corner visible")
	ok(m.is_visible(Vector2i(0, 0)), "bounding wall visible")
	ok(not m.is_visible(Vector2i(1, 5)), "room behind wall not visible")
	ok(m.is_visible(Vector2i(5, 5)), "straight through the gap is visible")
	ok(m.is_explored(Vector2i(1, 1)), "seen tiles become explored")


func test_fov_radius_and_memory() -> void:
	var rows := ["#".repeat(30)]
	rows.append("#" + "@" + ".".repeat(27) + "#")
	rows.append("#".repeat(30))
	var w := TestHelpers.ascii_world(rows)
	var m := w.current_floor()
	var sight := w.player.stat("sight")
	ok(m.is_visible(Vector2i(1 + sight, 1)), "tile at sight radius visible")
	ok(not m.is_visible(Vector2i(2 + sight, 1)), "tile past sight radius not visible")
	w.player_move(Vector2i(1, 0))
	w.player_move(Vector2i(1, 0))
	ok(m.is_explored(Vector2i(1, 1)) and m.is_visible(Vector2i(1, 1)), "start still visible")
	ok(m.is_explored(Vector2i(4 + sight - 1, 1)), "newly seen tile explored")


func test_distance_map_and_paths() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@..#.#",
		"#.#.#.#",
		"#.#...#",
		"#######",
	])
	var m := w.current_floor()
	var path := Pathing.path_to(m, Vector2i(1, 1), Vector2i(5, 1), false)
	ok(not path.is_empty(), "path found around wall")
	eq(path[path.size() - 1], Vector2i(5, 1), "path ends at goal")
	var cur := Vector2i(1, 1)
	for p in path:
		ok(m.can_step(cur, p), "each step legal %s->%s" % [cur, p])
		cur = p
	var dist := Pathing.distance_map(m, Vector2i(1, 1))
	eq(dist[m.idx(Vector2i(0, 0))], -1, "walls unreachable")
	eq(dist[m.idx(Vector2i(3, 1))], 2, "two steps along row")


func test_no_diagonal_squeeze_between_walls() -> void:
	var w := TestHelpers.ascii_world([
		"####",
		"#@##",
		"##.#",
		"####",
	])
	var m := w.current_floor()
	ok(not m.can_step(Vector2i(1, 1), Vector2i(2, 2)), "squeeze blocked")
	ok(Pathing.path_to(m, Vector2i(1, 1), Vector2i(2, 2), false).is_empty(), "no path through a squeeze")
	var t0 := w.time
	ok(not w.player_move(Vector2i(1, 1)), "player cannot squeeze")
	eq(w.time, t0, "blocked move spends no time")


func test_travel_path_uses_only_explored_tiles() -> void:
	var w := TestHelpers.ascii_world([
		"##########",
		"#@.......#",
		"##########",
	])
	var m := w.current_floor()
	m.explored.fill(0)
	m.explored[m.idx(Vector2i(1, 1))] = 1
	m.explored[m.idx(Vector2i(2, 1))] = 1
	ok(Pathing.path_to(m, Vector2i(1, 1), Vector2i(5, 1), true).is_empty(), "no route through unexplored")
	eq(Pathing.path_to(m, Vector2i(1, 1), Vector2i(2, 1), true).size(), 1, "route through explored")
