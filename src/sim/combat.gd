class_name Combat
extends RefCounted
## Melee resolution as a pure function of two actors and a random stream.
##   hit chance  = 70 + 5 * (accuracy - evasion), clamped to 5..95 (percent)
##   crit chance = attacker crit stat (base 5%), +50 for sneak_attack on an unaware target
##   damage      = weapon dice (+ a second roll on a crit) + damage_bonus - defense, minimum 1
## Damage type is recorded ("physical") so resistances can key off it later.

const BASE_HIT := 70
const HIT_PER_POINT := 5


static func hit_chance(attacker: Actor, defender: Actor) -> int:
	var pct := BASE_HIT + HIT_PER_POINT * (attacker.stat("accuracy") - defender.stat("evasion"))
	if defender.has_trait("unfiled"):
		pct -= 10
	return clampi(pct, 5, 95)


static func ranged_hit_chance(attacker: Actor, defender: Actor, dist: int, item_acc: int, dmg_type: String) -> int:
	var attr := attacker.stat("will") if dmg_type != "physical" else attacker.stat("agility")
	var acc := int(attacker.base.get("accuracy", 0)) + attr + item_acc - maxi(0, dist - 3)
	if attacker.has_trait("steady_aim"):
		acc += 2
	var pct := BASE_HIT + HIT_PER_POINT * (acc - defender.stat("evasion"))
	if defender.has_trait("unfiled"):
		pct -= 10
	return clampi(pct, 5, 95)


static func mitigate(raw: int, defender: Actor, dmg_type: String, pierce_def: int = 0) -> Dictionary:
	var amt := maxi(1, raw)
	if dmg_type == "physical":
		var def := maxi(0, defender.stat("defense") - pierce_def)
		amt = maxi(1, amt - def)
	var r := defender.resist(dmg_type)
	if r >= 100:
		return {"damage": 0, "resist": r}
	if r != 0:
		amt = maxi(1, int(roundf(float(amt) * float(100 - r) / 100.0)))
	return {"damage": amt, "resist": r}


static func resolve(attacker: Actor, defender: Actor, rng: Rng) -> Dictionary:
	var dtype := attacker.melee_damage_type()
	var result := {"hit": false, "crit": false, "damage": 0, "type": dtype, "resist": 0, "sneak": false}
	var sneak := attacker.has_trait("sneak_attack") and not defender.is_player and not defender.awake
	result["sneak"] = sneak
	if not sneak and rng.d100() > hit_chance(attacker, defender):
		return result
	result["hit"] = true
	var crit_pct := attacker.stat("crit") + (50 if sneak else 0)
	var exec_rank := attacker.talent_rank("executioners_vow")
	if exec_rank > 0 and defender.hp * 2 < defender.stat("max_hp"):
		crit_pct += 5 * exec_rank
	var crit := rng.d100() <= crit_pct
	result["crit"] = crit
	var dice := attacker.damage_dice()
	var raw := Dice.roll(dice, rng)
	if crit:
		raw += Dice.roll(dice, rng)
	raw += attacker.stat("damage_bonus")
	if sneak:
		raw += 2 * attacker.talent_rank("unseen_edge")
	if exec_rank > 0 and defender.hp * 2 < defender.stat("max_hp"):
		raw += 2 * exec_rank
	var wb_rank := attacker.talent_rank("ward_breaker")
	if wb_rank > 0 and (defender.tags.has("dominion") or defender.tags.has("guardian")):
		raw += 2 * wb_rank
	if dtype == "fire" and attacker.has_trait("cinder_born"):
		raw += 1
	var pierce := (1 if attacker.has_trait("infernal_blood") else 0) + (1 if attacker.has_trait("steady_aim") else 0)
	var mit := mitigate(raw, defender, dtype, pierce)
	result["damage"] = int(mit["damage"])
	result["resist"] = int(mit["resist"])
	return result


static func resolve_ranged(attacker: Actor, defender: Actor, dist: int, dice: String,
		item_acc: int, item_crit: int, dmg_type: String, rng: Rng) -> Dictionary:
	var result := {"hit": false, "crit": false, "damage": 0, "type": dmg_type, "resist": 0, "sneak": false}
	var sneak := attacker.has_trait("sneak_attack") and not defender.is_player and not defender.awake and dist <= 4
	result["sneak"] = sneak
	if not sneak and rng.d100() > ranged_hit_chance(attacker, defender, dist, item_acc, dmg_type):
		return result
	result["hit"] = true
	var crit_pct := attacker.stat("crit") + item_crit + (50 if sneak else 0)
	var exec_rank := attacker.talent_rank("executioners_vow")
	if exec_rank > 0 and defender.hp * 2 < defender.stat("max_hp"):
		crit_pct += 5 * exec_rank
	var crit := rng.d100() <= crit_pct
	result["crit"] = crit
	var raw := Dice.roll(dice, rng)
	if crit:
		raw += Dice.roll(dice, rng)
	raw += maxi(0, attacker.stat("will")) if dmg_type != "physical" else maxi(0, attacker.stat("agility") / 2)
	if sneak:
		raw += 2 * attacker.talent_rank("unseen_edge")
	if exec_rank > 0 and defender.hp * 2 < defender.stat("max_hp"):
		raw += 2 * exec_rank
	var wb_rank := attacker.talent_rank("ward_breaker")
	if wb_rank > 0 and (defender.tags.has("dominion") or defender.tags.has("guardian")):
		raw += 2 * wb_rank
	if dmg_type == "fire" and attacker.has_trait("cinder_born"):
		raw += 1
	var pierce := (1 if attacker.has_trait("infernal_blood") else 0) + (1 if attacker.has_trait("steady_aim") else 0)
	var mit := mitigate(raw, defender, dmg_type, pierce)
	result["damage"] = int(mit["damage"])
	result["resist"] = int(mit["resist"])
	return result
