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


static func mask_risk_bonus(actor: Actor, db: ContentDB) -> int:
	var counts := active_counts(actor, db)
	if int(counts.get("unblinking_eye", 0)) >= 3:
		return int(SETS["unblinking_eye"]["3"].get("mask_risk", 0))
	return 0


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
