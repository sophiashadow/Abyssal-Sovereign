class_name ContentSchema
extends RefCounted
## The single source of truth for content file shapes. docs/CONTENT_SCHEMA.md
## documents these; tests/test_content.gd checks the doc names every field.
##
## Field type mini-language:
##   id            lowercase snake_case identifier
##   string        non-empty string
##   text          any string
##   int / number / bool
##   dice          dice notation, see src/core/dice.gd
##   glyph         exactly one character
##   color         "#rrggbb"
##   enum:a|b|c    one of the listed strings
##   ref:<kind>    an id defined in that content kind
##   list:<type>   array whose elements match <type>
##   mods          object mapping a known modifier stat to an int
##   attrs         object mapping an attribute (might, agility, will) to an int
##   table:<kind>  array of {"id": ref:<kind>, "weight": int > 0}
##   trait         a trait id implemented in src/sim/traits.gd

const KINDS: Array[String] = ["statuses", "items", "species", "classes", "talents", "contracts", "factions", "npcs", "threads", "monsters", "floors"]

## Stats that equipment, statuses and species may modify.
const MOD_STATS: Array[String] = [
	"might", "agility", "will", "max_hp", "accuracy", "evasion", "defense",
	"damage", "crit", "speed", "sight",
]
const ATTRIBUTES: Array[String] = ["might", "agility", "will"]
const DAMAGE_TYPES: Array[String] = ["physical", "fire", "cold", "radiant", "void"]

