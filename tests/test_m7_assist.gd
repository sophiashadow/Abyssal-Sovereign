extends TestCase
## M7.7 player-agency helpers: safe auto-explore, interruptible rest, floor travel,
## advisory warnings, equipment comparison, pack sort/filter/search, log filter and
## enemy inspection. The point of the automation tests is what it refuses to do.

const LONG := ["######################################", "#@...................................#", "######################################"]


func _world(rows: Array = LONG, monsters: Dictionary = {}, klass: String = "fallen_knight") -> World:
	return TestHelpers.ascii_world(rows, monsters, "human", klass)


func _unexplored_floor(w: World) -> int:
	var m := w.current_floor()
	var n := 0
	for y in m.height:
		for x in m.width:
			if m.is_walkable(Vector2i(x, y)) and not m.is_explored(Vector2i(x, y)):
				n += 1
	return n


func _pack_count(w: World) -> int:
	var n := 0
	for it in w.player.inventory:
		n += it.quantity
	return n


# ---- auto-explore

func test_explore_reveals_the_whole_floor_and_reports_done() -> void:
	var w := _world()
	ok(_unexplored_floor(w) > 0, "starts with unexplored floor")
	var st := Assist.new_state()
	var guard := 0
	var last := {}
	while guard < 200:
		last = Assist.explore_step(w, st)
		if not bool(last["acted"]):
			break
		guard += 1
	ok(bool(last["done"]), "reports done: %s" % String(last["stop"]))
	eq(_unexplored_floor(w), 0, "every floor tile seen")
	ok(w.state == World.State.PLAYING, "still alive")


func test_explore_collects_items_it_passes() -> void:
	var w := _world()
	var it := w._new_item("healing_salve")
	it.pos = Vector2i(30, 1)
	w.current_floor().items.append(it)
	var before := _pack_count(w)
	var st := Assist.new_state()
	Assist.explore_run(w, st, 300)
	ok(_pack_count(w) > before, "picked the item up")
	ok(w.current_floor().items_at(Vector2i(30, 1)).is_empty(), "it left the floor")


func test_explore_stops_for_a_hostile_and_never_attacks() -> void:
	var w := _world(["######################################", "#@..................................g#", "######################################"], {"g": "ghoul"})
	var foe := TestHelpers.monster(w, "ghoul")
	var hp := foe.hp
	var st := Assist.new_state()
	var r := Assist.explore_run(w, st, 300)
	ok(String(r["stop"]).find("in view") >= 0, "stops with the foe in view: %s" % String(r["stop"]))
	eq(foe.hp, hp, "never attacked")
	ok(Grid.chebyshev(w.player.pos, foe.pos) > 1, "never walked into it")
	var before := w.player.pos
	var again := Assist.explore_step(w, st)
	ok(not bool(again["acted"]) and w.player.pos == before, "refuses to continue while it is in view")


func test_explore_refuses_dangerous_statuses_and_low_health() -> void:
	var w := _world()
	w.apply_status(w.player, "bleeding")
	var r := Assist.explore_step(w, Assist.new_state())
	ok(not bool(r["acted"]) and String(r["stop"]).find("bleeding") >= 0, "bleeding stops it")
	var w2 := _world()
	w2.player.hp = 1
	ok(not bool(Assist.explore_step(w2, Assist.new_state())["acted"]), "low health stops it")
	var w3 := _world()
	ok(Assist.stop_reason(w3) == "", "healthy and alone: no reason to stop")


func test_explore_stops_when_hurt_unexpectedly() -> void:
	var w := _world()
	var st := Assist.new_state()
	ok(bool(Assist.explore_step(w, st)["acted"]), "first step")
	w.player.hp -= 2
	var r := Assist.explore_step(w, st)
	ok(not bool(r["acted"]) and String(r["stop"]).find("hurt") >= 0, "damage it did not plan for stops it")


func test_explore_never_steps_on_a_known_hazard() -> void:
	var rows := ["##########", "#@.......#", "##########"]
	var w := _world(rows)
	var m := w.current_floor()
	m.set_tile(Vector2i(4, 1), Tiles.ASH_EMBER)
	for x in 10:
		m.explored[m.idx(Vector2i(x, 1))] = 1
	var st := Assist.new_state()
	var r := Assist.explore_run(w, st, 100)
	ok(w.player.pos.x < 4, "stayed on the near side of the embers (x=%d)" % w.player.pos.x)
	ok(m.get_tile(w.player.pos) != Tiles.ASH_EMBER, "not standing on a hazard")
	ok(r["steps"] >= 0, "terminated")


