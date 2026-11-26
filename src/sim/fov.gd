class_name Fov
extends RefCounted
## Recursive shadowcasting over eight octants (the algorithm described by
## Bjorn Bergstrom on RogueBasin; this implementation is written for this
## project). Marks map.visible and adds to map.explored.

const MULT := [
	[1, 0, 0, -1, -1, 0, 0, 1],
	[0, 1, -1, 0, 0, -1, 1, 0],
	[0, 1, 1, 0, 0, -1, -1, 0],
	[1, 0, 0, 1, -1, 0, 0, -1],
]


static func compute(map: FloorMap, origin: Vector2i, radius: int) -> void:
	map.visible.fill(0)
	_mark(map, origin)
	for oct in 8:
		_cast(map, origin, radius, 1, 1.0, 0.0,
			MULT[0][oct], MULT[1][oct], MULT[2][oct], MULT[3][oct])


static func _mark(map: FloorMap, p: Vector2i) -> void:
	if map.in_bounds(p):
		var i := map.idx(p)
		map.visible[i] = 1
		map.explored[i] = 1


static func _cast(map: FloorMap, o: Vector2i, radius: int, row: int, start: float, end: float,
		xx: int, xy: int, yx: int, yy: int) -> void:
	if start < end:
		return
	var radius_sq := radius * radius
	var new_start := 0.0
	for j in range(row, radius + 1):
		var dx := -j - 1
		var dy := -j
		var blocked := false
		while dx <= 0:
			dx += 1
			var p := Vector2i(o.x + dx * xx + dy * xy, o.y + dx * yx + dy * yy)
			var l_slope := (dx - 0.5) / (dy + 0.5)
			var r_slope := (dx + 0.5) / (dy - 0.5)
			if start < r_slope:
				continue
			elif end > l_slope:
				break
			if dx * dx + dy * dy <= radius_sq:
				_mark(map, p)
			var opaque := not map.is_transparent(p)
			if blocked:
				if opaque:
					new_start = r_slope
					continue
				blocked = false
				start = new_start
			elif opaque and j < radius:
				blocked = true
				_cast(map, o, radius, j + 1, start, l_slope, xx, xy, yx, yy)
				new_start = r_slope
		if blocked:
			break
