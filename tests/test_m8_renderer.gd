extends TestCase
## M8.2 dual rendering architecture tests:
## - Tile vs glyph renderer modes never touch simulation state, turn count, or RNG.
## - Switching renderer/zoom/lighting/accessibility options consumes 0 turns.
## - Missing assets degrade gracefully with null / empty region and zero errors.


func _fingerprint(w: World) -> String:
	return "%d|%d|%d|%d|%s|%s" % [w.state, w.turns, w.depth, w.player.hp, w.floor_id, w.rng.get_state_string()]


func test_renderer_equivalence_and_zero_turn_switching() -> void:
	var reg := AssetRegistry.new()
	ok(reg.validate(db(), false).is_empty(), "vertical slice asset registry validates: %s" % str(reg.validate(db(), false)))
	ok(reg.validate_provenance().is_empty(), "vertical slice provenance validates: %s" % str(reg.validate_provenance()))

	var w_glyph := World.new_run(db(), 8808, "human", "occultist", "Equiv")
	var w_tiles := World.new_run(db(), 8808, "human", "occultist", "Equiv")
	var mv_g := MapView.new()
	mv_g.world = w_glyph
	mv_g.registry = reg
	mv_g.render_mode = "glyph"
	var mv_t := MapView.new()
	mv_t.world = w_tiles
	mv_t.registry = reg
	mv_t.render_mode = "tiles"

	# Switch presentation properties mid-run; 0 turns consumed, state unchanged.
	var before_fp := _fingerprint(w_tiles)
	mv_t.render_mode = "glyph"
	mv_t.camera_zoom = 1.5
	mv_t.integer_scale = false
	mv_t.decorative_lighting = false
	mv_t.color_mode = 1
	mv_t.high_contrast = true
	mv_t.render_mode = "tiles"
	eq(_fingerprint(w_tiles), before_fp, "presentation changes consume zero turns and leave RNG intact")

	AutoPlayer.new(w_glyph).play(150)
	AutoPlayer.new(w_tiles).play(150)
	eq(_fingerprint(w_glyph), _fingerprint(w_tiles), "glyph and tile modes produce identical simulation runs")
	eq(JSON.stringify(w_glyph.to_dict()), JSON.stringify(w_tiles.to_dict()), "glyph and tile modes produce byte-identical saves")
	mv_g.free()
	mv_t.free()


func test_effective_tile_px_integer_scaling() -> void:
	var mv := MapView.new()
	mv.tile_px = 32
	mv.camera_zoom = 1.0
	mv.integer_scale = true
	eq(mv.effective_tile_px(), 32, "1.0x at 32px -> 32px")
	mv.camera_zoom = 1.5
	eq(mv.effective_tile_px(), 48, "1.5x at 32px -> 48px")
	mv.camera_zoom = 2.0
	eq(mv.effective_tile_px(), 64, "2.0x at 32px -> 64px")
	mv.free()


func test_missing_assets_degrade_gracefully() -> void:
	var missing_reg := AssetRegistry.new("res://content/presentation/does_not_exist.json", "res://content/presentation/does_not_exist_prov.json")
	eq(missing_reg.get_atlas("no_such_atlas"), null, "missing atlas returns null cleanly")
	ok(missing_reg.tile_region(1, Tiles.FLOOR, 0).is_empty(), "missing tile region returns empty dict")
	ok(missing_reg.feature_region(1, "altar", false).is_empty(), "missing feature region returns empty dict")
	ok(missing_reg.emblem_region("no_such_emblem").is_empty(), "missing emblem returns empty dict")
	var w := World.new_run(db(), 101, "human", "fallen_knight", "Fallback")
	var mv := MapView.new()
	mv.world = w
	mv.registry = missing_reg
	mv.render_mode = "tiles"
	ok(mv.effective_tile_px() > 0, "MapView stays valid with empty registry fallback")
	mv.free()
