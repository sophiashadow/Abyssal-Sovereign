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
	return clampi(BASE_HIT + HIT_PER_POINT * (attacker.stat("accuracy") - defender.stat("evasion")), 5, 95)


static func resolve(attacker: Actor, defender: Actor, rng: Rng) -> Dictionary:
	var result := {"hit": false, "crit": false, "damage": 0, "type": "physical", "sneak": false}
	var sneak := attacker.has_trait("sneak_attack") and not defender.is_player and not defender.awake
	result["sneak"] = sneak
	if not sneak and rng.d100() > hit_chance(attacker, defender):
		return result
	result["hit"] = true
	var crit_pct := attacker.stat("crit") + (50 if sneak else 0)
	var crit := rng.d100() <= crit_pct
	result["crit"] = crit
	var dice := attacker.damage_dice()
	var raw := Dice.roll(dice, rng)
	if crit:
		raw += Dice.roll(dice, rng)
	raw += attacker.stat("damage_bonus")
	var def := defender.stat("defense")
	if attacker.has_trait("infernal_blood"):
		def = maxi(0, def - 1)
	result["damage"] = maxi(1, raw - def)
	return result