func test_explore_never_springs_a_revealed_trap_when_there_is_a_way_round() -> void:
	var rows := ["#######", "#@....#", "#.....#", "#######"]
	var w := _world(rows)
	var m := w.current_floor()
	m.features.append({"kind": "trap", "sub": "spike", "x": 3, "y": 1, "revealed": true, "used": false})
	m.features.append({"kind": "trap", "sub": "spike", "x": 3, "y": 2, "revealed": true, "used": false})
	var avoid := Assist.avoid_set(m)
	ok(avoid.has(Vector2i(3, 1)) and avoid.has(Vector2i(3, 2)), "both traps are avoided")
	var st := Assist.new_state()
	Assist.explore_run(w, st, 60)
	ok(not (w.player.pos == Vector2i(3, 1) or w.player.pos == Vector2i(3, 2)), "did not stand on a trap")
	for t in m.features:
		ok(not bool(t.get("used", false)), "trap unsprung")


func test_explore_stops_beside_a_consequential_feature_and_does_not_use_it() -> void:
	var w := _world(LONG)
	var m := w.current_floor()
	m.features.append({"kind": "altar", "sub": "unbinding", "x": 12, "y": 1, "revealed": true, "used": false})
	var st := Assist.new_state()
	var r := Assist.explore_run(w, st, 50)
	ok(String(r["stop"]).find("Decide for yourself") >= 0, "stops and says why: %s" % String(r["stop"]))
	ok(not bool(m.feature_at(Vector2i(12, 1)).get("used", false)), "altar unused")
	ok(Grid.chebyshev(w.player.pos, Vector2i(12, 1)) <= 1, "stopped beside it")
	var r2 := Assist.explore_run(w, st, 50)
	ok(int(r2["steps"]) > 0, "the same feature does not stop it twice")
	ok(not bool(m.feature_at(Vector2i(12, 1)).get("used", false)), "still unused")


func test_explore_does_not_cross_a_sphere_gate() -> void:
	var w := _world(["########", "#@....>#", "########"])
	var st := Assist.new_state()
	Assist.explore_run(w, st, 100)
	eq(w.depth, 1, "never descended")
	eq(w.apotheosis, 0, "no gate cost paid")
	ok(w.current_floor().get_tile(w.player.pos) != Tiles.STAIRS_DOWN, "did not stop on the stairs")


# ---- rest

func test_rest_refuses_to_rest_through_bleeding() -> void:
	var w := _world()
	w.player.hp = w.player.stat("max_hp") - 3
	w.apply_status(w.player, "bleeding")
	var r := Assist.rest(w)
	eq(int(r["turns"]), 0, "does not start")
	ok(String(r["stop"]).find("bleeding") >= 0, "says why: %s" % String(r["stop"]))


func test_rest_runs_to_whole_and_reports_it() -> void:
	var w := _world()
	w.player.hp = w.player.stat("max_hp") - 2
	var r := Assist.rest(w)
	ok(int(r["turns"]) > 0, "rested")
	eq(w.player.hp, w.player.stat("max_hp"), "whole again")
	var r2 := Assist.rest(w)
	ok(String(r2["stop"]).find("whole") >= 0, "then says so")


func test_rest_is_interrupted_by_a_hostile() -> void:
	var w := _world(["#########", "#@......#", "#######g#", "#########"], {"g": "ghoul"})
	w.player.hp = w.player.stat("max_hp") - 2
	var foe := TestHelpers.monster(w, "ghoul")
	foe.awake = true
	var r := Assist.rest(w)
	ok(int(r["turns"]) == 0 or String(r["stop"]) != "", "does not rest blindly with a foe about")


# ---- travel

func _two_floor_world() -> World:
	var w := World.new_run(TestHelpers.content(), 7, "human", "fallen_knight", "Tester")
	var m := w.current_floor()
	w.player.pos = m.down_pos
	w.update_fov()
	ok(w.player_descend_gate("by_name"), "descended to depth 2")
	# Travel stops for foes by design; this fixture tests routing, so empty the floors.
	for fm in w.floors.values():
		for a in (fm as FloorMap).actors.duplicate():
			if not a.is_player:
				(fm as FloorMap).actors.erase(a)
	w.update_fov()
	return w


func test_next_hop_only_over_visited_floors() -> void:
	var w := _two_floor_world()
	var d1 := w.db.spine_floor_id(1)
	var hop := Assist.next_hop(w, d1)
	ok(not hop.is_empty(), "a way up to a visited floor")
	eq(String(hop["kind"]), "up", "via the stairs up")
	eq(Assist.next_hop(w, w.db.spine_floor_id(3)), {}, "no hop to an unvisited floor")
	eq(Assist.next_hop(w, w.floor_id), {}, "none to the floor you are on")
	var names := []
	for d in Assist.travel_destinations(w):
		names.append(String(d["floor_id"]))
	ok(names.has(d1) and not names.has(w.db.spine_floor_id(3)), "destinations list only visited floors")