const FIELDS := {
	"statuses": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"description": {"type": "text", "required": true},
		"duration": {"type": "int", "required": true, "min": 1},
		"mods": {"type": "mods", "required": false},
		"resists": {"type": "resists", "required": false},
		"regen": {"type": "int", "required": false},
		"damage_type": {"type": "enum:physical|fire|cold|radiant|void", "required": false},
		"on_expire": {"type": "ref:statuses", "required": false},
		"color": {"type": "color", "required": false},
	},
	"items": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"glyph": {"type": "glyph", "required": true},
		"color": {"type": "color", "required": true},
		"kind": {"type": "enum:weapon|ranged|armor|amulet|consumable|relic|key", "required": true},
		"description": {"type": "text", "required": true},
		"damage": {"type": "dice", "required": false},
		"range": {"type": "int", "required": false, "min": 1},
		"damage_type": {"type": "enum:physical|fire|cold|radiant|void", "required": false},
		"aoe_radius": {"type": "int", "required": false, "min": 0},
		"accuracy": {"type": "int", "required": false},
		"crit": {"type": "int", "required": false},
		"defense": {"type": "int", "required": false},
		"evasion": {"type": "int", "required": false},
		"mods": {"type": "mods", "required": false},
		"resists": {"type": "resists", "required": false},
		"rarity": {"type": "enum:common|uncommon|rare|artifact", "required": false},
		"set_id": {"type": "string", "required": false},
		"effect": {"type": "enum:heal|status|projectile|scroll", "required": false},
		"heal": {"type": "dice", "required": false},
		"status": {"type": "ref:statuses", "required": false},
		"spell": {"type": "string", "required": false},
		"stackable": {"type": "bool", "required": false},
		"work_status": {"type": "ref:statuses", "required": false},
		"work_cost_hp": {"type": "int", "required": false, "min": 0},
		"work_desc": {"type": "text", "required": false},
		"transmute_mods": {"type": "mods", "required": false},
		"transmute_desc": {"type": "text", "required": false},
	},
	"species": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"description": {"type": "text", "required": true},
		"attributes": {"type": "attrs", "required": true},
		"hp": {"type": "int", "required": true},
		"hp_per_level": {"type": "int", "required": true},
		"xp_mult": {"type": "number", "required": false},
		"heal_mult": {"type": "number", "required": false},
		"mods": {"type": "mods", "required": false},
		"resists": {"type": "resists", "required": false},
		"traits": {"type": "list:trait", "required": false},
	},
	"classes": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"description": {"type": "text", "required": true},
		"attributes": {"type": "attrs", "required": true},
		"hp": {"type": "int", "required": true, "min": 1},
		"hp_per_level": {"type": "int", "required": true, "min": 0},
		"accuracy": {"type": "int", "required": false},
		"evasion": {"type": "int", "required": false},
		"starting_equipment": {"type": "list:ref:items", "required": true},
		"starting_items": {"type": "list:ref:items", "required": false},
		"resource": {"type": "enum:stamina|resonance|poise", "required": false},
		"traits": {"type": "list:trait", "required": false},
	},
	"talents": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"class_id": {"type": "ref:classes", "required": true},
		"tree": {"type": "string", "required": true},
		"tier": {"type": "int", "required": true, "min": 1},
		"kind": {"type": "enum:passive|active", "required": true},
		"max_rank": {"type": "int", "required": true, "min": 1},
		"prereq": {"type": "ref:talents", "required": false},
		"cost": {"type": "int", "required": false, "min": 0},
		"cooldown": {"type": "int", "required": false, "min": 0},
		"range": {"type": "int", "required": false, "min": 0},
		"damage_type": {"type": "enum:physical|fire|cold|radiant|void", "required": false},
		"targeting": {"type": "enum:self|enemy|tile", "required": false},
		"description": {"type": "text", "required": true},
		"mods": {"type": "mods", "required": false},
		"effect": {"type": "string", "required": false},
	},
	"contracts": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"description": {"type": "text", "required": true},
		"way": {"type": "enum:serpent|return", "required": true},
		"oath": {"type": "enum:no_healing_items|light_pack|no_return_rites|no_by_name", "required": true},
		"oath_text": {"type": "text", "required": true},
		"boon_status": {"type": "ref:statuses", "required": true},
		"reward_mods": {"type": "mods", "required": true},
		"floors": {"type": "int", "required": true, "min": 1},
		"apotheosis": {"type": "int", "required": false},
	},
	"factions": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"description": {"type": "text", "required": true},
		"pole_a": {"type": "id", "required": true},
		"pole_a_label": {"type": "string", "required": true},
		"pole_b": {"type": "id", "required": true},
		"pole_b_label": {"type": "string", "required": true},
		"provenance": {"type": "enum:canon|canon_derived|interpretation|proposed", "required": true},
	},
	"npcs": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"role": {"type": "string", "required": true},
		"faction": {"type": "ref:factions", "required": true},
		"faction_pole": {"type": "id", "required": true},
		"floors": {"type": "list:ref:floors", "required": true},
		"greeting": {"type": "text", "required": true},
		"service": {"type": "enum:repair_curse|bless_gear|identify_rumor|barter_gear|heal_shelter|reduce_chains|contract_aid|attest_way", "required": true},
		"provenance": {"type": "enum:canon|canon_derived|interpretation|proposed", "required": true},
	},
	"threads": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"description": {"type": "text", "required": true},
		"lead_text": {"type": "text", "required": true},
		"trigger_kind": {"type": "enum:npc|floor|boss|relic|contract", "required": true},
		"trigger_ref": {"type": "string", "required": true},
		"faction": {"type": "ref:factions", "required": true},
		"npc_id": {"type": "ref:npcs", "required": true},
		"goal_kind": {"type": "enum:visit_floor|kill_monster|npc_talk|work_relic|transmute_relic|attest_contract|sacrifice_hp", "required": true},
		"goal_ref": {"type": "string", "required": true},
		"delay_turns": {"type": "int", "required": true, "min": 0},
		"reward_kind": {"type": "enum:stat_point|talent_point|heal_vigor|loot_magic|reduce_chains|way_return|way_serpent|faction_pole", "required": true},
		"refusal_effect": {"type": "enum:standing_drop|subjugation_spike|faction_shift|ambush_alert|curse_mark", "required": true},
		"provenance": {"type": "enum:canon|canon_derived|interpretation|proposed", "required": true},
	},
	"monsters": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"glyph": {"type": "glyph", "required": true},
		"color": {"type": "color", "required": true},
		"description": {"type": "text", "required": true},
		"hp": {"type": "int", "required": true, "min": 1},
		"damage": {"type": "dice", "required": true},
		"damage_type": {"type": "enum:physical|fire|cold|radiant|void", "required": false},
		"ranged_damage": {"type": "dice", "required": false},
		"ranged_range": {"type": "int", "required": false, "min": 1},
		"accuracy": {"type": "int", "required": true},
		"evasion": {"type": "int", "required": true},
		"defense": {"type": "int", "required": true},
		"speed": {"type": "int", "required": true, "min": 10},
		"xp": {"type": "int", "required": true, "min": 0},
		"perception": {"type": "int", "required": true, "min": 1},
		"resists": {"type": "resists", "required": false},
		"specials": {"type": "list:string", "required": false},
		"tags": {"type": "list:string", "required": false},
		"unique": {"type": "bool", "required": false},
	},
	"floors": {
		"id": {"type": "id", "required": true},
		"depth": {"type": "int", "required": true, "min": 1},
		"sphere": {"type": "string", "required": false},
		"region_kind": {"type": "enum:spine|branch|sanctuary|vault|stronghold|settlement", "required": false},
		"branch": {"type": "string", "required": false},
		"hazard": {"type": "enum:none|ash_ember|rime_ice|miasma|solar_glare", "required": false},
		"terrain": {"type": "enum:standard|water|sanctuary|iron_grate", "required": false},
		"parent": {"type": "ref:floors", "required": false},
		"alt_down": {"type": "ref:floors", "required": false},
		"sites": {"type": "list:string", "required": false},
		"provenance": {"type": "enum:canon|canon_derived|interpretation|proposed", "required": false},
		"name": {"type": "string", "required": true},
		"description": {"type": "text", "required": true},
		"width": {"type": "int", "required": true, "min": 20},
		"height": {"type": "int", "required": true, "min": 15},
		"rooms_min": {"type": "int", "required": true, "min": 2},
		"rooms_max": {"type": "int", "required": true, "min": 2},
		"monsters_min": {"type": "int", "required": true, "min": 0},
		"monsters_max": {"type": "int", "required": true, "min": 0},
		"items_min": {"type": "int", "required": true, "min": 0},
		"items_max": {"type": "int", "required": true, "min": 0},
		"monster_table": {"type": "table:monsters", "required": true},
		"item_table": {"type": "table:items", "required": true},
		"exit": {"type": "enum:stairs|sealed_door|branch_end", "required": true},
		"guardian": {"type": "ref:monsters", "required": false},
		"boss": {"type": "ref:monsters", "required": false},
	},
}

## Extra rules: per item kind, fields that must be present.
const ITEM_KIND_REQUIRES := {
	"weapon": ["damage"],
	"ranged": ["damage", "range"],
	"armor": ["defense"],
	"amulet": ["mods"],
	"consumable": ["effect"],
	"relic": ["work_status", "work_desc", "transmute_mods", "transmute_desc"],
}
