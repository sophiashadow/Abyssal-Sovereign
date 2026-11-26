class_name Masks
extends RefCounted
## The four Mask stances from FALSE LIGHT §9: Bare Face, Nyx, Eris, Lilith.
## Switching is a turn cost; holding an active Mask accrues risk toward a
## seizure status until you cool down in Bare Face or rotate frequencies.

const ORDER: Array[String] = ["bare_face", "nyx", "eris", "lilith"]

const DEFS := {
	"bare_face": {
		"name": "Bare Face",
		"summary": "No combat bonus; cools accumulated Mask risk (-2/turn).",
		"mods": {},
		"resists": {},
		"seizure": "",
		"color": "#b8a8b8",
	},
	"nyx": {
		"name": "Nyx",
		"summary": "+2 evasion, +25% Void resist, -25% Radiant resist; unaware foes notice half as easily. Risk: Dissolution.",
		"mods": {"evasion": 2},
		"resists": {"void": 25, "radiant": -25},
		"seizure": "dissolution",
		"color": "#8f7ae0",
	},
	"eris": {
		"name": "Eris",
		"summary": "+2 damage, +1 accuracy, +25% Fire resist, -25% Cold resist; halts natural regen. Risk: Isolation.",
		"mods": {"damage": 2, "accuracy": 1},
		"resists": {"fire": 25, "cold": -25},
		"seizure": "isolation",
		"color": "#e05a47",
	},
	"lilith": {
		"name": "Lilith",
		"summary": "+2 sight, +2 will, +25% Radiant resist; foes notice 2 tiles farther. Risk: Exposure.",
		"mods": {"sight": 2, "will": 2},
		"resists": {"radiant": 25},
		"seizure": "exposure",
		"color": "#e8c547",
	},
}


static func is_valid(id: String) -> bool:
	return DEFS.has(id)


static func label(id: String) -> String:
	return String(DEFS.get(id, DEFS["bare_face"])["name"])


static func summary(id: String) -> String:
	return String(DEFS.get(id, DEFS["bare_face"])["summary"])


static func mods(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["bare_face"])["mods"]


static func resists(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["bare_face"])["resists"]


static func seizure_status(id: String) -> String:
	return String(DEFS.get(id, DEFS["bare_face"])["seizure"])


static func color(id: String) -> String:
	return String(DEFS.get(id, DEFS["bare_face"])["color"])
