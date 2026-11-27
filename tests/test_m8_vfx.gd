extends TestCase
## M8.6 motion, VFX, and combat feedback tests:
## - World.events is never saved and never alters RNG/determinism.
## - reduced_motion & instant_actions suppress shakes, particles, glides, and flashes.
## - VfxLayer handles all event types cleanly and clears after stepping.


func test_world_events_not_saved_and_preserve_determinism() -> void:
	var a := World.new_run(db(), 6262, "human", "occultist", "VfxA")
	var b := World.new_run(db(), 6262, "human", "occultist", "VfxB")
	a.player_move(Vector2i(1, 0))
	b.player_move(Vector2i(1, 0))
	AutoPlayer.new(a).play(80)
	AutoPlayer.new(b).play(80)
	ok(a.event_serial > 0 and not a.events.is_empty(), "events emitted during play")
	var saved := a.to_dict()
	ok(not saved.has("events") and not saved.has("event_serial"), "events are never serialized in saves")
	eq(a.rng.get_state_string(), b.rng.get_state_string(), "RNG identical")


func test_vfx_layer_reduced_motion_and_instant_mode() -> void:
	var w := World.new_run(db(), 6363, "cambion", "fallen_knight", "Vfx")
	var vfx := VfxLayer.new()
	vfx.reduced_motion = true
	var evs: Array[Dictionary] = [
		{"serial": 1, "kind": "move", "actor_id": 1, "from": Vector2i(1, 1), "to": Vector2i(2, 1)},
		{"serial": 2, "kind": "melee_hit", "from": Vector2i(2, 1), "to": Vector2i(3, 1), "amount": 5, "dmg_type": "fire", "crit": true, "is_player": true},
		{"serial": 3, "kind": "trap_trigger", "pos": Vector2i(2, 1), "trap": "spike"},
		{"serial": 4, "kind": "relic_work", "pos": Vector2i(2, 1), "item_id": "confessors_glass"},
		{"serial": 5, "kind": "entangled", "pos": Vector2i(2, 1), "depth": 1},
		{"serial": 6, "kind": "damage", "pos": Vector2i(3, 1), "amount": 5, "dmg_type": "fire", "is_player": false},
	]
	var ser := vfx.consume_events(evs, 0, false)
	eq(ser, 6, "consumed all 6 events")
	eq(vfx.screen_shake_offset(), Vector2.ZERO, "reduced_motion suppresses shake")
	eq(vfx.particles.size(), 0, "reduced_motion suppresses particles")
	eq(vfx.actor_tile_offset(1), Vector2.ZERO, "reduced_motion suppresses glide offset")
	eq(vfx.flash_ttl, 0.0, "reduced_motion suppresses flash")
	ok(vfx.popups.size() >= 1, "floating text still informative under reduced motion")

	vfx.clear()
	vfx.reduced_motion = false
	vfx.instant_actions = true
	vfx.consume_events(evs, 0, false)
	ok(not vfx.has_active(), "instant_actions skips all animations")

	vfx.instant_actions = false
	vfx.consume_events(evs, 0, false)
	ok(vfx.has_active(), "normal mode schedules animations")
	for _i in 20:
		vfx.step(0.05)
	ok(not vfx.has_active(), "all animations expire cleanly within 1s")
