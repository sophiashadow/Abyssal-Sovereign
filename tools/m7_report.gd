extends SceneTree
## M7.1 aggregator. Reads m7_soak JSONL and writes a JSON summary plus a markdown table.
##   godot --headless --path . --script res://tools/m7_report.gd -- --in=balance/raw --filter=r1 --out=balance/r1
##   add --suspects to print the pairs that deserve more samples (adaptive sampling).
## Pure arithmetic over recorded runs: no simulation happens here.

const MIN_N := 4


func _init() -> void:
	var in_dir := "balance/raw"
	var filt := ""
	var out := ""
	var sus_only := false
	var set_filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			in_dir = arg.substr(5)
		elif arg.begins_with("--filter="):
			filt = arg.substr(9)
		elif arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg.begins_with("--set="):
			set_filter = arg.substr(6)
		elif arg == "--suspects":
			sus_only = true
	var runs := load_runs(in_dir, filt, set_filter)
	var db := ContentDB.load_default()
	var sm := summarize(runs, db)
	if sus_only:
		print(",".join(PackedStringArray(sm["suspects"])))
		quit(0)
		return
	if out != "":
		var f := FileAccess.open(out + "_summary.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(sm, "  ", true))
		f.close()
		var m := FileAccess.open(out + "_summary.md", FileAccess.WRITE)
		m.store_string(to_markdown(sm))
		m.close()
	print(to_markdown(sm))
	quit(0)


static func load_runs(dir: String, filt: String, set_filter: String = "") -> Array:
	var runs: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return runs
	var names := Array(d.get_files())
	names.sort()
	for fn in names:
		if not String(fn).ends_with(".jsonl") or (filt != "" and not String(fn).contains(filt)):
			continue
		for line in FileAccess.get_file_as_string(dir + "/" + fn).split("\n", false):
			var v: Variant = JSON.parse_string(line)
			if v is Dictionary and (set_filter == "" or String(v.get("set", "")) == set_filter):
				runs.append(v)
	return runs


static func _rate(w: int, n: int) -> float:
	return snappedf(float(w) / maxi(1, n), 0.001)


static func summarize(runs: Array, db: ContentDB) -> Dictionary:
	var by_pol := {}
	var by_cl_pol := {}
	var by_sp_pol := {}
	var by_pair := {}
	var deaths := {}
	var classes := {}
	var cause_depth := {}
	var cover := {}
	var victories := {}
	var durations := {}
	var killers_by_calling := {}
	var level_at_depth := {}
	for r in runs:
		var pol := String(r["policy"])
		var won := String(r["state"]) == "won"
		var dead := String(r["state"]) == "dead"
		_acc(by_pol, pol, won, dead, r)
		_acc(by_cl_pol, "%s|%s" % [r["calling"], pol], won, dead, r)
		_acc(by_sp_pol, "%s|%s" % [r["species"], pol], won, dead, r)
		if pol != "random":
			_acc(by_pair, String(r["pair"]), won, dead, r)
		if won:
			victories["%s|%s" % [pol, r["victory"]]] = int(victories.get("%s|%s" % [pol, r["victory"]], 0)) + 1
		var tel: Dictionary = r.get("tel", {})
		if dead and pol != "random":
			var key := "d%d %s" % [int(r["depth"]), String(r["cause"])]
			deaths[key] = int(deaths.get(key, 0)) + 1
			var dd: Dictionary = tel.get("death", {})
			var cls := String(dd.get("classification", "unknown"))
			classes[cls] = int(classes.get(cls, 0)) + 1
			var ck := "d%d" % int(r["depth"])
			cause_depth[ck] = int(cause_depth.get(ck, 0)) + 1
			var kc := "%s|%s" % [r["calling"], String(r["cause"])]
			killers_by_calling[kc] = int(killers_by_calling.get(kc, 0)) + 1
		if pol != "random":
			var seen_depth := {}
			for fl in tel.get("floor_log", []):
				var dd2 := int(fl["depth"])
				if not seen_depth.has(dd2):
					seen_depth[dd2] = true
					var lk := "%s|d%d" % [pol, dd2]
					if not level_at_depth.has(lk):
						level_at_depth[lk] = {"n": 0, "level": 0}
					level_at_depth[lk]["n"] += 1
					level_at_depth[lk]["level"] += int(fl["level"])
		var dk := pol
		if not durations.has(dk):
			durations[dk] = {"n": 0, "turns": 0}
		durations[dk]["n"] += 1
		durations[dk]["turns"] += int(r["turns"])
		for k in (tel.get("counters", {}) as Dictionary):
			cover[k] = int(cover.get(k, 0)) + int((tel["counters"] as Dictionary)[k])
	var suspects := _suspects(by_pair)
	var cov := _coverage(cover, db)
	return {
		"runs": runs.size(),
		"by_policy": _finish(by_pol), "by_calling_policy": _finish(by_cl_pol), "by_origin_policy": _finish(by_sp_pol),
		"by_pair_nonrandom": _finish(by_pair), "deaths": deaths, "death_classes": classes, "deaths_by_depth": cause_depth,
		"victories": victories, "coverage": cov, "killers_by_calling": killers_by_calling, "level_at_depth_entry": _mean_levels(level_at_depth), "suspects": suspects, "mean_turns": _means(durations),
	}


static func _mean_levels(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = snappedf(float(d[k]["level"]) / maxi(1, int(d[k]["n"])), 0.1)
	return out


static func _acc(d: Dictionary, k: String, won: bool, dead: bool, r: Dictionary) -> void:
	if not d.has(k):
		d[k] = {"n": 0, "won": 0, "dead": 0, "depth": 0, "level": 0, "turns": 0}
	var e: Dictionary = d[k]
	e["n"] += 1
	e["won"] += 1 if won else 0
	e["dead"] += 1 if dead else 0
	e["depth"] += int(r["depth"])
	e["level"] += int(r["level"])
	e["turns"] += int(r["turns"])


static func _finish(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		var e: Dictionary = d[k]
		var n := int(e["n"])
		out[k] = {"n": n, "won": e["won"], "win_rate": _rate(int(e["won"]), n), "dead": e["dead"],
				"mean_depth": snappedf(float(e["depth"]) / maxi(1, n), 0.01), "mean_level": snappedf(float(e["level"]) / maxi(1, n), 0.01),
				"mean_turns": int(float(e["turns"]) / maxi(1, n))}
	return out


static func _means(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = int(float(d[k]["turns"]) / maxi(1, int(d[k]["n"])))
	return out


## Pairs that sit well off the pooled win rate, or that never/always win with a
## usable sample, get extra seeds. Selection uses only recorded outcomes.
static func _suspects(by_pair: Dictionary) -> Array:
	var tn := 0
	var tw := 0
	for k in by_pair:
		tn += int(by_pair[k]["n"])
		tw += int(by_pair[k]["won"])
	var p := float(tw) / maxi(1, tn)
	var out: Array = []
	for k in by_pair:
		var n := int(by_pair[k]["n"])
		if n < MIN_N:
			continue
		var rate := float(by_pair[k]["won"]) / n
		var se := sqrt(maxf(0.0025, p * (1.0 - p)) / n)
		if absf(rate - p) > 2.0 * se or rate == 0.0 or rate == 1.0 and n >= 8:
			out.append(k)
	out.sort()
	return out


static func _coverage(c: Dictionary, db: ContentDB) -> Dictionary:
	var out := {}
	var talents := db.ids("talents")
	var learned := 0
	var used := 0
	for t in talents:
		learned += 1 if c.has("talent_learned|" + t) else 0
		used += 1 if c.has("talent_used|" + t) else 0
	out["talents_learned"] = "%d/%d" % [learned, talents.size()]
	out["talents_used"] = "%d/%d" % [used, talents.size()]
	var unused: Array = []
	for t in talents:
		if String(db.get_def("talents", t)["kind"]) == "active" and not c.has("talent_used|" + t):
			unused.append(t)
	out["active_talents_never_used"] = unused
	var mons := db.ids("monsters")
	var seen := 0
	var unseen: Array = []
	for m in mons:
		if c.has("kill|" + m) or c.has("boss_kill|" + m) or c.has("elite_kill|" + m):
			seen += 1
		else:
			unseen.append(m)
	out["monsters_killed"] = "%d/%d" % [seen, mons.size()]
	out["monsters_never_killed"] = unseen
	var floors := db.ids("floors")
	var fs := 0
	for f in floors:
		var start := String(db.floor_def(f).get("region_kind", "spine")) == "spine" and int(db.floor_def(f)["depth"]) == 1
		fs += 1 if c.has("floor_first|" + f) or start else 0
	out["floors_visited"] = "%d/%d" % [fs, floors.size()]
	var th := db.ids("threads")
	var acc := 0
	for t in th:
		acc += 1 if c.has("thread_accepted|" + t) else 0
	out["threads_accepted"] = "%d/%d" % [acc, th.size()]
	var tally := {}
	for k in c:
		var cat := String(k).get_slice("|", 0)
		if cat in ["thread_settled", "thread_refused", "thread_abandoned", "contract_signed", "contract_fulfilled", "contract_broken",
				"relic_worked", "relic_transmuted", "gate", "victory", "retreat", "branch", "interact", "consumable", "entangled", "narrative"]:
			tally[k] = c[k]
	out["optional_content"] = tally
	return out


static func to_markdown(sm: Dictionary) -> String:
	var s := "# M7 soak summary (%d runs)\n\n## Policies\n\n| policy | n | win | mean depth | mean level | mean turns |\n|---|---|---|---|---|---|\n" % int(sm["runs"])
	var bp: Dictionary = sm["by_policy"]
	for k in _sorted(bp):
		s += "| %s | %d | %.1f%% | %.2f | %.1f | %d |\n" % [k, bp[k]["n"], 100.0 * float(bp[k]["win_rate"]), bp[k]["mean_depth"], bp[k]["mean_level"], bp[k]["mean_turns"]]
	s += "\n## Calling x policy (win rate, n)\n\n"
	var callings := {}
	var pols := {}
	for k in sm["by_calling_policy"]:
		callings[String(k).get_slice("|", 0)] = true
		pols[String(k).get_slice("|", 1)] = true
	var pl := _sorted(pols)
	s += "| calling | " + " | ".join(PackedStringArray(pl)) + " |\n|---|" + "---|".repeat(pl.size()) + "\n"
	for c in _sorted(callings):
		var row := "| %s |" % c
		for p in pl:
			var e: Dictionary = sm["by_calling_policy"].get("%s|%s" % [c, p], {})
			row += " %s |" % ("-" if e.is_empty() else "%.0f%% (%d)" % [100.0 * float(e["win_rate"]), e["n"]])
		s += row + "\n"
	s += "\n## Deaths (non-random)\n\n"
	var dk: Array = sm["deaths"].keys()
	dk.sort_custom(func(a, b): return sm["deaths"][a] > sm["deaths"][b])
	for k in dk.slice(0, 20):
		s += "- %s: %d\n" % [k, sm["deaths"][k]]
	s += "\nClassification: %s\n\nDeaths by depth: %s\n" % [JSON.stringify(sm["death_classes"]), JSON.stringify(sm["deaths_by_depth"])]
	s += "\nVictories (policy|ending): %s\n" % JSON.stringify(sm["victories"])
	s += "\n## Coverage\n\n"
	for k in sm["coverage"]:
		if k != "optional_content" and k != "monsters_never_killed" and k != "active_talents_never_used":
			s += "- %s: %s\n" % [k, sm["coverage"][k]]
	s += "- monsters never killed: %s\n" % ", ".join(PackedStringArray(sm["coverage"]["monsters_never_killed"]))
	s += "- active talents never used: %s\n" % ", ".join(PackedStringArray(sm["coverage"]["active_talents_never_used"]))
	s += "\nMean level on first entry to each depth (policy|depth): %s\n" % JSON.stringify(sm["level_at_depth_entry"])
	s += "\nOptional-content counters: %s\n" % JSON.stringify(sm["coverage"]["optional_content"])
	s += "\nSuspect pairs (adaptive sampling): %s\n" % ", ".join(PackedStringArray(sm["suspects"]))
	return s


static func _sorted(d: Variant) -> Array:
	var k: Array = d.keys()
	k.sort()
	return k
