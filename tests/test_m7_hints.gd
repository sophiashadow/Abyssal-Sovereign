extends TestCase
## M7.8 onboarding hints: advice only. They read the world, never change it, and
## each one is offered once.


func _plain(w: World) -> World:
	return TestHelpers.ascii_world(["#######", "#..@..#", "#######"], {}, "human", "fallen_knight")


func test_calling_hint_names_the_signature_tree_and_first_talent() -> void:
	for cl in db().ids("classes"):
		var w := World.new_run(db(), 11, "human", cl, "H")
		for m in w.current_floor().actors.duplicate():
			if not m.is_player:
				w.current_floor().actors.erase(m)
		var h := Hints.next(w, {})
		eq(String(h.get("id", "")), "calling", "%s is offered its calling hint first" % cl)
		var tree := String(db().get_def("classes", cl)["signature_tree"])
		ok(String(h.get("text", "")).contains(tree), "%s hint names %s" % [cl, tree])
		var tname := String(db().get_def("talents", Hints.first_talent(db(), cl))["name"])
		ok(String(h.get("text", "")).contains(tname), "%s hint names %s" % [cl, tname])


func test_hint_is_once_only_and_ends_when_a_talent_is_learned() -> void:
	var w := _plain(null)
	var first := Hints.next(w, {})
	eq(String(first.get("id", "")), "calling", "calling hint due at the start")
	ok(Hints.next(w, {"calling": true}).get("id", "") != "calling", "a seen hint is not repeated")
	var tid := Hints.first_talent(db(), "fallen_knight")
	w.player.talent_points = 1
	ok(w.player_learn_talent(tid), "learned the first talent")
	ok(Hints.next(w, {}).get("id", "") != "calling", "no calling hint once a talent is learned")


func test_hints_never_change_the_world() -> void:
	var w := World.new_run(db(), 4242, "human", "occultist", "Pure")
	var before := JSON.stringify(w.to_dict())
	for _i in 6:
		Hints.next(w, {})
	eq(JSON.stringify(w.to_dict()), before, "state, log and RNG are untouched by asking for hints")


func test_explore_hint_waits_for_calm_and_some_turns() -> void:
	var w := _plain(null)
	var seen := {"calling": true, "elite": true, "unknown_item": true, "rest": true}
	eq(Hints.next(w, seen).size(), 0, "nothing to say on turn zero")
	w.turns = 25
	eq(String(Hints.next(w, seen).get("id", "")), "explore", "explore hint after a little play")
	eq(Hints.next(w, {"calling": true, "elite": true, "unknown_item": true, "rest": true, "explore": true}).size(), 0, "all seen, silent")


func test_no_hint_after_the_run_ends() -> void:
	var w := _plain(null)
	w.state = World.State.DEAD
	eq(Hints.next(w, {}).size(), 0, "silent when the run is over")
