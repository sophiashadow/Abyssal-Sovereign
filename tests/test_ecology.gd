extends TestCase
## M5.4 Dungeon ecology: traps, secret doors, hazards, altars, shrines,
## ritual circles, locked vaults, wandering brokers, challenge monoliths, and Sphere profiles.


func test_traps_secret_doors_and_search() -> void:
	var w := TestHelpers.ascii_world([
		"#########",
		"#@......#",
		"###.#...#",
		"#########",
	], {}, "human", "fallen_knight")
	var m := w.current_floor()
	m.features.append({"kind": "trap", "sub": "spike", "x": 3, "y": 1, "revealed": false, "used": false})
	m.features.append({"kind": "secret_door", "sub": "cache", "x": 3, "y": 2, "revealed": false, "used": false})
	var hp_before := w.player.hp
	w.player_move(Vector2i(1, 0))
	w.player_move(Vector2i(1, 0))
	var f_trap := m.feature_at(Vector2i(3, 1))
	ok(bool(f_trap["revealed"]), "stepping onto hidden trap reveals it")
	ok(bool(f_trap["used"]), "trap fires once")
	ok(w.player.hp < hp_before or w.player.has_status("bleeding"), "spike trap harms or bleeds")

	m.features.append({"kind": "trap", "sub": "rime", "x": 4, "y": 1, "revealed": false, "used": false})
	var xp0 := w.player.xp
	ok(w.player_search(), "searched area")
	ok(bool(m.feature_at(Vector2i(4, 1))["revealed"]), "search reveals trap within radius 3")
	ok(bool(m.feature_at(Vector2i(4, 1))["used"]), "search disarms adjacent trap")
	eq(w.player.xp, xp0 + 5, "disarm awards 5 XP")
	ok(bool(m.feature_at(Vector2i(3, 2))["revealed"]), "search reveals secret door")

	var items0 := m.items.size()
	ok(w.player_interact(Vector2i(3, 2), "open"), "opened revealed secret door")
	eq(m.get_tile(Vector2i(3, 2)), Tiles.FLOOR, "secret door became walkable floor")
	ok(m.items.size() > items0, "secret door revealed loot")


func test_environmental_hazards_and_status_combos() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "human", "occultist")
	var m := w.current_floor()
	m.set_tile(Vector2i(2, 1), Tiles.ASH_EMBER)
	m.set_tile(Vector2i(3, 1), Tiles.RIME_ICE)
	m.set_tile(Vector2i(4, 1), Tiles.MIASMA)
	m.set_tile(Vector2i(5, 1), Tiles.SOLAR_GLARE)

	w.apply_status(w.player, "chilled")
	var hp0 := w.player.hp
	ok(w.player_move(Vector2i(1, 0)), "stepped onto embers")
	ok(not w.player.has_status("chilled"), "embers triggered Thermal Shock removing chilled")
	ok(w.player.has_status("sundered"), "Thermal Shock inflicted sundered")
	ok(w.player.hp <= hp0 - 4, "embers + thermal shock dealt damage")

	w.apply_status(w.player, "burning")
	ok(w.player_move(Vector2i(1, 0)), "stepped onto ossuary rime")
	ok(not w.player.has_status("burning"), "rime triggered Scalding Steam removing burning")
	ok(w.player.has_status("perception_fog"), "Scalding Steam inflicted fog")

	var hp2 := w.player.hp
	ok(w.player_move(Vector2i(1, 0)), "stepped onto miasma")
	ok(w.player.hp < hp2, "miasma dealt void damage")

	var hp3 := w.player.hp
	ok(w.player_move(Vector2i(1, 0)), "stepped onto false-sun glare")
	ok(w.player.hp < hp3, "glare dealt radiant damage")


