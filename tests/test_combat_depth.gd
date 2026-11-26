extends TestCase
## M5.2 Combat depth: ranged weapons, projectiles, scrolls, damage types,
## resistances/vulnerabilities, status interactions, monster specials, elites, bosses.


func test_damage_types_resistances_and_vulnerabilities() -> void:
	var w := World.new_run(db(), 501, "revenant", "occultist", "Res")
	eq(w.player.resist("cold"), 50, "revenant innate cold resist")
	eq(w.player.resist("radiant"), -25, "revenant radiant vulnerability")
	eq(w.player.resist("fire"), 25, "ash robe fire resist")
	w.player_switch_mask("nyx")
	eq(w.player.resist("void"), 75, "nyx +25% void stacks with revenant +25% and robe +25%")
	eq(w.player.resist("radiant"), -50, "nyx -25% radiant stacks to -50%")
	var phys_mit := Combat.mitigate(10, w.player, "physical")
	var fire_mit := Combat.mitigate(10, w.player, "fire")
	ok(int(fire_mit["damage"]) < 10, "fire resist reduces elemental damage")
	var high_def := Actor.new()
	high_def.db = db()
	high_def.base = {"defense": 20}
	eq(int(Combat.mitigate(10, high_def, "physical")["damage"]), 1, "high armor blocks physical")
	eq(int(Combat.mitigate(10, high_def, "void")["damage"]), 10, "armor defense does not block void")


func test_ranged_weapons_projectiles_and_wall_blocking() -> void:
	var line := Grid.line(Vector2i(1, 1), Vector2i(5, 1))
	eq(line.size(), 4, "Bresenham line length")
	eq(line[3], Vector2i(5, 1), "line ends at target")

	var w := TestHelpers.ascii_world([
		"#########",
		"#@..g...#",
		"#.#c....#",
		"#########",
	], {"g": "ghoul", "c": "false_sun_cultist"}, "human", "assassin")
	var ghoul := TestHelpers.monster(w, "ghoul")
	var cultist := TestHelpers.monster(w, "false_sun_cultist")
	var tr_clear := w.projectile_trace(w.player.pos, ghoul.pos, 5)
	eq(tr_clear["hit_actor"], ghoul, "clear line hits ghoul")
	var tr_wall := w.projectile_trace(w.player.pos, cultist.pos, 8)
	eq(tr_wall["blocked"], true, "wall blocks line of fire to cultist")
	ok(tr_wall["hit_actor"] == null, "no actor hit behind wall")
	ok(not w.player_fire(cultist.pos), "cannot fire through wall")

	w.player.base["accuracy"] = 20
	var ghp := ghoul.hp
	ok(w.player_fire(ghoul.pos), "fired shortbow at ghoul")
	ok(ghoul.hp < ghp, "ranged shot damaged ghoul")

	var flask_idx := w.player.inventory.size()
	w._add_to_inventory(w.player, w._new_item("cinder_flask"))
	ghoul.hp = 20
	ok(w.player_use_at(flask_idx, ghoul.pos), "threw cinder flask")
	ok(ghoul.hp < 20, "cinder flask damaged target")
	ok(ghoul.has_status("burning"), "cinder flask applied burning")

	var knife_idx := -1
	for i in w.player.inventory.size():
		if w.player.inventory[i].template_id == "throwing_knife":
			knife_idx = i
			break
	ok(knife_idx >= 0, "assassin starts with throwing knives")
	ghoul.statuses.clear()
	ghoul.awake = false
	w.player_use_at(knife_idx, ghoul.pos)
	ok(ghoul.has_status("bleeding") or not ghoul.is_alive(), "throwing knife inflicted bleeding or killed")


