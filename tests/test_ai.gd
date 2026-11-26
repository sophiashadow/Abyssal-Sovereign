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


func test_awake_monster_pursues_last_known_position_then_loses_sight() -> void:
	var w := TestHelpers.ascii_world([
		"###########",
		"#@......g.#",
		"#.#########",
		"#.#.......#",
		"#.........#",
		"###########",
	], {"g": "ghoul"})
	var g := TestHelpers.monster(w, "ghoul")
	w.update_fov()
	g.awake = true
	# Let the ghoul see the player at (1, 1) on its first turn, then duck around the corner out of sight.
	w.player_wait()
	w.player_move(Vector2i(0, 1))
	w.player_move(Vector2i(0, 1))
	w.player_move(Vector2i(0, 1))
	w.player_move(Vector2i(1, 0))
	w.player_move(Vector2i(1, 0))
	w.player_move(Vector2i(1, 0))
	var hidden_pos := w.player.pos
	for _i in 20:
		w.player_wait()
	ok(not g.awake, "monster loses pursuit after checking last known position")
	ok(g.pos.y <= 2, "monster stopped at last known area instead of rounding the corner (%s)" % str(g.pos))
	ok(Grid.chebyshev(g.pos, hidden_pos) > 1, "did not omnisciently round the corner")


func test_sentinel_chain_fog_reduces_player_sight() -> void:
	var w := TestHelpers.ascii_world([
		"#########",
		"#@..P...#",
		"#########",
	], {"P": "preliator_sentinel"})
	var s := TestHelpers.monster(w, "preliator_sentinel")
	w.update_fov()
	s.awake = true
	var base_sight := w.player.stat("sight")
	for _i in 20:
		w.player_wait()
		if w.player.has_status("perception_fog") or w.state != World.State.PLAYING:
			break
	ok(w.player.has_status("perception_fog"), "sentinel inflicted perception_fog")
	ok(w.player.stat("sight") < base_sight, "perception_fog shrinks sight")


func test_isolation_suppresses_soul_siphon_and_rest() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@r...#",
		"#######",
	], {"r": "warren_rat"}, "human", "occultist")
	w.player.hp = 5
	w.apply_status(w.player, "isolation")
	ok(not w.can_rest(), "cannot rest while isolated")
	var rat := TestHelpers.monster(w, "warren_rat")
	w.apply_damage(rat, 99, "test")
	eq(w.player.hp, 5, "soul_siphon suppressed by isolation")
