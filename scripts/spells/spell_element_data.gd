class_name SpellElementData
extends RefCounted

const ELEMENTS := {
	"arcane": {
		"id": "arcane",
		"display_name": "Arcane",
		"description": "Pure direct energy with no additional status effect.",
		"primary_color": Color(0.77, 0.36, 1.0),
		"secondary_color": Color(1.0, 0.78, 1.0),
		"impact_color": Color(0.96, 0.48, 1.0),
		"short_summary": "Pure direct energy.",
		"strengths": "Clean, reliable direct impact.",
		"weaknesses": "No status effect.",
		"scaling_keywords": "direct damage, impact, arcane",
		"preview_id": "arcane",
		"available": true,
		"effect_id": "direct",
		"effect_power": 0.0,
		"tags": ["direct", "arcane"],
		"modifiers_text": "Direct damage with a magenta signature.",
	},
	"fire": {
		"id": "fire",
		"display_name": "Fire",
		"description": "Burns enemies briefly after impact.",
		"primary_color": Color(1.0, 0.3, 0.12),
		"secondary_color": Color(1.0, 0.78, 0.22),
		"impact_color": Color(1.0, 0.48, 0.12),
		"short_summary": "Burns enemies over time.",
		"strengths": "Adds persistent damage after impact.",
		"weaknesses": "Needs time to realize full damage.",
		"scaling_keywords": "burn, duration, damage over time",
		"preview_id": "fire",
		"available": true,
		"effect_id": "burn",
		"effect_power": 0.22,
		"tags": ["damage", "burn"],
		"modifiers_text": "Applies a light burn for 1.8s.",
	},
	"ice": {
		"id": "ice",
		"display_name": "Ice",
		"description": "Chills enemies and slows them briefly.",
		"primary_color": Color(0.28, 0.72, 1.0),
		"secondary_color": Color(0.8, 0.98, 1.0),
		"impact_color": Color(0.46, 0.88, 1.0),
		"short_summary": "Slows enemies.",
		"strengths": "Creates room through crowd control.",
		"weaknesses": "Lower direct pressure.",
		"scaling_keywords": "slow, duration, control",
		"preview_id": "ice",
		"available": true,
		"effect_id": "slow",
		"effect_power": 0.72,
		"tags": ["control", "slow"],
		"modifiers_text": "Reduces target speed for 1.4s.",
	},
	"electric": {
		"id": "electric",
		"display_name": "Electric",
		"description": "Improves Chain Lightning propagation and speeds up Area Field pulses.",
		"primary_color": Color(1.0, 0.84, 0.18),
		"secondary_color": Color(1.0, 0.98, 0.7),
		"impact_color": Color(1.0, 0.92, 0.36),
		"short_summary": "Sparks and chains energy.",
		"strengths": "Enhances chain links and field pulses.",
		"weaknesses": "No persistent status effect.",
		"scaling_keywords": "chains, pulses, propagation",
		"preview_id": "electric",
		"available": true,
		"effect_id": "direct",
		"effect_power": 0.0,
		"tags": ["direct", "electric"],
		"modifiers_text": "+1 Chain Lightning jump and -16% Area Field pulse interval.",
	},
	"shadow": {
		"id": "shadow",
		"display_name": "Shadow",
		"description": "Dark energy with a stronger direct impact.",
		"primary_color": Color(0.16, 0.1, 0.28),
		"secondary_color": Color(0.7, 0.36, 1.0),
		"impact_color": Color(0.56, 0.24, 0.92),
		"short_summary": "Amplifies direct impact.",
		"strengths": "Higher direct damage output.",
		"weaknesses": "No control effect.",
		"scaling_keywords": "direct damage, burst, shadow",
		"preview_id": "shadow",
		"available": true,
		"effect_id": "direct",
		"effect_power": 0.0,
		"damage_multiplier": 1.12,
		"tags": ["direct", "shadow"],
		"modifiers_text": "+12% direct damage with a violet signature.",
	},
	"poison": {
		"id": "poison",
		"display_name": "Poison",
		"description": "Future Element for corrosive damage patterns.",
		"short_summary": "Corrosive damage over time.",
		"primary_color": Color(0.42, 0.94, 0.28),
		"secondary_color": Color(0.76, 1.0, 0.5),
		"impact_color": Color(0.52, 1.0, 0.34),
		"available": false,
		"coming_soon": true,
		"strengths": "Future corrosive damage over time.",
		"weaknesses": "Not available yet.",
		"scaling_keywords": "poison, duration, corrosion",
		"preview_id": "generic",
	},
	"gravity": {
		"id": "gravity",
		"display_name": "Gravity",
		"description": "Future Element for spatial control.",
		"short_summary": "Dense spatial control.",
		"primary_color": Color(0.56, 0.42, 1.0),
		"secondary_color": Color(0.82, 0.74, 1.0),
		"impact_color": Color(0.66, 0.54, 1.0),
		"available": false,
		"coming_soon": true,
		"strengths": "Future spatial control.",
		"weaknesses": "Not available yet.",
		"scaling_keywords": "pull, radius, control",
		"preview_id": "generic",
	},
	"crystal": {
		"id": "crystal",
		"display_name": "Crystal",
		"description": "Future Element for refractive patterns.",
		"short_summary": "Refractive crystalline energy.",
		"primary_color": Color(0.2, 0.94, 0.86),
		"secondary_color": Color(0.74, 1.0, 0.96),
		"impact_color": Color(0.38, 1.0, 0.9),
		"available": false,
		"coming_soon": true,
		"strengths": "Future refractive spell effects.",
		"weaknesses": "Not available yet.",
		"scaling_keywords": "shards, ricochet, refraction",
		"preview_id": "generic",
	},
	"void": {
		"id": "void",
		"display_name": "Void",
		"description": "Future Element for entropy patterns.",
		"short_summary": "Unstable void energy.",
		"primary_color": Color(0.16, 0.04, 0.3),
		"secondary_color": Color(0.76, 0.28, 1.0),
		"impact_color": Color(0.56, 0.16, 0.94),
		"available": false,
		"coming_soon": true,
		"strengths": "Future entropy and burst effects.",
		"weaknesses": "Not available yet.",
		"scaling_keywords": "collapse, duration, entropy",
		"preview_id": "generic",
	},
}


const LEGACY_ELEMENT_ALIASES := {
	"lightning": "electric",
}


static func resolve_id(element_id: String) -> String:
	var resolved_id: String = str(LEGACY_ELEMENT_ALIASES.get(element_id, element_id))
	return resolved_id if ELEMENTS.has(resolved_id) else "arcane"


static func get_data(element_id: String) -> Dictionary:
	var resolved_id := resolve_id(element_id)
	return ELEMENTS[resolved_id].duplicate(true)


static func get_available() -> Array[Dictionary]:
	var elements: Array[Dictionary] = []
	for element_id in ["arcane", "fire", "ice", "electric", "shadow", "poison", "gravity", "crystal", "void"]:
		elements.append(get_data(element_id))
	return elements
