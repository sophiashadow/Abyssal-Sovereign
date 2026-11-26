extends TestCase
## Pickup, drop, stacking, capacity, equipment and consumables.

const ROOM := [
	"#######",
	"#@....#",
	"#.....#",
	"#######",
]


func _place(w: World, template_id: String, p: Vector2i) -> Item:
	var it := w._new_item(template_id)
	it.pos = p
	w.current_floor().items.append(it)
	return it


func _count(w: World, template_id: String) -> int:
	var n := 0
	for it in w.player.inventory:
		if it.template_id == template_id:
			n += it.quantity
	return n


func test_pickup_and_drop() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	_place(w, "rusted_blade", w.player.pos)
	var before := w.player.inventory.size()
	ok(w.player_pickup(), "picked up")
	eq(w.player.inventory.size(), before + 1, "in the pack")
	ok(w.current_floor().items_at(w.player.pos).is_empty(), "gone from the floor")
	ok(w.player_drop(w.player.inventory.size() - 1), "dropped")
	eq(w.current_floor().items_at(w.player.pos).size(), 1, "back on the floor")
	ok(not TestHelpers.ascii_world(ROOM).player_pickup(), "nothing to take costs no turn")


func test_stackables_share_a_slot() -> void:
	var w := TestHelpers.ascii_world(ROOM) # knights start with one salve
	var slots := w.player.inventory.size()
	_place(w, "healing_salve", w.player.pos)
	w.player_pickup()
	eq(w.player.inventory.size(), slots, "no new slot")
	eq(_count(w, "healing_salve"), 2, "quantity 2")


func test_pack_capacity() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	while w.player.inventory.size() < Actor.INVENTORY_LIMIT:
		w._add_to_inventory(w.player, w._new_item("rusted_blade"))
	_place(w, "stiletto", w.player.pos)
	ok(not w.player_pickup(), "full pack refuses a new item")
	eq(w.turns, 0, "refusal costs no turn")
	_place(w, "healing_salve", w.player.pos)
	w.current_floor().items.reverse() # salve first
	ok(w.player_pickup(), "a stack that fits is still accepted")


func test_equip_swaps_and_unequip() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	var old := w.player.equipped("weapon")
	w._add_to_inventory(w.player, w._new_item("crux_gladii"))
	var idx := w.player.inventory.size() - 1
	ok(w.player_use(idx), "equip")
	eq(w.player.equipped("weapon").template_id, "crux_gladii", "now wielded")
	eq(w.player.damage_dice(), "2d6", "weapon dice used")
	ok(w.player.inventory.has(old), "old weapon returned to the pack")
	ok(w.player_unequip("weapon"), "unequip")
	eq(w.player.equipped("weapon"), null, "empty hand")
	eq(w.player.damage_dice(), "1d2", "unarmed")


func test_equipment_mods_apply() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	var sight := w.player.stat("sight")
	var acc := w.player.stat("accuracy")
	w._add_to_inventory(w.player, w._new_item("eye_of_lilith"))
	w.player_use(w.player.inventory.size() - 1)
	eq(w.player.stat("sight"), sight + 2, "+2 sight")
	eq(w.player.stat("accuracy"), acc + 1, "+1 accuracy")
	var def := w.player.stat("defense")
	var spd := w.player.stat("speed")
	w._add_to_inventory(w.player, w._new_item("preliator_plate"))
	w.player_use(w.player.inventory.size() - 1)
	eq(w.player.stat("defense"), def - 2 + 4, "hauberk 2 -> plate 4")
	eq(w.player.stat("speed"), spd - 10, "plate slows")


func test_max_hp_gear_keeps_the_health_fraction() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	var mx := w.player.stat("max_hp")
	w._add_to_inventory(w.player, w._new_item("broken_tithe_seal"))
	w.player_use(w.player.inventory.size() - 1)
	eq(w.player.stat("max_hp"), mx + 6, "+6 max health")
	eq(w.player.hp, mx + 6, "still at full health")
	w.player_unequip("amulet")
	eq(w.player.hp, mx, "clamped back down")


func test_healing_and_revenant_half_healing() -> void:
	var w := TestHelpers.ascii_world(ROOM, {}, "human")
	var r := TestHelpers.ascii_world(ROOM, {}, "revenant")
	for _i in 30:
		for pair in [[w, 4, 10], [r, 2, 5]]:
			var ww: World = pair[0]
			ww.player.hp = 1
			ww._add_to_inventory(ww.player, ww._new_item("healing_salve"))
			var idx := -1
			for i in ww.player.inventory.size():
				if ww.player.inventory[i].template_id == "healing_salve":
					idx = i
			ww.player_use(idx)
			var gained := ww.player.hp - 1
			ok(gained >= pair[1] and gained <= pair[2], "salve heals %d..%d (got %d)" % [pair[1], pair[2], gained])


func test_consumed_stack_shrinks_then_vanishes() -> void:
	var w := TestHelpers.ascii_world(ROOM)
	eq(_count(w, "healing_salve"), 1, "one salve")
	w.player_use(0)
	eq(_count(w, "healing_salve"), 0, "used up")
	eq(w.player.inventory.size(), 0, "slot freed")


func test_false_light_is_a_loan_then_reckoning() -> void:
	var w := TestHelpers.ascii_world(ROOM, {}, "human", "occultist")
	var acc := w.player.stat("accuracy")
	var idx := -1
	for i in w.player.inventory.size():
		if w.player.inventory[i].template_id == "vial_of_false_light":
			idx = i
	w.player.hp = 1
	w.player_use(idx)
	ok(w.player.has_status("false_light"), "false light active")
	eq(w.player.stat("accuracy"), acc + 2, "sharper while it lasts")
	ok(w.player.hp > 1, "regenerates")
	for _i in 25:
		w.player_wait()
	ok(not w.player.has_status("false_light"), "it fades")
	ok(w.player.has_status("reckoning"), "and the reckoning arrives")
	eq(w.player.stat("accuracy"), acc - 3, "the collection")
