class_name Hints
extends RefCounted
## M7.8 optional onboarding. Hints are read-only advice computed from the world
## state: they never change it, never consume randomness, never gate a command
## and are never saved with a run. Each is shown once (the UI remembers which in
## its settings file) and all of them can be switched off.
##
## Calling advice comes from content (`signature_tree` in classes.json) and says
## where to start, not what is strongest. The evidence behind it is bot play: a
## policy that learned the signature tree won far more often as Ophite Binder
## and Rite Cantor than generic play did (docs/M7 findings); no human claim.

const ORDER: Array[String] = ["calling", "elite", "unknown_item", "rest", "explore"]


## Talent id to learn first in the calling's signature tree: the lowest tier,
## actives before passives, then id. "" when the calling names no tree.
static func first_talent(db: ContentDB, class_id: String) -> String:
	var tree := String(db.get_def("classes", class_id).get("signature_tree", ""))
	if tree == "":
		return ""
	var best := ""
	var best_key := 1 << 30
	for tid in db.ids("talents"):
		var t := db.get_def("talents", tid)
		if String(t.get("class_id", "")) != class_id or String(t.get("tree", "")) != tree:
			continue
		var key := int(t.get("tier", 1)) * 10 + (0 if String(t.get("kind", "")) == "active" else 1)
		if key < best_key:
			best_key = key
			best = tid
	return best


static func calling_text(db: ContentDB, class_id: String) -> String:
	var tid := first_talent(db, class_id)
	if tid == "":
		return ""
	var t := db.get_def("talents", tid)
	return "Your calling is built around %s. Open Build and learn %s first: %s" % [
		String(t["tree"]), String(t["name"]), String(t.get("description", ""))]


## The first applicable hint not yet in `seen`, as {"id", "text"}; {} for none.
static func next(w: World, seen: Dictionary) -> Dictionary:
	if w == null or w.state != World.State.PLAYING:
		return {}
	for hid in ORDER:
		if seen.has(hid):
			continue
		var text := _text_if_due(w, hid)
		if text != "":
			return {"id": hid, "text": text}
	return {}


static func _text_if_due(w: World, hid: String) -> String:
	var calm := w.visible_hostiles().is_empty()
	match hid:
		"calling":
			if w.player.talent_points > 0 and calm and _no_talents(w.player):
				return calling_text(w.db, w.player.class_id)
		"elite":
			for a in w.visible_hostiles():
				if a.is_elite:
					return "An [Elite] carries a modifier named in its title. Look at it (inspect) before committing; you can retreat to stairs and rest."
		"unknown_item":
			if calm:
				for it in w.player.inventory:
					if not w.is_item_identified(it):
						return "Unidentified gear hides its numbers and can be cursed. A scroll of identify, or a shrine, reveals them. Comparison appears once an item is known."
		"rest":
			if calm and w.player.hp * 100 < w.player.stat("max_hp") * 70 and w.can_rest():
				return "Rest recovers health and stops if something appears or hurts you. Bleeding and burning need a cure or water, not rest."
		"explore":
			if calm and w.turns >= 20 and Assist.stop_reason(w) == "":
				return "Auto-explore walks ground you can see and stops for foes, traps, hazards and anything worth a decision. Any key interrupts it."
	return ""


static func _no_talents(a: Actor) -> bool:
	for tid in a.talents:
		if int(a.talents[tid]) > 0:
			return false
	return true
