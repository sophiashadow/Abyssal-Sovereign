class_name Grid
extends RefCounted
## Grid helpers shared by generation, FOV, pathing and AI.

const DIRS_8: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const DIRS_4: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


static func chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return a != b and chebyshev(a, b) == 1


static func sign_vec(v: Vector2i) -> Vector2i:
	return Vector2i(signi(v.x), signi(v.y))