func test_travel_climbs_and_descends_between_visited_floors() -> void:
	var w := _two_floor_world()
	var d1 := w.db.spine_floor_id(1)
	var d2 := w.floor_id
	var r := Assist.travel_run(w, d1)
	ok(bool(r["done"]), "travel finished: %s" % String(r["stop"]))
	eq(w.floor_id, d1, "back on depth 1")
	var apo := w.apotheosis
	var hp := w.player.hp
	var r2 := Assist.travel_run(w, d2)
	eq(w.floor_id, d2, "and down again (already visited): %s" % String(r2["stop"]))
	eq(w.apotheosis, apo, "re-crossing a visited gate costs no Apotheosis")
	eq(w.player.hp, hp, "or health")


func test_travel_never_opens_a_new_sphere_gate() -> void:
	var w := World.new_run(TestHelpers.content(), 7, "human", "fallen_knight", "Tester")
	var m := w.current_floor()
	w.player.pos = m.down_pos
	var st := Assist.new_state()
	var hp := w.player.hp
	var apo := w.apotheosis
	var r := Assist.travel_step(w, w.db.spine_floor_id(2), st)
	ok(not bool(r["acted"]), "no route to an unvisited floor")
	eq(w.depth, 1, "did not descend")
	eq(w.player.hp, hp, "paid nothing")
	eq(w.apotheosis, apo, "no Apotheosis")


func test_thread_leads_do_not_name_unvisited_floors() -> void:
	var w := World.new_run(TestHelpers.content(), 7, "human", "fallen_knight", "Tester")
	var tid := ""
	for t in w.db.ids("threads"):
		if String(w.db.get_def("threads", t)["goal_kind"]) == "kill_monster":
			tid = t
			break
	ok(tid != "", "a kill thread exists")
	Threads.activate(w.threads_state, tid, 0)
	var leads := Assist.thread_leads(w)
	var found := false
	for l in leads:
		if String(l["thread"]) == tid:
			found = true
			var fid := Assist.goal_floor(w, "kill_monster", String(w.db.get_def("threads", tid)["goal_ref"]))
			if not w.visited_floors.has(fid):
				eq(String(l["floor_name"]), "", "no name for a place not yet seen")
				ok(not bool(l["visited"]), "marked unvisited")
	ok(found, "the active thread is listed")


# ---- warnings

func test_descent_warning_is_advisory_and_data_backed() -> void:
	var w := _world()
	var lines := Assist.descent_warnings(w)
	var found := false
	for l in lines:
		if l.find("level 1") >= 0:
			found = true
	ok(found, "level 1 going to depth 2 is told so")
	eq(Assist.recommended_level(2), 3, "recommended level for depth 2 comes from the M7.3-1 data")
	eq(Assist.recommended_level(5), 0, "no claim where there is no data")
	w.player.level = 3
	for l in Assist.descent_warnings(w):
		ok(l.find("level 3") < 0 and l.find("gentler") < 0, "no level warning from level 3")
	var apo := w.apotheosis
	var hp := w.player.hp
	Assist.descent_warnings(w)
	eq(w.apotheosis, apo, "reading a warning changes nothing")
	eq(w.player.hp, hp, "or health")


# ---- equipment comparison

func test_compare_item_reports_deltas_and_restores_equipment() -> void:
	var w := _world()
	var worn := w.player.equipped("weapon")
	var better := w._new_item("war_axe") if w.db.has("items", "war_axe") else null
	if better == null:
		for iid in w.db.ids("items"):
			if String(w.db.get_def("items", iid)["kind"]) == "weapon" and (worn == null or iid != worn.template_id):
				better = w._new_item(iid)
				break
	better.identified = true
	var def_before := w.player.stat("defense")
	var acc_before := w.player.stat("accuracy")
	var res := Assist.compare_item(w, better)
	eq(String(res["slot"]), "weapon", "compares against the weapon slot")
	ok((res["lines"] as PackedStringArray).size() > 0, "says something")
	eq(w.player.equipped("weapon"), worn, "equipment restored")
	eq(w.player.stat("defense"), def_before, "defense unchanged afterwards")
	eq(w.player.stat("accuracy"), acc_before, "accuracy unchanged afterwards")


