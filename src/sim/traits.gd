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
}


static func is_known(id: String) -> bool:
	return KNOWN.has(id)


static func describe(id: String) -> String:
	return String(KNOWN.get(id, id))
