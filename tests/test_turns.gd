extends TestCase
## Scheduler, movement and waiting.

const ROOM := [
	"##########",
	"#@.......#",
	"#........#",
	"#........#",
	"##########",
]


func test_wait_spends_one_turn() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	ok(w.player_wait(), "wait spends time")
	eq(w.turns, 1, "turn counter")
	eq(w.time, 100, "a normal action costs 100 time at speed 100")


func test_moving_into_a_wall_costs_nothing() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	var start := w.player.pos
	ok(not w.player_move(Vector2i(-1, 0)), "wall blocks")
	ok(not w.player_move(Vector2i(-1, -1)), "corner blocks")
	eq(w.player.pos, start, "did not move")
	eq(w.turns, 0, "no turn spent")


func test_eight_direction_movement() -> void:
	for d in Grid.DIRS_8:
		var w := TestHelpers.ascii_world([
			"#####",
			"#...#",
			"#.@.#",
			"#...#",
			"#####",
		])
		var start := w.player.pos
		ok(w.player_move(d), "can move %s" % str(d))
		eq(w.player.pos, start + d, "moved %s" % str(d))


func test_faster_monsters_act_more_often_and_player_wins_ties() -> void:
	# The rat (speed 130) is walled off so it cannot interfere; a long status
	# on it counts its turns, because statuses tick at the start of each turn.
	var w := TestHelpers.ascii_world([
		"#######",
		"#@...##",
		"######r",
	], {"r": "warren_rat"})
	var rat := TestHelpers.monster(w, "warren_rat")
	rat.awake = true
	w.apply_status(rat, "reckoning") # 40 turns
	eq(rat.scaled_cost(100), 76, "speed 130 makes a 100-cost action take 76")
	for _i in 10:
		w.player_wait()
	# Rat acts at 0, 76, ..., 988 (14 turns) before the player's turn at 1000.
	eq(40 - int(rat.statuses[0]["turns"]), 14, "rat turns in 10 player turns")
	eq(w.time, 1000, "player acts at time 1000")


func test_scheduler_orders_by_time_then_id() -> void:
	var w := TestHelpers.ascii_world([
		"########",
		"#@..####",
		"######ab",
	], {"a": "catalogued_dead", "b": "catalogued_dead"})
	var mons := []
	for a in w.current_floor().actors:
		if not a.is_player:
			a.next_time = 0
			mons.append(a)
	w.player.next_time = 0
	eq(w._next_actor(), w.player, "player (id 1) wins a tie at time 0")
	w.player.next_time = 50
	eq(w._next_actor().id, mini(mons[0].id, mons[1].id), "lower id wins among monsters")


func test_actions_are_ignored_after_death() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	w.apply_damage(w.player, 999, "a test")
	eq(w.state, World.State.DEAD, "dead")
	ok(not w.player_wait(), "cannot wait")
	ok(not w.player_move(Vector2i(1, 0)), "cannot move")
	eq(w.death_cause, "a test", "cause recorded")


func test_natural_regeneration_and_revenant_half_speed() -> void:
	var h := TestHelpers.ascii_world(ROOM, {}, "human")
	var r := TestHelpers.ascii_world(ROOM, {}, "revenant")
	for w in [h, r]:
		w.player.hp = 1
		for _i in 12:
			w.player_wait()
	eq(h.player.hp, 3, "human: +1 every 6 turns")
	eq(r.player.hp, 2, "revenant: +1 every 12 turns")


func test_rest_stops_when_a_hostile_comes_into_view() -> void:
	var w := TestHelpers.ascii_world([
		"###############",
		"#@............#",
		"###############",
	], {})
	w.player.hp = 1
	var n := w.player_rest(500)
	eq(w.player.hp, w.player.stat("max_hp"), "rested to full when alone")
	ok(n > 0 and n < 500, "stopped when whole (%d turns)" % n)
	var w2 := TestHelpers.ascii_world([
		"###############",
		"#@.........g..#",
		"###############",
	], {"g": "ghoul"})
	TestHelpers.monster(w2, "ghoul").awake = true
	w2.player.hp = 1
	ok(w2.player_rest(500) < 10, "interrupted by an approaching ghoul")


func test_death_leaves_health_at_zero() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	w.apply_damage(w.player, 999, "x")
	eq(w.player.hp, 0, "no negative health shown after death")


func test_named_losses_classify_gilded_fluent_and_catalogued() -> void:
	var w1 := TestHelpers.ascii_world(ROOM)
	w1.apply_damage(w1.player, 999, "warren rat")
	eq(w1.named_loss()["id"], "catalogued", "ordinary death is Catalogued")

	var w2 := TestHelpers.ascii_world(ROOM)
	w2.apply_status(w2.player, "reckoning")
	w2.apply_damage(w2.player, 999, "ghoul")
	eq(w2.named_loss()["id"], "gilded", "reckoning death is Gilded")

	var w3 := TestHelpers.ascii_world(ROOM)
	w3.apply_status(w3.player, "false_light")
	w3.apply_damage(w3.player, 999, "ghoul")
	eq(w3.named_loss()["id"], "gilded", "false_light death is Gilded")

	for sid in ["isolation", "perception_fog", "dissolution", "exposure"]:
		var w4 := TestHelpers.ascii_world(ROOM)
		w4.apply_status(w4.player, sid)
		w4.apply_damage(w4.player, 999, "Preliator Sentinel")
		eq(w4.named_loss()["id"], "fluent", "%s death is Fluent" % sid)
