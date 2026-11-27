extends TestCase
## M8.0 foundation tests: Sphere identity & relic telemetry stay pure observers,
## PolicyPlayer works relics and finishes explorer/narrative runs without looping,
## and m7_report aggregates the new telemetry cleanly.

const M7Soak := preload("res://tools/m7_soak.gd")
const M7Report := preload("res://tools/m7_report.gd")


func _fingerprint(w: World) -> String:
	return "%d|%d|%d|%d|%s|%s" % [w.state, w.turns, w.depth, w.player.hp, w.floor_id, w.rng.get_state_string()]


func test_sphere_and_relic_telemetry_are_pure_observers() -> void:
	var a := World.new_run(db(), 4242, "human", "occultist", "T")
	var b := World.new_run(db(), 4242, "human", "occultist", "T")
	b.telemetry = Telemetry.new()
	a._add_to_inventory(a.player, a._new_item("confessors_glass"))
	b._add_to_inventory(b.player, b._new_item("confessors_glass"))
	var bot_a := PolicyPlayer.new(a, "specialist")
	var bot_b := PolicyPlayer.new(b, "specialist")
	bot_a.play(400)
	bot_b.play(400)
	eq(_fingerprint(a), _fingerprint(b), "M8.0 telemetry does not alter simulation state or RNG")
	eq(JSON.stringify(a.to_dict()), JSON.stringify(b.to_dict()), "M8.0 telemetry leaves serialized save identical")
	var td := b.telemetry.to_dict()
	ok(not (td["sphere_turns"] as Dictionary).is_empty(), "sphere_turns recorded")
	ok(not (td["sphere_actions"] as Dictionary).is_empty(), "sphere_actions recorded")


func test_relic_work_and_status_telemetry_recorded() -> void:
	var w := World.new_run(db(), 5151, "cambion", "fallen_knight", "T")
	w.telemetry = Telemetry.new()
	var relic := w._new_item("confessors_glass")
	w._add_to_inventory(w.player, relic)
	var idx := w.player.inventory.find(relic)
	ok(idx >= 0, "relic added to pack")
	ok(w.player_work_relic(idx), "worked relic")
	var td := w.telemetry.to_dict()
	eq(int((td["relic_work"] as Dictionary).get("confessors_glass", 0)), 1, "relic_work counted")
	ok((td["sphere_statuses"] as Dictionary).size() >= 1, "sphere_statuses recorded")
	ok(int((td["sphere_turns"] as Dictionary).get("d1:Moon", 0)) >= 1, "sphere_turns counted under d1:Moon")


func test_policy_player_works_relics_and_finishes_explorer_narrative() -> void:
	var w := World.new_run(db(), 7171, "human", "preliator_warden", "T")
	w.telemetry = Telemetry.new()
	w._add_to_inventory(w.player, w._new_item("broken_halo"))
	# Spawn a nearby hostile so specialist relic-work trigger fires deterministically.
	var foe := w._new_monster("warren_rat", w.player.pos + Vector2i(1, 0))
	if w.current_floor().is_walkable(foe.pos) and w.current_floor().actor_at(foe.pos) == null:
		w.current_floor().actors.append(foe)
		w.update_fov()
	var bot := PolicyPlayer.new(w, "specialist")
	bot.play(30)
	ok(int(w.telemetry.relic_work.get("broken_halo", 0)) >= 1, "specialist worked carried relic near hostile")

	# Previously stalled m8_diag_pre human/occultist runs should terminate well under 20000 actions.
	for pol in ["explorer", "narrative"]:
		var r := M7Soak.run_one(db(), "human", "occultist", pol, 0, "dev", "m8_diag_pre")
		ok(String(r["state"]) != "playing", "%s finished instead of hitting cap (state=%s, turns=%d)" % [pol, r["state"], int(r["turns"])])
		var sm := M7Report.summarize([r], db())
		ok(not ((sm["sphere_identity"] as Dictionary)["turns"] as Dictionary).is_empty(), "%s summary carries sphere_identity" % pol)
