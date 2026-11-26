class_name Traits
extends RefCounted
## Named rules that content can attach to species and classes. The behaviour
## lives where the rule applies (combat.gd, world.gd); this registry is what
## the content validator checks against, so a typo in JSON is an error, not a
## silently inert trait.

const KNOWN := {
	"sneak_attack": "Attacks against an unaware enemy always hit and are far more likely to be critical.",
	"iron_oath": "+2 defense while below half health.",
	"soul_siphon": "Each kill restores 1 + will health.",
	"deathless": "Once per floor, a killing blow leaves you at 1 health instead.",
	"infernal_blood": "Your attacks ignore 1 point of the target's defense.",
	"mask_stances": "Wear the Masks as stances (Bare Face, Nyx, Eris, Lilith), switching for 1 turn.",
	"adaptable": "Starts with +1 attribute point and gains a bonus talent point at levels 3 and 6.",
	"cinder_born": "Immune to smoldering embers; burning mends +1 health per turn instead of searing, and fire attacks deal +1 damage.",
	"liminal_sight": "Immune to Monopolized Sight and automatically detects nearby hidden traps and secret doors.",
	"ledger_forged": "Immune to Pinned and gains +1 Subjugation threshold before becoming Entangled.",
	"unfiled": "Hostile attacks suffer -10% hit chance and unaware foes notice 20% less easily.",
	"penance_vigor": "Working a Relic or suffering a Chain restores +2 class resource and +1 health.",
	"bulwark_stance": "Waiting or braced reduces incoming ranged and special damage by 25% and grants +1 defense while Braced.",
	"steady_aim": "Ranged weapons and thrown projectiles gain +2 accuracy, +1 range, and ignore 1 defense.",
	"ritual_cadence": "Reading any scroll or using an altar, shrine, or ritual circle restores +4 Resonance and grants Braced.",
	"alchemical_potency": "Healing items and thrown flasks are +35% stronger, and Reckoning lasts 10 fewer turns.",
	"chain_binder": "Active talents that apply debuffs also reduce Subjugation by 1.",
}


static func is_known(id: String) -> bool:
	return KNOWN.has(id)


static func describe(id: String) -> String:
	return String(KNOWN.get(id, id))
