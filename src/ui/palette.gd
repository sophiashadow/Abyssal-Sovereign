class_name Palette
extends RefCounted
## Colours shared by every screen. Derived from the FALSE LIGHT visual
## language (void, Lux magenta, record parchment, false-sun gold); see
## docs/LORE.md. Rendering only: the simulation never reads these.

const VOID := Color("#080609")
const PANEL := Color("#140f16")
const PANEL_EDGE := Color("#3a2a3c")
const TEXT := Color("#eee5d3")
const TEXT_DIM := Color("#a89d8c")
const RECORD := Color("#d3bea0")
const GOLD := Color("#b79555")
const FALSE_SUN := Color("#f2c35c")
const LUX := Color("#e0008f")
const ALERT := Color("#ff4d6d")
const GOOD := Color("#78bea7")
const LORE := Color("#b7aecf")

const TILE_GLYPH := {
	Tiles.WALL: "#", Tiles.FLOOR: ".", Tiles.STAIRS_DOWN: ">", Tiles.STAIRS_UP: "<",
	Tiles.DOOR_SEALED: "+", Tiles.DOOR_OPEN: "'",
}
const TILE_COLOR := {
	Tiles.WALL: Color("#8a7a66"), Tiles.FLOOR: Color("#5a4e5e"), Tiles.STAIRS_DOWN: FALSE_SUN,
	Tiles.STAIRS_UP: RECORD, Tiles.DOOR_SEALED: ALERT, Tiles.DOOR_OPEN: GOOD,
}

## Message-log colours by World.log_msg kind.
const LOG_COLOR := {
	"info": TEXT_DIM, "combat": RECORD, "danger": ALERT, "good": GOOD, "lore": LORE,
}


## Explored-but-not-visible tiles: same hue, much darker, still legible.
static func remembered(c: Color) -> Color:
	return c.darkened(0.62)


static func log_color(kind: String) -> Color:
	return LOG_COLOR.get(kind, TEXT)
