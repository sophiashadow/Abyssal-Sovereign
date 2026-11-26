class_name ItemSets
extends RefCounted
## Equipment sets granting 2-piece and 3-piece build synergies.

const SETS := {
	"inquisitors_audit": {
		"name": "Inquisitor's Audit",
		"2": {"mods": {"accuracy": 2, "defense": 1}, "resists": {}, "desc": "+2 accuracy, +1 defense"},
		"3": {"mods": {"damage": 3}, "resists": {"radiant": 25}, "desc": "+3 damage, +25% radiant resist"},
	},
	"unblinking_eye": {
		"name": "The Eye Unblinking",
		"2": {"mods": {"will": 2, "sight": 1}, "resists": {}, "desc": "+2 will, +1 sight"},
		"3": {"mods": {"accuracy": 2}, "resists": {"void": 25}, "mask_risk": 3, "desc": "+2 accuracy, +25% void resist, +3 Mask risk cap"},
	},
	"cinder_oath": {
		"name": "Cinder & Oath",
		"2": {"mods": {"might": 2}, "resists": {"fire": 25}, "desc": "+2 might, +25% fire resist"},
		"3": {"mods": {"crit": 10, "speed": 10}, "resists": {"cold": 20}, "desc": "+10% crit, +10 speed, +20% cold resist"},
	},
	"preliator_bastion": {
		"name": "Preliator's Bastion",
		"2": {"mods": {"defense": 2}, "resists": {"physical": 10}, "desc": "+2 defense, +10% physical resist"},
		"3": {"mods": {"max_hp": 6}, "resists": {"radiant": 25}, "subjugation_cap": 1, "desc": "+6 max HP, +25% radiant resist, +1 Subjugation limit"},
	},
	"tithe_collectors": {
		"name": "Tithe Collector's Tally",
		"2": {"mods": {"accuracy": 2, "might": 1}, "resists": {}, "desc": "+2 accuracy, +1 might"},
		"3": {"mods": {"damage": 2, "crit": 10}, "resists": {}, "desc": "+2 damage, +10% crit"},
	},
	"ophite_seam": {
		"name": "Ophite Seam",
		"2": {"mods": {"agility": 1, "evasion": 2}, "resists": {}, "desc": "+1 agility, +2 evasion"},
		"3": {"mods": {"speed": 15}, "resists": {"void": 25}, "desc": "+15 speed, +25% void resist"},
	},
	"ash_penitent": {
		"name": "Ash Penitent",
		"2": {"mods": {"will": 1}, "resists": {"fire": 25}, "desc": "+1 will, +25% fire resist"},
		"3": {"mods": {"damage": 2, "crit": 12}, "resists": {"void": 15}, "desc": "+2 damage, +12% crit, +15% void resist"},
	},
	"velvet_ossuary": {
		"name": "Velvet Ossuary",
		"2": {"mods": {"max_hp": 6}, "resists": {"cold": 25}, "desc": "+6 max HP, +25% cold resist"},
		"3": {"mods": {"defense": 2, "will": 2}, "resists": {"physical": 15}, "desc": "+2 defense, +2 will, +15% physical resist"},
	},
	"archive_warden": {
		"name": "Archive Keeper's Seal",
		"2": {"mods": {"sight": 2, "will": 1}, "resists": {}, "desc": "+2 sight, +1 will"},
		"3": {"mods": {"accuracy": 2}, "resists": {"void": 20}, "mask_risk": 2, "desc": "+2 accuracy, +20% void resist, +2 Mask risk cap"},
	},
	"processional_guard": {
		"name": "Processional Guard",
		"2": {"mods": {"might": 1, "accuracy": 2}, "resists": {}, "desc": "+1 might, +2 accuracy"},
		"3": {"mods": {"defense": 2, "damage": 2}, "resists": {"physical": 10}, "desc": "+2 defense, +2 damage, +10% physical resist"},
	},
	"unwritten_margin": {
		"name": "The Unwritten Margin",
		"2": {"mods": {"evasion": 2, "agility": 1}, "resists": {}, "desc": "+2 evasion, +1 agility"},
		"3": {"mods": {"crit": 15, "speed": 15}, "resists": {}, "subjugation_cap": 1, "desc": "+15% crit, +15 speed, +1 Subjugation limit"},
	},
	"false_sun_choir": {
		"name": "Chorus of False Light",
		"2": {"mods": {"will": 1}, "resists": {"radiant": 25}, "desc": "+1 will, +25% radiant resist"},
		"3": {"mods": {"damage": 3, "accuracy": 2}, "resists": {}, "mask_risk": 1, "desc": "+3 damage, +2 accuracy, +1 Mask risk cap"},
	},
}