func test_scrolls_and_tactical_movement() -> void:
	var wk := TestHelpers.ascii_world([
		"#######",
		"#@...g#",
		"#######",
	], {"g": "ghoul"}, "human", "fallen_knight")
	wk.player_learn_talent("shield_brace")
	wk.player.talent_points += 1
	wk.player_learn_talent("vanguard_charge")
	wk.player.base["accuracy"] = 20
	wk.rng = Rng.new(42)
	var g := TestHelpers.monster(wk, "ghoul")
	var ghp := g.hp
	ok(wk.player_use_talent("vanguard_charge", g.pos), "charged ghoul against wall")
	eq(Grid.chebyshev(wk.player.pos, g.pos), 1, "charge moved knight adjacent")
	ok(g.hp <= ghp - 3, "charge + wall slam dealt heavy damage")
	if g.is_alive():
		ok(g.has_status("sundered"), "wall slam inflicted sundered")

	var wo := TestHelpers.ascii_world([
		"#########",
		"#@..g.r.#",
		"#########",
	], {"g": "ghoul", "r": "warren_rat"}, "cambion", "occultist")
	var g2 := TestHelpers.monster(wo, "ghoul")
	var r2 := TestHelpers.monster(wo, "warren_rat")
	var lance_idx := wo.player.inventory.size()
	wo._add_to_inventory(wo.player, wo._new_item("scroll_of_abyssal_lance"))
	var g2hp := g2.hp
	var r2hp := r2.hp
	ok(wo.player_use_at(lance_idx, r2.pos), "cast abyssal lance")
	ok(g2.hp < g2hp and r2.hp < r2hp, "lance pierced both lined foes")

	wo.player_learn_talent("veil_step")
	wo.apply_status(wo.player, "pinned")
	ok(not wo.player_move(Vector2i(1, 0)), "pinned blocks normal walking")
	var blink_to := wo._best_blink_tile(wo.current_floor(), 4)
	ok(blink_to.x >= 0, "found open blink tile")
	ok(wo.player_use_talent("veil_step", blink_to), "veil_step blinks to open tile")
	eq(wo.player.pos, blink_to, "moved to blink target")
	ok(not wo.player.has_status("pinned"), "blink clears pinned")


func test_status_interactions() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@.g..#",
		"#######",
	], {"g": "ghoul"}, "human", "occultist")
	var g := TestHelpers.monster(w, "ghoul")
	g.hp = 40
	w.apply_status(g, "chilled")
	w.apply_status(g, "burning")
	ok(not g.has_status("chilled"), "burning triggers thermal shock removing chilled")
	ok(g.has_status("sundered"), "thermal shock inflicts sundered")
	ok(g.hp == 36, "thermal shock dealt 4 bonus damage")

	w.apply_status(g, "burning")
	w.apply_status(g, "chilled")
	ok(not g.has_status("burning"), "chilled triggers scalding steam removing burning")
	ok(g.has_status("perception_fog"), "scalding steam inflicts perception_fog")
	eq(g.hp, 33, "scalding steam dealt 3 bonus damage")

	w.apply_status(g, "bleeding")
	eq(g.hp, 30, "bleeding on sundered triggers 3 hemorrhage damage")
	w.apply_damage(g, 2, "cauterize test", "fire")
	ok(not g.has_status("bleeding"), "fire damage cauterized bleeding")
	eq(g.hp, 26, "cauterize dealt +2 bonus fire damage")

	w.apply_status(w.player, "false_light")
	var hp_p := w.player.hp
	w.apply_damage(w.player, 2, "void test", "void")
	eq(w.player.hp, hp_p - 5, "void deals +3 bonus damage on false_light")


func test_enemy_specials_elites_and_bosses() -> void:
	var w := World.new_run(db(), 777, "human", "fallen_knight", "Spec")
	w._enter_floor(3, true)
	var m3 := w.current_floor()
	var has_boss := false
	var has_elite := false
	for a in m3.actors:
		if a.template_id == "choir_cantor_prime":
			has_boss = true
		if a.is_elite:
			has_elite = true
	ok(has_boss, "Sphere 3 spawns Choir Cantor Prime mid-boss")
	ok(has_elite, "depth 3 spawns at least one elite monster")

	w._enter_floor(5, true)
	var has_auditor := false
	for a in w.current_floor().actors:
		if a.template_id == "iron_auditor":
			has_auditor = true
	ok(has_auditor, "Sphere 5 spawns Iron Auditor mid-boss")

	var wt := TestHelpers.ascii_world([
		"#########",
		"#@..T...#",
		"#########",
	], {"T": "tithe_inquisitor"}, "human", "fallen_knight")
	var items_before := wt.current_floor().items.size()
	var inq := TestHelpers.monster(wt, "tithe_inquisitor")
	wt._apply_elite(inq, "iron")
	ok(inq.is_elite and inq.name.begins_with("Ironbound"), "elite mutation applied")
	wt._kill_monster(inq)
	ok(wt.current_floor().items.size() > items_before, "killing elite drops floor loot")
