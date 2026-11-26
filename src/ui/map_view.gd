class_name MapView
extends Control
## Draws the current floor as glyphs, centred on the player, and turns taps
## into map coordinates. Short tap = tile_tapped; long press or right click =
## tile_inspected. Nothing depends on hover, so touch and mouse behave alike.

signal tile_tapped(pos: Vector2i)
signal tile_inspected(pos: Vector2i)

const LONG_PRESS_SEC := 0.45

var world: World
var tile_px: int = 24
## Highlighted tile (look mode, travel target); (-1, -1) for none.
var marker := Vector2i(-1, -1)
var _font: Font
var _press_at := -1.0
var _press_pos := Vector2.ZERO


func _ready() -> void:
	_font = ThemeDB.fallback_font
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func _process(_delta: float) -> void:
	# A held press turns into an inspect without waiting for release.
	if _press_at >= 0.0 and Time.get_ticks_msec() / 1000.0 - _press_at >= LONG_PRESS_SEC:
		_press_at = -1.0
		tile_inspected.emit(screen_to_tile(_press_pos))


func _origin() -> Vector2i:
	## Map tile drawn at the top-left cell.
	var cols := int(size.x / tile_px)
	var rows := int(size.y / tile_px)
	if world == null:
		return Vector2i.ZERO
	return world.player.pos - Vector2i(cols / 2, rows / 2)


func _offset() -> Vector2:
	## Centres the grid of whole cells inside the control.
	var cols := int(size.x / tile_px)
	var rows := int(size.y / tile_px)
	return Vector2((size.x - cols * tile_px) / 2.0, (size.y - rows * tile_px) / 2.0)


func screen_to_tile(p: Vector2) -> Vector2i:
	var local := p - _offset()
	return _origin() + Vector2i(floori(local.x / tile_px), floori(local.y / tile_px))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			tile_inspected.emit(screen_to_tile(mb.position))
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press_at = Time.get_ticks_msec() / 1000.0
				_press_pos = mb.position
			elif _press_at >= 0.0:
				_press_at = -1.0
				tile_tapped.emit(screen_to_tile(mb.position))
			accept_event()
	elif event is InputEventMouseMotion and _press_at >= 0.0:
		# Dragging cancels a pending press so a scroll is not read as a tap.
		if (event as InputEventMouseMotion).position.distance_to(_press_pos) > tile_px:
			_press_at = -1.0


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.VOID)
	if world == null:
		return
	var m := world.current_floor()
	var cols := int(size.x / tile_px)
	var rows := int(size.y / tile_px)
	var o := _origin()
	var off := _offset()
	var fsize := int(tile_px * 0.82)
	var items := {}
	for it in m.items:
		items[it.pos] = it
	var actors := {}
	for a in m.actors:
		if a.is_alive():
			actors[a.pos] = a
	for cy in rows:
		for cx in cols:
			var p := o + Vector2i(cx, cy)
			if not m.in_bounds(p) or not m.is_explored(p):
				continue
			var vis := m.is_visible(p)
			var glyph := String(Palette.TILE_GLYPH[m.get_tile(p)])
			var col: Color = Palette.TILE_COLOR[m.get_tile(p)]
			if vis and actors.has(p):
				var a: Actor = actors[p]
				glyph = a.glyph
				col = Color(a.color)
			elif items.has(p):
				var it: Item = items[p]
				var d := it.def(world.db)
				glyph = String(d["glyph"])
				col = Color(String(d["color"]))
			if not vis:
				col = Palette.remembered(col)
			var cell := off + Vector2(cx * tile_px, cy * tile_px)
			if vis and actors.has(p) and actors[p] != world.player:
				draw_rect(Rect2(cell, Vector2(tile_px, tile_px)), Color(col, 0.16))
			_glyph(cell, glyph, col, fsize)
	if m.in_bounds(marker):
		var mc := off + Vector2(marker - o) * tile_px
		draw_rect(Rect2(mc, Vector2(tile_px, tile_px)), Palette.FALSE_SUN, false, 2.0)


func _glyph(cell: Vector2, glyph: String, col: Color, fsize: int) -> void:
	var sz := _font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var asc := _font.get_ascent(fsize)
	var desc := _font.get_descent(fsize)
	var pos := cell + Vector2((tile_px - sz.x) / 2.0, (tile_px - (asc + desc)) / 2.0 + asc)
	draw_string(_font, pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