static func set_name(sid: String) -> String:
	return String(SETS.get(sid, {}).get("name", sid))


static func active_counts(actor: Actor, db: ContentDB) -> Dictionary:
	var counts := {}
	if actor == null or db == null or actor.equipment.is_empty():
		return counts
	var seen_templates := {}
	for slot in Actor.SLOTS:
		var it := actor.equipped(slot)
		if it == null or seen_templates.has(it.template_id):
			continue
		var sid := String(it.def(db).get("set_id", ""))
		if sid != "" and SETS.has(sid):
			seen_templates[it.template_id] = true
			counts[sid] = int(counts.get(sid, 0)) + 1
	return counts


static func mod_sum(actor: Actor, db: ContentDB, stat_name: String) -> int:
	if actor == null or actor.equipment.is_empty():
		return 0
	var counts := active_counts(actor, db)
	var total := 0
	for sid in counts:
		var c := int(counts[sid])
		var sdef: Dictionary = SETS[sid]
		if c >= 2:
			total += int(sdef["2"]["mods"].get(stat_name, 0))
		if c >= 3:
			total += int(sdef["3"]["mods"].get(stat_name, 0))
	return total


static func resist_sum(actor: Actor, db: ContentDB, dmg_type: String) -> int:
	if actor == null or actor.equipment.is_empty():
		return 0
	var counts := active_counts(actor, db)
	var total := 0
	for sid in counts:
		var c := int(counts[sid])
		var sdef: Dictionary = SETS[sid]
		if c >= 2:
			total += int(sdef["2"]["resists"].get(dmg_type, 0))
		if c >= 3:
			total += int(sdef["3"]["resists"].get(dmg_type, 0))
	return total


static func _bonus_field_sum(actor: Actor, db: ContentDB, field_name: String) -> int:
	if actor == null or actor.equipment.is_empty():
		return 0
	var counts := active_counts(actor, db)
	var total := 0
	for sid in counts:
		var c := int(counts[sid])
		var sdef: Dictionary = SETS[sid]
		if c >= 2:
			total += int(sdef["2"].get(field_name, 0))
		if c >= 3:
			total += int(sdef["3"].get(field_name, 0))
	return total


static func mask_risk_bonus(actor: Actor, db: ContentDB) -> int:
	return _bonus_field_sum(actor, db, "mask_risk")


static func subjugation_cap_bonus(actor: Actor, db: ContentDB) -> int:
	return _bonus_field_sum(actor, db, "subjugation_cap")


static func summaries(actor: Actor, db: ContentDB) -> Array[String]:
	var out: Array[String] = []
	var counts := active_counts(actor, db)
	for sid in counts:
		var c := int(counts[sid])
		var sdef: Dictionary = SETS[sid]
		var bonuses: PackedStringArray = []
		if c >= 2:
			bonuses.append("2pc: " + String(sdef["2"]["desc"]))
		if c >= 3:
			bonuses.append("3pc: " + String(sdef["3"]["desc"]))
		var detail := " (" + "; ".join(bonuses) + ")" if not bonuses.is_empty() else " (2pc unlocks bonus)"
		out.append("%s [%d/3]%s" % [sdef["name"], c, detail])
	return out
