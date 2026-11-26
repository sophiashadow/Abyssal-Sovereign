class_name Affixes
extends RefCounted
## Procedural equipment affixes, BUC status, and run-shuffled disguise names
## for unidentified consumables and scrolls.

const POTION_ALIASES: Array[String] = [
	"cloudy phial", "amber vial", "ash-grey draught", "copper flask",
	"verdigris bottle", "lead-sealed phial", "pale tincture", "gold-flecked vial",
	"salt-rimmed flask", "pitch-dark draught",
]

const SCROLL_ALIASES: Array[String] = [
	"parchment inked 'TITHE'", "vellum stamped 'PROSAY'", "charred scroll",
	"wax-sealed writ", "silver-ruled leaf", "torn ledger-sheet",
	"ink-stained rubric", "stamped audit-slip",
]

const PREFIXES := {
	"keen": {"label": "Keen", "slots": ["weapon", "ranged"], "mods": {"accuracy": 1, "crit": 5}},
	"brutal": {"label": "Brutal", "slots": ["weapon", "ranged"], "mods": {"damage": 2}},
	"ashen": {"label": "Ashen", "slots": ["weapon", "ranged"], "damage_type": "fire", "status": "burning"},
	"rimed": {"label": "Rimed", "slots": ["weapon", "ranged"], "damage_type": "cold", "status": "chilled"},
	"abyssal": {"label": "Abyssal", "slots": ["weapon", "ranged"], "mods": {"will": 1}, "damage_type": "void"},
	"gilded": {"label": "Gilded", "slots": ["weapon", "ranged"], "mods": {"accuracy": 1, "damage": 1}, "damage_type": "radiant"},
	"warded": {"label": "Warded", "slots": ["armor", "amulet"], "resists": {"fire": 15, "cold": 15}},
	"swift": {"label": "Swift", "slots": ["armor", "amulet"], "mods": {"evasion": 1, "speed": 10}},
	"stout": {"label": "Stout", "slots": ["armor", "amulet"], "mods": {"defense": 1, "max_hp": 4}},
	"occult": {"label": "Occult", "slots": ["armor", "amulet"], "mods": {"will": 1}, "resists": {"void": 20}},
}

const SUFFIXES := {
	"of_the_eye": {"label": "of the Eye", "slots": ["weapon", "ranged", "armor", "amulet"], "mods": {"sight": 1, "accuracy": 1}},
	"of_cinders": {"label": "of Cinders", "slots": ["armor", "amulet"], "resists": {"fire": 25}},
	"of_hoarfrost": {"label": "of Hoarfrost", "slots": ["armor", "amulet"], "resists": {"cold": 25}},
	"of_the_oath": {"label": "of the Oath", "slots": ["weapon", "ranged", "armor", "amulet"], "mods": {"might": 1, "defense": 1}},
	"of_venom": {"label": "of Venom", "slots": ["weapon", "ranged"], "mods": {"crit": 5}, "status": "bleeding"},
	"of_false_light": {"label": "of False Light", "slots": ["weapon", "ranged", "armor", "amulet"], "mods": {"damage": 1}, "resists": {"radiant": 25}},
}


static func is_prefix(affix_id: String) -> bool:
	return PREFIXES.has(affix_id)


static func label(affix_id: String) -> String:
	if PREFIXES.has(affix_id):
		return String(PREFIXES[affix_id]["label"])
	if SUFFIXES.has(affix_id):
		return String(SUFFIXES[affix_id]["label"])
	return affix_id


static func _compatible(table: Dictionary, kind: String) -> Array[String]:
	var out: Array[String] = []
	for k in table:
		if (table[k]["slots"] as Array).has(kind):
			out.append(String(k))
	out.sort()
	return out


static func apply_affix(it: Item, affix_id: String) -> void:
	var def: Dictionary = PREFIXES[affix_id] if PREFIXES.has(affix_id) else SUFFIXES.get(affix_id, {})
	if def.is_empty():
		return
	if not it.affixes.has(affix_id):
		it.affixes.append(affix_id)
	var m: Dictionary = def.get("mods", {})
	for stat_name in m:
		it.mods[stat_name] = int(it.mods.get(stat_name, 0)) + int(m[stat_name])
	var r: Dictionary = def.get("resists", {})
	for dt in r:
		it.resists[dt] = int(it.resists.get(dt, 0)) + int(r[dt])
	if def.has("damage_type") and it.bonus_damage_type == "":
		it.bonus_damage_type = String(def["damage_type"])
	if def.has("status") and it.bonus_status == "":
		it.bonus_status = String(def["status"])


static func roll_equipment(it: Item, db: ContentDB, depth: int, rng: Rng, guaranteed_magic: bool = false) -> void:
	if not it.is_equippable(db):
		return
	var d := it.def(db)
	var kind := String(d["kind"])
	if String(d.get("rarity", "common")) == "artifact":
		it.rarity = "artifact"
		it.buc = "blessed" if rng.chance_pct(25) else "uncursed"
		it.identified = false
		return
	var magic_pct := 100 if guaranteed_magic else mini(85, 32 + depth * 8)
	if rng.chance_pct(magic_pct):
		var rare_pct := mini(50, 15 + depth * 5)
		var is_rare := rng.chance_pct(rare_pct)
		it.rarity = "rare" if is_rare else "uncommon"
		var prefs := _compatible(PREFIXES, kind)
		var suffs := _compatible(SUFFIXES, kind)
		if is_rare and not prefs.is_empty() and not suffs.is_empty():
			apply_affix(it, String(rng.pick(prefs)))
			apply_affix(it, String(rng.pick(suffs)))
		elif not prefs.is_empty() and (suffs.is_empty() or rng.chance_pct(50)):
			apply_affix(it, String(rng.pick(prefs)))
		elif not suffs.is_empty():
			apply_affix(it, String(rng.pick(suffs)))
	if rng.chance_pct(12):
		it.buc = "blessed"
	elif rng.chance_pct(14):
		it.buc = "cursed"
	it.identified = (it.rarity == "common" and it.buc == "uncursed")
