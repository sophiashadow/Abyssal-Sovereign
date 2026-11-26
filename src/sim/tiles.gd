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

const NAMES := {
	WALL: "wall", FLOOR: "floor", STAIRS_DOWN: "stairs down", STAIRS_UP: "stairs up",
	DOOR_SEALED: "the Unwritten Door (sealed)", DOOR_OPEN: "the Unwritten Door (open)",
}


static func is_walkable(t: int) -> bool:
	return t == FLOOR or t == STAIRS_DOWN or t == STAIRS_UP or t == DOOR_OPEN


static func is_transparent(t: int) -> bool:
	return t != WALL and t != DOOR_SEALED
