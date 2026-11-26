extends TestCase
## M5.3 Equipment and discovery: affixes, rarity, artifacts, identification,
## blessed/cursed items, equipment sets, and EXODUS relics.


func test_procedural_affixes_and_rarity_determinism() -> void:
	var w1 := World.new_run(db(), 901, "human", "fallen_knight", "A1")
	var w2 := World.new_run(db(), 901, "human", "fallen_knight", "A2")
	var items1 := w1.current_floor().items
	var items2 := w2.current_floor().items
	eq(items1.size(), items2.size(), "same floor item count for same seed")
	for i in items1.size():
		eq(JSON.stringify(items1[i].to_dict()), JSON.stringify(items2[i].to_dict()), "deterministic floor item %d" % i)

	var it := w1._new_item("notched_longsword")
	Affixes.apply_affix(it, "ashen")
	Affixes.apply_affix(it, "of_the_eye")
	it.rarity = "rare"
	it.buc = "blessed"
	it.identified = true
	eq(it.effective_damage_type(db()), "fire", "ashen affix shifts weapon to fire")
	eq(it.effective_status(db()), "burning", "ashen affix grants burning on hit")
	eq(it.total_mod(db(), "sight"), 1, "of_the_eye adds sight")
	eq(it.total_mod(db(), "accuracy"), 2, "blessed +1 and of_the_eye +1 accuracy")
	ok(it.display_name(db()).contains("Blessed Ashen notched longsword of the Eye"), "affixed display name: %s" % it.display_name(db()))


func test_unidentified_consumables_and_equipment_discovery() -> void:
	var w := World.new_run(db(), 902, "human", "fallen_knight", "Id")
	ok(bool(w.id_known.get("healing_salve", false)), "starting healing salve is already known")
	ok(not bool(w.id_known.get("bone_tincture", false)), "unseen bone tincture starts unknown")
	var tinct := w._new_item("bone_tincture")
	var disguised := w.item_name(tinct)
	ok(not disguised.contains("bone tincture"), "unidentified potion uses disguise (%s)" % disguised)
	ok(w.id_aliases.get("bone_tincture", "") == disguised, "matches run alias")

	var idx := w.player.inventory.size()
	w._add_to_inventory(w.player, tinct)
	var sword := w._new_item("notched_longsword")
	Affixes.apply_affix(sword, "keen")
	sword.rarity = "uncommon"
	sword.identified = false
	w._add_to_inventory(w.player, sword)
	ok(w.item_name(sword).begins_with("glowing "), "unidentified magical gear hides affixes")

	var id_idx := w.player.inventory.size()
	w._add_to_inventory(w.player, w._new_item("scroll_of_identify"))
	ok(w.player_use(id_idx), "read scroll of witness")
	ok(bool(w.id_known.get("bone_tincture", false)), "scroll revealed bone tincture")
	ok(sword.identified, "scroll identified magical sword")
	eq(w.item_name(tinct), "bone tincture", "true potion name shown after ID")


func test_blessed_and_cursed_equipment_mechanics() -> void:
	var w := World.new_run(db(), 903, "human", "fallen_knight", "Curse")
	var curse_blade := w._new_item("stiletto")
	curse_blade.buc = "cursed"
	curse_blade.identified = false
	var idx := w.player.inventory.size()
	w._add_to_inventory(w.player, curse_blade)
	ok(w.player_use(idx), "equipped cursed blade")
	ok(curse_blade.identified, "equipping reveals item and curse")
	eq(w.player.equipped("weapon"), curse_blade, "cursed blade equipped")
	ok(not w.player_unequip("weapon"), "cannot unequip cursed weapon")
	var unbind_idx := w.player.inventory.size()
	w._add_to_inventory(w.player, w._new_item("scroll_of_unbind"))
	ok(w.player_use(unbind_idx), "read scroll of unbinding")
	eq(curse_blade.buc, "uncursed", "curse lifted")
	ok(w.player_unequip("weapon"), "can unequip once unbound")

	var w2 := World.new_run(db(), 904, "human", "fallen_knight", "Chain")
	var c2 := w2._new_item("stiletto")
	c2.buc = "cursed"
	c2.identified = true
	w2._add_to_inventory(w2.player, c2)
	w2.player_use(w2.player.inventory.size() - 1)
	w2.player_learn_talent("break_the_chain")
	ok(w2.player_use_talent("break_the_chain"), "break_the_chain unbinds curse")
	eq(c2.buc, "uncursed", "break_the_chain removed weapon curse")


func test_equipment_sets_and_unique_artifacts() -> void:
	var w := World.new_run(db(), 905, "human", "occultist", "Sets")
	var base_will := w.player.stat("will")
	var base_sight := w.player.stat("sight")
	var rod := w._new_item("abyssal_rod")
	var cowl := w._new_item("prosay_cowl")
	var eye := w._new_item("eye_of_lilith")
	w.player.equipment["ranged"] = rod
	w.player.equipment["armor"] = cowl
	var counts2 := ItemSets.active_counts(w.player, db())
	eq(int(counts2.get("unblinking_eye", 0)), 2, "2pc Unblinking Eye active")
	eq(w.player.stat("will"), base_will + 3, "+1 cowl +2 set 2pc (rod matches starting eye_focus +1 will)")
	w.player.equipment["amulet"] = eye
	eq(int(ItemSets.active_counts(w.player, db()).get("unblinking_eye", 0)), 3, "3pc Unblinking Eye active")
	eq(w.player.stat("sight"), base_sight + 2 + 2 + 1, "cowl +2, eye +2, 2pc +1 sight")
	eq(ItemSets.mask_risk_bonus(w.player, db()), 3, "3pc Unblinking Eye adds +3 Mask risk cap")

	var art := w._maybe_artifact_drop()
	ok(art != null and art.rarity == "artifact", "spawned artifact")
	eq(w.spawned_uniques.size(), 1, "artifact recorded as unique")


func test_new_exodus_relics() -> void:
	var w := World.new_run(db(), 906, "human", "occultist", "Relics")
	var lamp := w._new_item("ward_keepers_lamp")
	var mystery := w._new_item("ossuary_rime_vial")
	w._add_to_inventory(w.player, lamp)
	w._add_to_inventory(w.player, mystery)
	w.apply_status(w.player, "perception_fog")
	var lamp_idx := w.player.inventory.size() - 2
	ok(w.player_work_relic(lamp_idx), "worked Ward-Keeper's Lamp")
	ok(w.player.has_status("lamp_vigil"), "lamp_vigil applied")
	ok(not w.player.has_status("perception_fog"), "lamp cleared perception_fog")
	ok(bool(w.id_known.get("ossuary_rime_vial", false)), "lamp identified unseen flask")

	var purse := w._new_item("almoners_purse")
	w._add_to_inventory(w.player, purse)
	w.player.resource = 2
	ok(w.player_work_relic(w.player.inventory.size() - 1), "worked Almoner's Purse")
	ok(w.player.has_status("almoners_grace"), "almoners_grace applied")
	ok(w.player.resource >= 6, "purse restored resource")

	var crown := w._new_item("severed_crown")
	w._add_to_inventory(w.player, crown)
	var dmg_before := w.player.stat("damage_bonus")
	ok(w.player_transmute_relic(w.player.inventory.size() - 1), "transmuted Severed Crown")
	ok(w.player.stat("damage_bonus") > dmg_before, "crown transmute raised damage")
