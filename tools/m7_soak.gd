extends SceneTree
## M7.1 policy soak. One JSONL line per run; nothing leaves the machine.
##   godot --headless --path . --script res://tools/m7_soak.gd -- \
##     --set=dev --salt=m7dev --seeds=2 --policies=baseline,explorer --out=balance/raw/x.jsonl
##
## Options
##   --set=dev|validation   dev seeds may be reused freely; validation salts must be
##                          claimed once (--claim) in balance/validation_ledger.txt and
##                          are then spent: the tool refuses a dev run on a ledger salt.
##   --salt=NAME            seed namespace
##   --seeds=N --seed-from=K  seed indices K..K+N-1 (used for adaptive top-ups)
##   --policies=a,b         default: every policy in PolicyPlayer.POLICIES
##   --pairs=sp/cl,sp/cl    default: all 64 origin/calling pairs
##   --classes=a,b --species=a,b   filters
##   --shard=I/N            run only every Nth job (parallel processes)
##   --actions=N            override the action cap (default 4000, 20000 for explorer/narrative)
##   --out=PATH             append JSONL (default: print only)
##   --profile=ID           run profile (initiate|exile|adversary|sovereign; default exile). Seeds are
##                          independent of the profile, so profiles are same-seed A/B comparisons.
##   --claim                claim --salt in the ledger and exit
##   --list                 print the job count and exit
## The dungeon seed for a (pair, index) is identical across policies so policies
## are compared on the same worlds; the policy's own Rng is derived separately.

const LEDGER := "res://balance/validation_ledger.txt"
const SLOW_POLICIES: Array[String] = ["explorer", "narrative"]


func _init() -> void:
	var o := _parse()
	var db := ContentDB.load_default()
	if not db.is_valid():
		print("content invalid: ", db.errors)
		quit(2)
		return
	var ledger := _read_ledger()
	var salt := String(o["salt"])
	if o.has("claim"):
		if ledger.has(salt):
			print("salt already in ledger: ", salt)
			quit(3)
			return
		_append_ledger("%s|claimed|%s" % [salt, Time.get_datetime_string_from_system(true)])
		print("claimed validation salt: ", salt)
		quit(0)
		return
	var set_name := String(o["set"])
	if set_name == "validation" and String(ledger.get(salt, "")) != "claimed":
		print("validation salt not claimed (or historical): ", salt, " -> run with --claim first")
		quit(3)
		return
	if set_name == "dev" and ledger.has(salt):
		print("dev runs may not use a ledger salt: ", salt)
		quit(3)
		return
	var jobs: Array = []
	for sp in db.ids("species"):
		for cl in db.ids("classes"):
			var pair := "%s/%s" % [sp, cl]
			if not (o["pairs"] as Array).is_empty() and not (o["pairs"] as Array).has(pair):
				continue
			if not (o["species"] as Array).is_empty() and not (o["species"] as Array).has(sp):
				continue
			if not (o["classes"] as Array).is_empty() and not (o["classes"] as Array).has(cl):
				continue
			for pol in o["policies"]:
				for i in range(int(o["seed_from"]), int(o["seed_from"]) + int(o["seeds"])):
					jobs.append([sp, cl, pol, i])
	var shard_i := int(o["shard_i"])
	var shard_n := int(o["shard_n"])
	if o.has("list"):
		print("jobs: ", jobs.size())
		quit(0)
		return
	var f: FileAccess = null
	if String(o["out"]) != "":
		var path := String(o["out"])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
		f = FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
		if f == null:
			print("cannot open ", path)
			quit(2)
			return
		f.seek_end()
	var started := Time.get_ticks_msec()
	var done := 0
	for n in jobs.size():
		if n % shard_n != shard_i:
			continue
		var j: Array = jobs[n]
		var rec := run_one(db, String(j[0]), String(j[1]), String(j[2]), int(j[3]), set_name, salt, int(o["actions"]), String(o["profile"]))
		done += 1
		if f != null:
			f.store_line(JSON.stringify(rec))
			f.flush()
		else:
			print(JSON.stringify(rec))
	print("shard %d/%d: %d runs in %.1fs" % [shard_i, shard_n, done, float(Time.get_ticks_msec() - started) / 1000.0])
	quit(0)


