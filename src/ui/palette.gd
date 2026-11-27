class_name Palette
extends RefCounted
## Colours shared by every screen. Derived from the FALSE LIGHT visual
## language (void, Lux magenta, record parchment, false-sun gold); see
## docs/LORE.md. Rendering only: the simulation never reads these.

const VOID := Color("#080609")
const PANEL := Color("#140f16")
const PANEL_EDGE := Color("#3a2a3c")
const IRON := Color("#52515c")
const PORPHYRY := Color("#2d1a2e")
const PORPHYRY_LIGHT := Color("#4b2749")
const TEXT := Color("#eee5d3")
const IVORY := Color("#eee5d3")
const TEXT_DIM := Color("#a89d8c")
const RECORD := Color("#d3bea0")
const GOLD := Color("#b79555")
const FALSE_SUN := Color("#f2c35c")
const LUX := Color("#e0008f")
const SILVER := Color("#b8c4d0")
const BLOOD := Color("#a62639")
const ALERT := Color("#ff4d6d")
const GOOD := Color("#78bea7")
const LORE := Color("#b7aecf")

## Subtle accent hues for the Seven Spheres (Moon -> Saturn).
const SPHERE_ACCENTS := {
	1: Color("#b8c4d0"), ## Moon: Cold Silver / Ossuary Bone
	2: Color("#b79555"), ## Mercury: Brass & Verdigris
	3: Color("#c45b9a"), ## Venus: Porphyry & Gilded Choir
	4: Color("#f2c35c"), ## Sun: False Solar Gold
	5: Color("#b84b44"), ## Mars: Black Iron & Furnace Red
	6: Color("#9b6dd6"), ## Jupiter: Imperial Porphyry
	7: Color("#e0008f"), ## Saturn: Witness Magenta & Obsidian
}

const TILE_GLYPH := {
	Tiles.WALL: "#", Tiles.FLOOR: ".", Tiles.STAIRS_DOWN: ">", Tiles.STAIRS_UP: "<",
	Tiles.DOOR_SEALED: "+", Tiles.DOOR_OPEN: "'",
	Tiles.ASH_EMBER: "~", Tiles.RIME_ICE: "~", Tiles.MIASMA: "\"", Tiles.SOLAR_GLARE: "*",
	Tiles.BRANCH_IN: ">", Tiles.BRANCH_OUT: "<",
	Tiles.WATER_SHALLOW: "~", Tiles.SANCTUARY_FLOOR: ",", Tiles.IRON_GRATE: ":",
}
const TILE_COLOR := {
	Tiles.WALL: Color("#8a7a66"), Tiles.FLOOR: Color("#5a4e5e"), Tiles.STAIRS_DOWN: FALSE_SUN,
	Tiles.STAIRS_UP: RECORD, Tiles.DOOR_SEALED: ALERT, Tiles.DOOR_OPEN: GOOD,
	Tiles.ASH_EMBER: Color("#ff7a33"), Tiles.RIME_ICE: Color("#6ec6ff"),
	Tiles.MIASMA: Color("#8f7ae0"), Tiles.SOLAR_GLARE: FALSE_SUN,
	Tiles.BRANCH_IN: GOOD, Tiles.BRANCH_OUT: GOOD,
	Tiles.WATER_SHALLOW: Color("#5e7a99"), Tiles.SANCTUARY_FLOOR: Color("#6e8b82"),
	Tiles.IRON_GRATE: Color("#8c8c9c"),
}

## Message-log colours by World.log_msg kind.
const LOG_COLOR := {
	"info": TEXT_DIM, "combat": RECORD, "danger": ALERT, "good": GOOD, "lore": LORE,
}


## Explored-but-not-visible tiles: same hue, much darker, still legible.
static func remembered(c: Color) -> Color:
	return c.darkened(0.62)


static func remembered_hc(c: Color, high_contrast: bool) -> Color:
	return c.darkened(0.42 if high_contrast else 0.62)


## Maps functional roles to accessible palettes (0=Standard, 1=R/G Safe, 2=B/Y Safe).
static func color_for_mode(c: Color, role: String, color_mode: int = 0, high_contrast: bool = false) -> Color:
	var out := c
	if color_mode == 1:
		match role:
			"good", "friendly":
				out = Color("#6ec6ff")
			"danger", "hostile":
				out = Color("#ff8a3d")
			"miasma":
				out = Color("#b97aff")
	elif color_mode == 2:
		match role:
			"good", "friendly":
				out = Color("#7ef0e8")
			"danger", "hostile":
				out = Color("#ff4d6d")
			"miasma":
				out = Color("#e0008f")
			"gold", "stairs":
				out = Color("#ffe27a")
	if high_contrast:
		out = out.lightened(0.18)
	return out


static func log_color(kind: String) -> Color:
	return LOG_COLOR.get(kind, TEXT)
