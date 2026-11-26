extends TestCase
## Monster awareness, pursuit and attack.

const HALL := [
	"##############",
	"#@..........g#",
	"##############",
]


func test_awake_monster_closes_distance_and_attacks() -> void:
	var w := TestHelpers.ascii_world(HALL, {"g": "ghoul"})
	var g := TestHelpers.monster(w, "ghoul")
	g.awake = true
	var start := Grid.chebyshev(g.pos, w.player.pos)
	var hp := w.player.hp
	for _i in 30:
		w.player_wait()
		if w.state != World.State.PLAYING:
			break
	ok(Grid.chebyshev(g.pos, w.player.pos) < start, "approached")
	eq(Grid.chebyshev(g.pos, w.player.pos), 1, "adjacent")
	ok(w.player.hp < hp or w.state == World.State.DEAD, "attacked")


func test_unaware_unseen_monster_stays_put() -> void:
	var w := TestHelpers.ascii_world([
		"##########",
		"#@.#....g#",
		"##########",
	], {"g": "ghoul"})
	var g := TestHelpers.monster(w, "ghoul")
	var p := g.pos
	for _i in 20:
		w.player_wait()
	eq(g.pos, p, "did not move")
	ok(not g.awake, "still unaware")


func test_visible_monster_eventually_notices() -> void:
	var w := TestHelpers.ascii_world(HALL, {"g": "catalogued_dead"})
	w.current_floor().actors[1].pos = Vector2i(6, 1)
	w.update_fov()
	var m := TestHelpers.monster(w, "catalogued_dead")
	for _i in 30:
		w.player_wait()
		if m.awake:
			break
	ok(m.awake, "noticed within 30 turns")


func test_monsters_never_share_tiles_or_walk_walls() -> void:
	var w := TestHelpers.ascii_world([
		"#########",
		"#@......#",
		"#.......#",
		"#..rrrr.#",
		"#########",
	], {"r": "warren_rat"})
	for a in w.current_floor().actors:
		a.awake = true
	for _i in 40:
		w.player_wait()
		if w.state != World.State.PLAYING:
			break
		var seen := {}
		for a in w.current_floor().actors:
			if not a.is_alive():
				continue
			ok(not seen.has(a.pos), "one actor per tile")
			ok(w.current_floor().is_walkable(a.pos), "on walkable ground")
			seen[a.pos] = true