func test_compare_item_hides_unidentified_numbers_and_flags_curses() -> void:
	var w := _world()
	var gear: Item = null
	for iid in w.db.ids("items"):
		if String(w.db.get_def("items", iid)["kind"]) == "armor":
			gear = w._new_item(iid)
			break
	gear.identified = false
	var res := Assist.compare_item(w, gear)
	ok(bool(res["unknown"]), "unidentified gear is unknown")
	ok(String((res["lines"] as PackedStringArray)[0]).find("Unidentified") >= 0, "and says so")
	gear.identified = true
	gear.buc = "cursed"
	ok(String(Assist.compare_item(w, gear)["warning"]).find("cursed") >= 0, "a known curse is flagged")


func test_compare_item_ignores_non_equipment() -> void:
	var w := _world()
	var salve := w._new_item("healing_salve")
	eq(String(Assist.compare_item(w, salve)["slot"]), "", "no slot for a consumable")


# ---- pack

func test_inventory_view_sorts_filters_and_searches() -> void:
	var w := _world()
	w.player.inventory.clear()
	for iid in ["healing_salve", "ward_keepers_lamp"]:
		w._add_to_inventory(w.player, w._new_item(iid))
	for iid in w.db.ids("items"):
		var kind := String(w.db.get_def("items", iid)["kind"])
		if kind == "weapon" or kind == "armor":
			w._add_to_inventory(w.player, w._new_item(iid))
			if w.player.inventory.size() >= 5:
				break
	var n := w.player.inventory.size()
	eq(Assist.inventory_view(w).size(), n, "default shows everything")
	eq(Assist.inventory_view(w, "recent")[0], n - 1, "recent: newest first")
	var by_kind := Assist.inventory_view(w, "kind")
	var kinds := []
	for i in by_kind:
		kinds.append(int(Assist.KIND_ORDER.get(String(w.player.inventory[i].def(w.db)["kind"]), 9)))
	var sorted_kinds := kinds.duplicate()
	sorted_kinds.sort()
	eq(kinds, sorted_kinds, "kind sort is monotone")
	var names := []
	for i in Assist.inventory_view(w, "name"):
		names.append(w.item_name(w.player.inventory[i]).to_lower())
	var sorted_names := names.duplicate()
	sorted_names.sort()
	eq(names, sorted_names, "name sort is alphabetical")
	for i in Assist.inventory_view(w, "recent", "consumable"):
		eq(String(w.player.inventory[i].def(w.db)["kind"]), "consumable", "filter keeps one kind")
	var q := Assist.inventory_view(w, "recent", "all", "SALVE")
	ok(q.size() >= 1, "search is case-insensitive")
	eq(Assist.inventory_view(w, "recent", "all", "zzz-no-such").size(), 0, "no match, no rows")


func test_search_matches_the_displayed_name_not_the_hidden_one() -> void:
	var w := _world()
	w.player.inventory.clear()
	var gear: Item = null
	for iid in w.db.ids("items"):
		if String(w.db.get_def("items", iid)["kind"]) == "armor":
			gear = w._new_item(iid)
			break
	gear.identified = false
	gear.rarity = "rare"
	w._add_to_inventory(w.player, gear)
	var real := String(gear.def(w.db)["name"]).to_lower()
	eq(Assist.inventory_view(w, "recent", "all", "glowing").size(), 1, "finds it by what is shown")
	if w.item_name(gear).to_lower().find(real) < 0:
		eq(Assist.inventory_view(w, "recent", "all", real).size(), 0, "does not leak the hidden base name")


# ---- log and inspection

func test_filter_log_by_kind_and_limit() -> void:
	var msgs: Array[Dictionary] = [{"t": "a", "k": "combat"}, {"t": "b", "k": "lore"}, {"t": "c", "k": "combat"}, {"t": "d", "k": "info"}]
	eq(Assist.filter_log(msgs, []).size(), 4, "no filter shows all")
	eq(Assist.filter_log(msgs, ["combat"]).size(), 2, "one kind")
	eq(Assist.filter_log(msgs, ["combat", "lore"]).size(), 3, "two kinds")
	var last := Assist.filter_log(msgs, [], 2)
	eq(String(last[0]["t"]), "c", "limit keeps the newest")


func test_inspect_actor_gives_both_hit_chances() -> void:
	var w := _world(["#######", "#@.g..#", "#######"], {"g": "ghoul"})
	var g := TestHelpers.monster(w, "ghoul")
	var text := Assist.inspect_actor(w, g)
	ok(text.find("You hit") >= 0 and text.find("it hits you") >= 0, "both directions: %s" % text)
	ok(text.find("%d%%" % Combat.hit_chance(w.player, g)) >= 0, "matches the combat formula")