## One run, returns a flat record. Also used by the tests.
static func run_one(db: ContentDB, sp: String, cl: String, policy: String, idx: int, set_name: String, salt: String, actions: int = 0, profile: String = "exile") -> Dictionary:
	var pair := "%s/%s" % [sp, cl]
	var seed_val := Rng.derive(idx, "%s:%s:%s" % [set_name, salt, pair])
	var w := World.new_run(db, seed_val, sp, cl, "Soak", profile)
	var tel := Telemetry.new()
	w.telemetry = tel
	var bot := PolicyPlayer.new(w, policy)
	var cap := actions if actions > 0 else (20000 if SLOW_POLICIES.has(policy) else 4000)
	var t0 := Time.get_ticks_msec()
	bot.play(cap)
	var branch_floors := 0
	for fid in w.visited_floors:
		if String(db.floor_def(fid).get("region_kind", "spine")) != "spine":
			branch_floors += 1
	var vic := String(w.victory_kind().get("id", "")) if w.state == World.State.WON else ""
	return {
		"set": set_name, "salt": salt, "pair": pair, "profile": w.difficulty, "species": sp, "calling": cl, "policy": policy, "idx": idx, "seed": seed_val,
		"state": ["playing", "dead", "won"][int(w.state)],
		"depth": w.depth, "level": w.player.level, "turns": w.turns, "actions_cap": cap, "ms": Time.get_ticks_msec() - t0,
		"cause": w.death_cause, "victory": vic,
		"floors": w.visited_floors.size(), "branch_floors": branch_floors, "max_sphere": w.max_sphere_reached,
		"npcs_met": w.npcs_met.size(), "threads_settled": w.resolved_thread_count(),
		"threads_seen": w.active_thread_ids().size() + w.resolved_thread_count() + (w.threads_state.get("refused", []) as Array).size(),
		"apotheosis": w.apotheosis, "serpent": w.way_serpent, "return": w.way_return, "subjugation": w.subjugation,
		"contract": w.contract, "contract_log": w.contract_log, "mask": String(w.player.mask), "talents": w.player.talents.size(),
		"factions": w.faction_flags,
		"tel": tel.to_dict(),
	}


func _parse() -> Dictionary:
	var o := {"set": "dev", "salt": "m7dev", "seeds": 1, "seed_from": 0, "policies": PolicyPlayer.POLICIES.duplicate(),
			"pairs": [], "species": [], "classes": [], "shard_i": 0, "shard_n": 1, "actions": 0, "out": "", "profile": "exile"}
	for arg in OS.get_cmdline_user_args():
		if arg == "--claim" or arg == "--list":
			o[arg.substr(2)] = true
		elif arg.begins_with("--") and arg.contains("="):
			var kv := arg.substr(2).split("=", true, 1)
			var k := String(kv[0])
			var v := String(kv[1])
			match k:
				"policies", "pairs", "species", "classes":
					o[k] = Array(v.split(",", false))
				"shard":
					var parts := v.split("/")
					o["shard_i"] = parts[0].to_int()
					o["shard_n"] = maxi(1, parts[1].to_int())
				"seed-from":
					o["seed_from"] = v.to_int()
				"seeds", "actions":
					o[k] = v.to_int()
				_:
					o[k] = v
	return o


func _read_ledger() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(LEDGER):
		return out
	for line in FileAccess.get_file_as_string(LEDGER).split("\n", false):
		if line.begins_with("#"):
			continue
		var parts := line.split("|")
		if parts.size() >= 2:
			out[parts[0]] = parts[1]
	return out


func _append_ledger(line: String) -> void:
	var f := FileAccess.open(LEDGER, FileAccess.READ_WRITE if FileAccess.file_exists(LEDGER) else FileAccess.WRITE)
	f.seek_end()
	f.store_line(line)
