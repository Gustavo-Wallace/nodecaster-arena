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
		"effect_id": "slow",
		"effect_power": 0.72,
		"tags": ["control", "slow"],
		"modifiers_text": "Reduces target speed for 1.4s.",
	},
	"lightning": {
		"id": "lightning",
		"display_name": "Electric",
		"description": "Improves Chain Lightning propagation and speeds up Area Field pulses.",
		"primary_color": Color(1.0, 0.84, 0.18),
		"secondary_color": Color(1.0, 0.98, 0.7),
		"impact_color": Color(1.0, 0.92, 0.36),
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
		"effect_id": "direct",
		"effect_power": 0.0,
		"damage_multiplier": 1.12,
		"tags": ["direct", "shadow"],
		"modifiers_text": "+12% direct damage with a violet signature.",
	},
}


static func get_data(element_id: String) -> Dictionary:
	var resolved_id := element_id if ELEMENTS.has(element_id) else "arcane"
	return ELEMENTS[resolved_id].duplicate(true)


static func get_available() -> Array[Dictionary]:
	var elements: Array[Dictionary] = []
	for element_id in ["arcane", "fire", "ice", "lightning", "shadow"]:
		elements.append(get_data(element_id))
	return elements
