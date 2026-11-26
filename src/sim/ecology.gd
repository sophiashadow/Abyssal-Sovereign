class_name Ecology
extends RefCounted
## M5.4 Dungeon ecology definitions: traps, environmental hazards, secret doors,
## altars, shrines, ritual circles, locked vaults, wandering brokers, challenge monoliths,
## and procedural Sphere profiles.

const TRAPS := {
	"spike": {"name": "ledger-spike trap", "damage": "1d6+2", "damage_type": "physical", "status": "bleeding"},
	"cinder": {"name": "cinder-wire trap", "damage": "1d6+2", "damage_type": "fire", "status": "burning"},
	"rime": {"name": "rime-seal trap", "damage": "1d6+1", "damage_type": "cold", "status": "chilled"},
	"shackle": {"name": "shackle-snare trap", "damage": "1d4+1", "damage_type": "physical", "status": "pinned"},
}

const HAZARDS := {
	Tiles.ASH_EMBER: {"name": "smoldering embers", "damage_type": "fire", "status": "burning"},
	Tiles.RIME_ICE: {"name": "ossuary rime", "damage_type": "cold", "status": "chilled"},
	Tiles.MIASMA: {"name": "abyssal miasma", "damage_type": "void", "status": "hexed"},
	Tiles.SOLAR_GLARE: {"name": "false-sun glare", "damage_type": "radiant", "status": "exposure"},
}

const SPHERE_PROFILES := {
	1: {"hazard": Tiles.ASH_EMBER, "h_min": 3, "h_max": 6, "traps": ["spike", "rime"],
		"sites": [{"kind": "shrine", "sub": "eye"}, {"kind": "altar", "sub": "unbinding"}]},
	2: {"hazard": Tiles.RIME_ICE, "h_min": 4, "h_max": 7, "traps": ["spike", "shackle"],
		"sites": [{"kind": "vault_gate", "sub": "locked_vault"}, {"kind": "merchant", "sub": "broker"}, {"kind": "contract_lectern", "sub": "rites"}]},
	3: {"hazard": Tiles.SOLAR_GLARE, "h_min": 4, "h_max": 8, "traps": ["cinder", "shackle"],
		"sites": [{"kind": "altar", "sub": "unbinding"}, {"kind": "ritual_circle", "sub": "geometry"}, {"kind": "challenge", "sub": "trial_bell"}]},
	4: {"hazard": Tiles.SOLAR_GLARE, "h_min": 5, "h_max": 9, "traps": ["cinder", "shackle"],
		"sites": [{"kind": "shrine", "sub": "eye"}, {"kind": "vault_gate", "sub": "locked_vault"}, {"kind": "merchant", "sub": "broker"}, {"kind": "contract_lectern", "sub": "rites"}]},
	5: {"hazard": Tiles.ASH_EMBER, "h_min": 5, "h_max": 9, "traps": ["spike", "cinder", "shackle"],
		"sites": [{"kind": "ritual_circle", "sub": "geometry"}, {"kind": "vault_gate", "sub": "locked_vault"}, {"kind": "challenge", "sub": "trial_bell"}]},
	6: {"hazard": Tiles.MIASMA, "h_min": 5, "h_max": 10, "traps": ["rime", "shackle", "cinder"],
		"sites": [{"kind": "altar", "sub": "unbinding"}, {"kind": "merchant", "sub": "broker"}, {"kind": "vault_gate", "sub": "locked_vault"}, {"kind": "contract_lectern", "sub": "rites"}]},
	7: {"hazard": Tiles.MIASMA, "h_min": 6, "h_max": 10, "traps": ["shackle", "rime", "spike"],
		"sites": [{"kind": "shrine", "sub": "eye"}, {"kind": "ritual_circle", "sub": "geometry"}, {"kind": "challenge", "sub": "trial_bell"}]},
}

