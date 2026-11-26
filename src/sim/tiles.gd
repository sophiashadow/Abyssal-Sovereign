class_name Tiles
extends RefCounted
## Terrain ids and their rules. Terrain carries simulation meaning (stairs,
## the sealed door), so it is defined in code; how it looks lives in the
## renderer's palette (src/ui/palette.gd).

const WALL := 0
const FLOOR := 1
const STAIRS_DOWN := 2
const STAIRS_UP := 3
const DOOR_SEALED := 4
const DOOR_OPEN := 5
const ASH_EMBER := 6
const RIME_ICE := 7
const MIASMA := 8
const SOLAR_GLARE := 9
const BRANCH_IN := 10
const BRANCH_OUT := 11
const WATER_SHALLOW := 12
const SANCTUARY_FLOOR := 13
const IRON_GRATE := 14

const NAMES := {
	WALL: "wall", FLOOR: "floor", STAIRS_DOWN: "stairs down", STAIRS_UP: "stairs up",
	DOOR_SEALED: "the Unwritten Door (sealed)", DOOR_OPEN: "the Unwritten Door (open)",
	ASH_EMBER: "smoldering embers", RIME_ICE: "ossuary rime",
	MIASMA: "abyssal miasma", SOLAR_GLARE: "false-sun glare",
	BRANCH_IN: "branch passage", BRANCH_OUT: "return passage",
	WATER_SHALLOW: "shallow cistern water", SANCTUARY_FLOOR: "sanctuary flagstones",
	IRON_GRATE: "iron grate",
}


static func is_walkable(t: int) -> bool:
	return t == FLOOR or t == STAIRS_DOWN or t == STAIRS_UP or t == DOOR_OPEN or is_hazard(t) or t >= BRANCH_IN


static func is_hazard(t: int) -> bool:
	return t >= ASH_EMBER and t <= SOLAR_GLARE


static func is_transparent(t: int) -> bool:
	return t != WALL and t != DOOR_SEALED
