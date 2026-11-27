extends TestCase
## M9.1 / M9.3 / M9.5 polish regression tests:
## - AssetRegistry lookup caching matches uncached lookups and clears cleanly.
## - VfxLayer melee lunge respects reduced_motion and instant_actions.
## - Simulation determinism and SAVE_VERSION 12 stay untouched.


func test_asset_registry_cache_parity_and_clear() -> void:
	var reg := AssetRegistry.new()
	var r1 := reg.tile_region(1, Tiles.FLOOR, 2)
	var r2 := reg.tile_region(1, Tiles.FLOOR, 2)
	ok(not r1.is_empty(), "cached tile region resolves")
	eq(r1["rect"], r2["rect"], "cached rect matches")
	eq(String(r1["atlas"]), String(r2["atlas"]), "cached atlas matches")
	var e1 := reg.emblem_region("title_crest")
	var e2 := reg.emblem_region("title_crest")
	eq(e1["rect"], e2["rect"], "cached emblem matches")
	reg.clear_cache()
	var r3 := reg.tile_region(1, Tiles.FLOOR, 2)
	eq(r1["rect"], r3["rect"], "re-resolves identically after cache clear")


func test_vfx_melee_lunge_and_accessibility_flags() -> void:
	var vfx := VfxLayer.new()
	var evs: Array[Dictionary] = [
		{"serial": 1, "kind": "melee_hit", "actor_id": 7, "from": Vector2i(2, 2), "to": Vector2i(3, 2), "amount": 4, "dmg_type": "physical", "crit": false, "is_player": true},
	]
	vfx.consume_events(evs, 0, false)
	ok(vfx.lunges.has(7), "melee_hit schedules lunge for attacker")
	vfx.step(0.04)
	ok(vfx.actor_tile_offset(7).x > 0.0, "lunge offsets attacker toward target")
	for _i in 6:
		vfx.step(0.05)
	ok(not vfx.lunges.has(7), "lunge expires cleanly")

	vfx.clear()
	vfx.reduced_motion = true
	vfx.consume_events(evs, 0, false)
	ok(not vfx.lunges.has(7), "reduced_motion suppresses melee lunge")

	vfx.clear()
	vfx.reduced_motion = false
	vfx.instant_actions = true
	vfx.consume_events(evs, 0, false)
	ok(not vfx.lunges.has(7), "instant_actions suppresses melee lunge")


func test_world_save_version_and_determinism_preserved() -> void:
	eq(World.SAVE_VERSION, 12, "SAVE_VERSION remains 12")
	var a := World.new_run(db(), 9393, "human", "fallen_knight", "PolA")
	var b := World.new_run(db(), 9393, "human", "fallen_knight", "PolB")
	AutoPlayer.new(a).play(60)
	AutoPlayer.new(b).play(60)
	eq(a.rng.get_state_string(), b.rng.get_state_string(), "RNG invariant")


func test_audio_unpause_preserves_zero_master_mute() -> void:
	var am := AudioManager.new()
	am.ensure_buses()
	var gs := GameSettings.new()
	gs.audio_enabled = true
	gs.vol_master = 0.0
	am.apply_settings(gs)
	var midx := AudioServer.get_bus_index("Master")
	ok(AudioServer.is_bus_mute(midx), "Master muted when vol_master is 0")
	am.set_paused(true)
	am.set_paused(false)
	ok(AudioServer.is_bus_mute(midx), "unpausing preserves zero-volume Master mute")
	gs.vol_master = 0.85
	am.apply_settings(gs)
	ok(not AudioServer.is_bus_mute(midx), "Master unmutes when vol_master restored")
	am.free()
