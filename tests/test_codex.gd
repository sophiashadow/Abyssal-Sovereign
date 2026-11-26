extends TestCase
## M6.8 Discovery, Codex and Run History:
## Knowledge-only cross-run catalog, zero-spoiler gating for unseen entries,
## atomic CodexIO persistence separate from SaveIO, run history, and zero RNG/World coupling.

const TEST_PATH := "user://test_codex_m68.json"


func test_codex_discovery_zero_spoilers_and_persistence() -> void:
	CodexIO.delete(TEST_PATH)
	var c := Codex.new()
	var w := World.new_run(db(), 6801, "human", "occultist", "Archivist")
	c.record_from_world(w)
	# Only starting/visited floor and identified starting items appear; unvisited floors remain absent.
	ok(c.floors.has("ossuary_warrens"), "starting floor recorded")
	ok(not c.floors.has("sealed_stair"), "unvisited Sphere 7 floor is not spoiled")
	ok(c.items.has("healing_salve"), "identified starting item recorded")
	ok(not c.items.has("marrow_cordial"), "unseen consumable not spoiled")

	# Interact with NPC or mark thread/victory to test run history + atomic save/load.
	w.player_learn_talent("gaze_of_lilith")
	w.threads_state["pool"] = ["unfiled_census_leaf"]
	w.discover_thread("unfiled_census_leaf")
	w.resolve_thread("unfiled_census_leaf", "sacrifice")
	w.state = World.State.WON
	c.record_run_end(w)
	eq(c.runs.size(), 1, "completed run appended to history")
	eq(String(c.runs[0]["outcome"]), "victory", "victory outcome recorded")
	eq(String(c.threads.get("unfiled_census_leaf", "")), "settled", "settled thread recorded")

	# Save atomically to CodexIO and reload cleanly.
	eq(CodexIO.save(c, TEST_PATH), OK, "CodexIO saved atomically")
	var loaded := CodexIO.load_codex(TEST_PATH)
	ok(loaded.floors.has("ossuary_warrens"), "loaded floor discovery preserved")
	eq(loaded.runs.size(), 1, "loaded run history preserved")
	eq(String(loaded.runs[0]["hero"]), "Archivist", "loaded hero name preserved")

	# Corrupt JSON falls back safely to empty Codex instead of crashing.
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("{corrupt")
	f.close()
	var fallback := CodexIO.load_codex(TEST_PATH)
	eq(fallback.runs.size(), 0, "corrupt codex falls back cleanly")
	CodexIO.delete(TEST_PATH)
	ok(not FileAccess.file_exists(TEST_PATH), "temp test codex cleaned up")
