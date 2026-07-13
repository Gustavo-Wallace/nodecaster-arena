class_name SpellShapeData
extends RefCounted

const SHAPES := {
	"circle": {
		"id": "circle",
		"display_name": "Circulo",
		"description": "Forma estavel e versatil.",
		"visual_shape": "circle",
		"base_color": Color(0.72, 0.48, 1.0),
		"damage_multiplier": 1.0,
		"projectile_speed_multiplier": 1.0,
		"fire_interval_multiplier": 1.0,
		"size_multiplier": 1.0,
		"pierce_bonus": 0,
		"duration_multiplier": 1.0,
		"area_multiplier": 1.0,
		"chain_range_multiplier": 1.0,
		"chain_jump_range_multiplier": 1.0,
		"chain_visual_width_multiplier": 1.0,
		"area_size_multiplier": 1.0,
		"area_duration_multiplier": 1.0,
		"area_tick_interval_multiplier": 1.0,
		"area_damage_multiplier": 1.0,
		"modifiers_text": "Equilibrado em dano, velocidade e tamanho.",
	},
	"triangle": {
		"id": "triangle",
		"display_name": "Triangulo",
		"description": "Forma veloz e precisa.",
		"visual_shape": "triangle",
		"base_color": Color(1.0, 0.52, 0.38),
		"damage_multiplier": 0.92,
		"projectile_speed_multiplier": 1.28,
		"fire_interval_multiplier": 0.94,
		"size_multiplier": 0.86,
		"pierce_bonus": 0,
		"duration_multiplier": 1.0,
		"area_multiplier": 0.9,
		"chain_range_multiplier": 1.16,
		"chain_jump_range_multiplier": 1.08,
		"chain_visual_width_multiplier": 0.82,
		"area_size_multiplier": 0.84,
		"area_duration_multiplier": 0.9,
		"area_tick_interval_multiplier": 0.82,
		"area_damage_multiplier": 1.16,
		"modifiers_text": "+28% velocidade, -8% dano, projeteis menores.",
	},
	"square": {
		"id": "square",
		"display_name": "Quadrado",
		"description": "Forma densa e impactante.",
		"visual_shape": "square",
		"base_color": Color(0.42, 0.88, 0.64),
		"damage_multiplier": 1.28,
		"projectile_speed_multiplier": 0.8,
		"fire_interval_multiplier": 1.1,
		"size_multiplier": 1.32,
		"pierce_bonus": 0,
		"duration_multiplier": 1.12,
		"area_multiplier": 1.2,
		"chain_range_multiplier": 0.9,
		"chain_jump_range_multiplier": 0.84,
		"chain_visual_width_multiplier": 1.3,
		"area_size_multiplier": 1.26,
		"area_duration_multiplier": 1.16,
		"area_tick_interval_multiplier": 1.12,
		"area_damage_multiplier": 1.1,
		"modifiers_text": "+28% dano, projeteis maiores e mais lentos.",
	},
	"star": {
		"id": "star",
		"display_name": "Estrela",
		"description": "Forma reservada para futuras matrizes.",
		"visual_shape": "star",
		"available": false,
	},
	"pentagon": {
		"id": "pentagon",
		"display_name": "Pentagono",
		"description": "Forma reservada para futuras matrizes.",
		"visual_shape": "pentagon",
		"available": false,
	},
}


static func get_data(shape_id: String) -> Dictionary:
	var resolved_id := shape_id if SHAPES.has(shape_id) else "circle"
	return SHAPES[resolved_id].duplicate(true)


static func get_available() -> Array[Dictionary]:
	var shapes: Array[Dictionary] = []
	for shape_id in ["circle", "triangle", "square"]:
		shapes.append(get_data(shape_id))
	return shapes
