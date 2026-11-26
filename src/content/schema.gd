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

const KINDS: Array[String] = ["statuses", "items", "species", "classes", "monsters", "floors"]

## Stats that equipment, statuses and species may modify.
const MOD_STATS: Array[String] = [
	"might", "agility", "will", "max_hp", "accuracy", "evasion", "defense",
	"damage", "crit", "speed", "sight",
]
const ATTRIBUTES: Array[String] = ["might", "agility", "will"]

const FIELDS := {
	"statuses": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"description": {"type": "text", "required": true},
		"duration": {"type": "int", "required": true, "min": 1},
		"mods": {"type": "mods", "required": false},
		"regen": {"type": "int", "required": false},
		"on_expire": {"type": "ref:statuses", "required": false},
		"color": {"type": "color", "required": false},
	},
	"items": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"glyph": {"type": "glyph", "required": true},
		"color": {"type": "color", "required": true},
		"kind": {"type": "enum:weapon|armor|amulet|consumable", "required": true},
		"description": {"type": "text", "required": true},
		"damage": {"type": "dice", "required": false},
		"accuracy": {"type": "int", "required": false},
		"crit": {"type": "int", "required": false},
		"defense": {"type": "int", "required": false},
		"evasion": {"type": "int", "required": false},
		"mods": {"type": "mods", "required": false},
		"effect": {"type": "enum:heal|status", "required": false},
		"heal": {"type": "dice", "required": false},
		"status": {"type": "ref:statuses", "required": false},
		"stackable": {"type": "bool", "required": false},
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
		"traits": {"type": "list:trait", "required": false},
	},
	"monsters": {
		"id": {"type": "id", "required": true},
		"name": {"type": "string", "required": true},
		"glyph": {"type": "glyph", "required": true},
		"color": {"type": "color", "required": true},
		"description": {"type": "text", "required": true},
		"hp": {"type": "int", "required": true, "min": 1},
		"damage": {"type": "dice", "required": true},
		"accuracy": {"type": "int", "required": true},
		"evasion": {"type": "int", "required": true},
		"defense": {"type": "int", "required": true},
		"speed": {"type": "int", "required": true, "min": 10},
		"xp": {"type": "int", "required": true, "min": 0},
		"perception": {"type": "int", "required": true, "min": 1},
		"tags": {"type": "list:string", "required": false},
		"unique": {"type": "bool", "required": false},
	},
	"floors": {
		"id": {"type": "id", "required": true},
		"depth": {"type": "int", "required": true, "min": 1},
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
		"exit": {"type": "enum:stairs|sealed_door", "required": true},
		"guardian": {"type": "ref:monsters", "required": false},
	},
}

## Extra rules: per item kind, fields that must be present.
const ITEM_KIND_REQUIRES := {
	"weapon": ["damage"],
	"armor": ["defense"],
	"amulet": ["mods"],
	"consumable": ["effect"],
}