const BROKER_POOL: Array[String] = [
	"healing_salve", "bone_tincture", "cinder_flask", "ossuary_rime_vial",
	"scroll_of_identify", "scroll_of_unbind", "scroll_of_phase_step",
	"scroll_of_abyssal_lance", "vault_key", "witness_mantle", "abyssal_rod",
]


static func glyph(feat: Dictionary) -> String:
	match String(feat.get("kind", "")):
		"trap":
			return "_" if bool(feat.get("used", false)) else "^"
		"secret_door":
			return "'" if bool(feat.get("used", false)) else "+"
		"altar":
			return "_"
		"shrine":
			return "&"
		"ritual_circle":
			return "O"
		"vault_gate":
			return "'" if bool(feat.get("used", false)) else "="
		"merchant":
			return "$"
		"contract_lectern":
			return "%"
		"challenge":
			return "!"
	return "?"


static func color(feat: Dictionary) -> String:
	if bool(feat.get("used", false)):
		return "#6a5f70"
	match String(feat.get("kind", "")):
		"trap":
			return "#ff4d6d"
		"secret_door":
			return "#c6aa70"
		"altar":
			return "#eee5d3"
		"shrine":
			return "#78bea7"
		"ritual_circle":
			return "#c77dff"
		"vault_gate":
			return "#f2c35c"
		"merchant":
			return "#f2c35c"
		"contract_lectern":
			return "#c77dff"
		"challenge":
			return "#ff7a33"
	return "#eee5d3"


static func label(feat: Dictionary) -> String:
	match String(feat.get("kind", "")):
		"trap":
			var tname := String(TRAPS.get(String(feat.get("sub", "spike")), {}).get("name", "trap"))
			return tname + (" (disarmed)" if bool(feat.get("used", false)) else "")
		"secret_door":
			return "revealed passage" if bool(feat.get("used", false)) else "secret cache door"
		"altar":
			return "Altar of Unbinding" + (" (spent)" if bool(feat.get("used", false)) else "")
		"shrine":
			return "Shrine of the Unblinking Eye" + (" (spent)" if bool(feat.get("used", false)) else "")
		"ritual_circle":
			return "Geometric Ritual Circle" + (" (spent)" if bool(feat.get("used", false)) else "")
		"vault_gate":
			return "Locked Audit Vault" + (" (opened)" if bool(feat.get("used", false)) else "")
		"merchant":
			return "Wandering Debt-Broker"
		"contract_lectern":
			return "Lectern of Rites"
		"challenge":
			return "Trial Bell Monolith" + (" (rung)" if bool(feat.get("used", false)) else "")
	return "feature"


static func description(feat: Dictionary) -> String:
	match String(feat.get("kind", "")):
		"trap":
			return "Disarmed mechanism." if bool(feat.get("used", false)) else "A concealed Dominion mechanism underfoot."
		"secret_door":
			return "An opened hidden cache." if bool(feat.get("used", false)) else "False-flagged stonework hiding an unrecorded cache."
		"altar":
			return "A cracked stone slab scored outside Prosay's ledger. Unbinds curses or blesses endurance at blood cost."
		"shrine":
			return "An altar etched with the Eye. Witnesses hidden items and traps, or trades apotheosis for Will."
		"ritual_circle":
			return "Chalk-chalked Geometry still humming. Inscribes affixes onto gear or drains cooldowns & Mask strain."
		"vault_gate":
			return "Heavy black-iron audit bars sealing untouched salvage inside."
		"merchant":
			return "A hooded clerk from the lower seams trading salvage for blood or spare goods."
		"contract_lectern":
			return "A black-lacquered lectern open to the rites of the Two Ways. Sign a divine contract: a boon now, an oath to keep, a reward if you do."
		"challenge":
			return "An iron bell inscribed 'RING TO PROVE WORTH'. Summons an ambush for elite plunder and growth."
	return ""


static func is_interactive(feat: Dictionary) -> bool:
	if feat.is_empty():
		return false
	var k := String(feat.get("kind", ""))
	if k == "trap":
		return false
	if bool(feat.get("used", false)) and k != "merchant":
		return false
	return true
