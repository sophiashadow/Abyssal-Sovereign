extends TestCase
## M7.4/M7.6: Relic Work versus Transmutation keeps a real cost on both sides.
## Work is temporary, repeatable and pays +1 Apotheosis each time; Transmute is
## permanent, consumes the relic and pays +2 Apotheosis and a Serpent step.
## Working cannot be farmed for free: Apotheosis 8 freezes experience.


func _world_with(relic: String) -> World:
	var w := TestHelpers.ascii_world(["#####", "#.@.#", "#####"], {}, "human", "fallen_knight")
	w._add_to_inventory(w.player, w._new_item(relic))
	return w


func _relic_index(w: World, relic: String) -> int:
	for i in w.player.inventory.size():
		if w.player.inventory[i].template_id == relic:
			return i
	return -1


func test_work_keeps_the_relic_and_costs_apotheosis() -> void:
	var w := _world_with("ward_keepers_lamp")
	var hp := w.player.hp
	var apo := w.apotheosis
	ok(w.player_work_relic(_relic_index(w, "ward_keepers_lamp")), "worked")
	ok(_relic_index(w, "ward_keepers_lamp") >= 0, "relic kept after Work")
	eq(w.apotheosis, apo + 1, "Work costs +1 Apotheosis")
	ok(w.player.hp < hp, "Work paid blood")
	ok(not w.player_work_relic(_relic_index(w, "ward_keepers_lamp")), "cannot re-Work while its status is active")


func test_transmute_is_permanent_and_dearer() -> void:
	var w := _world_with("ward_keepers_lamp")
	var apo := w.apotheosis
	var serpent := w.way_serpent
	var max_hp := w.player.stat("max_hp")
	ok(w.player_transmute_relic(_relic_index(w, "ward_keepers_lamp")), "transmuted")
	eq(_relic_index(w, "ward_keepers_lamp"), -1, "relic consumed")
	eq(w.apotheosis, apo + 2, "Transmute costs +2 Apotheosis")
	eq(w.way_serpent, serpent + 1, "Transmute steps the Serpent's Way")
	ok(w.player.stat("max_hp") > max_hp, "permanent gain applied")


func test_free_work_is_self_limiting() -> void:
	## almoners_purse costs no HP, the cheapest Work. Repeating it must run into
	## Apotheosis 8, which stops experience, instead of being a free infinite loop.
	var w := _world_with("almoners_purse")
	var worked := 0
	for _i in 40:
		var idx := _relic_index(w, "almoners_purse")
		if w.player_work_relic(idx):
			worked += 1
		else:
			for _t in 9:
				w.player_wait()
		if w.state != World.State.PLAYING:
			break
		if w.apotheosis >= World.APOTHEOSIS_THRESHOLD:
			break
	ok(w.apotheosis >= World.APOTHEOSIS_THRESHOLD, "repeated Work reaches the Apotheosis threshold")
	ok(worked >= 8, "it took repeated, spaced uses")
	var xp := w.player.xp
	w.gain_xp(100)
	eq(w.player.xp, xp, "at the threshold experience no longer accrues")