func test_altars_shrines_and_ritual_circles() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "human", "fallen_knight")
	var m := w.current_floor()
	var curse_item := w._new_item("rusted_blade")
	curse_item.buc = "cursed"
	curse_item.identified = true
	w._add_to_inventory(w.player, curse_item)
	w.player_use(w.player.inventory.size() - 1)
	m.features.append({"kind": "altar", "sub": "unbinding", "x": 2, "y": 1, "revealed": true, "used": false})
	w.apotheosis = 3
	ok(w.player_interact(Vector2i(2, 1), "cleanse"), "used altar to cleanse")
	eq(curse_item.buc, "uncursed", "altar lifted weapon curse")
	eq(w.apotheosis, 2, "altar reduced apotheosis")

	m.features.append({"kind": "shrine", "sub": "eye", "x": 3, "y": 1, "revealed": true, "used": false})
	m.features.append({"kind": "trap", "sub": "cinder", "x": 5, "y": 1, "revealed": false, "used": false})
	var potion := w._new_item("bone_tincture")
	w._add_to_inventory(w.player, potion)
	w.player.pos = Vector2i(3, 1)
	ok(w.player_interact(Vector2i(3, 1), "witness"), "used Shrine of Eye")
	ok(bool(m.feature_at(Vector2i(5, 1))["revealed"]), "shrine revealed traps across floor")
	ok(bool(w.id_known.get("bone_tincture", false)), "shrine identified pack items")

	m.features.append({"kind": "ritual_circle", "sub": "geometry", "x": 4, "y": 1, "revealed": true, "used": false})
	w.player.hp = w.player.stat("max_hp")
	var aff_before := w.player.equipped("weapon").affixes.size()
	ok(w.player_interact(Vector2i(4, 1), "inscribe"), "inscribed affix at ritual circle")
	eq(w.player.equipped("weapon").affixes.size(), aff_before + 1, "weapon gained an affix")


func test_locked_vaults_and_ophite_key_synergy() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "human", "assassin")
	var m := w.current_floor()
	m.features.append({"kind": "vault_gate", "sub": "locked_vault", "x": 2, "y": 1, "revealed": true, "used": false})
	ok(not w.player_interact(Vector2i(2, 1), "key"), "locked vault requires key")
	var oph := w._new_item("ophite_key")
	w._add_to_inventory(w.player, oph)
	ok(w.player_interact(Vector2i(2, 1), "key"), "Ophite Key unlocks vault")
	ok(w.player.inventory.has(oph), "Ophite Key is not consumed")
	eq(m.items_at(Vector2i(2, 1)).size(), 2, "vault dropped 2 items")


func test_merchant_and_challenge_monolith() -> void:
	var w := TestHelpers.ascii_world([
		"#########",
		"#@......#",
		"#.......#",
		"#########",
	], {}, "human", "occultist")
	var m := w.current_floor()
	m.features.append({
		"kind": "merchant", "sub": "broker", "x": 2, "y": 1, "revealed": true, "used": false,
		"stock": [{"id": "bone_tincture", "price_hp": 4, "sold": false}],
	})
	var hp0 := w.player.hp
	ok(w.player_interact(Vector2i(2, 1), "buy:0:blood"), "bought item with blood")
	eq(w.player.hp, hp0 - 4, "paid blood price")
	ok(bool(w.id_known.get("bone_tincture", false)), "purchased consumable identified")

	m.features.append({"kind": "challenge", "sub": "trial_bell", "x": 4, "y": 1, "revealed": true, "used": false})
	var sp0 := w.player.stat_points
	var actors0 := m.actors.size()
	var items0 := m.items.size()
	w.player.pos = Vector2i(3, 1)
	ok(w.player_interact(Vector2i(4, 1), "ring"), "rang Trial Bell")
	eq(w.player.stat_points, sp0 + 1, "monolith granted +1 attribute point")
	ok(m.actors.size() > actors0, "monolith spawned ambush")
	ok(m.items.size() > items0, "monolith dropped reward")


func test_seven_spheres_have_distinct_ecology() -> void:
	for depth in range(1, 8):
		var fd := db().floor_for_depth(depth)
		var m := DungeonGen.generate(fd, Rng.derive(555, "eco:%d" % depth))
		ok(not m.features.is_empty(), "depth %d has ecology features" % depth)
		var expected_haz := int(Ecology.SPHERE_PROFILES[depth]["hazard"])
		var has_haz := false
		for y in m.height:
			for x in m.width:
				if m.get_tile(Vector2i(x, y)) == expected_haz:
					has_haz = true
					break
			if has_haz:
				break
		ok(has_haz, "depth %d placed signature Sphere hazard" % depth)
