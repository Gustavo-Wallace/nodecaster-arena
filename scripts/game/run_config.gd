extends Node

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/ui/character_select.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"

var selected_character_id: String = "circle"

var characters := {
	"circle": {
		"id": "circle",
		"display_name": "Circulo",
		"profile": "Equilibrado",
		"description": "Forma estavel e versatil.",
		"max_health": 100,
		"move_speed": 320.0,
		"projectile_damage": 12,
		"projectile_speed": 520.0,
		"fire_interval": 0.45,
		"projectile_count": 1,
		"visual_shape": "circle",
		"fill_color": Color(0.18, 0.78, 1.0),
		"outline_color": Color(0.82, 0.98, 1.0),
	},
	"triangle": {
		"id": "triangle",
		"display_name": "Triangulo",
		"profile": "Rapido e ofensivo",
		"description": "Forma veloz, fragil e agressiva.",
		"max_health": 82,
		"move_speed": 380.0,
		"projectile_damage": 14,
		"projectile_speed": 560.0,
		"fire_interval": 0.39,
		"projectile_count": 1,
		"visual_shape": "triangle",
		"fill_color": Color(0.96, 0.46, 1.0),
		"outline_color": Color(1.0, 0.86, 1.0),
	},
	"square": {
		"id": "square",
		"display_name": "Quadrado",
		"profile": "Resistente",
		"description": "Forma solida, lenta e duravel.",
		"max_health": 135,
		"move_speed": 270.0,
		"projectile_damage": 12,
		"projectile_speed": 500.0,
		"fire_interval": 0.48,
		"projectile_count": 1,
		"visual_shape": "square",
		"fill_color": Color(0.36, 0.88, 0.54),
		"outline_color": Color(0.82, 1.0, 0.82),
	},
}


func select_character(character_id: String) -> void:
	if characters.has(character_id):
		selected_character_id = character_id


func get_selected_character_data() -> Dictionary:
	return get_character_data(selected_character_id)


func get_character_data(character_id: String) -> Dictionary:
	if not characters.has(character_id):
		return characters["circle"].duplicate(true)

	return characters[character_id].duplicate(true)


func get_character_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []

	for character_id in ["circle", "triangle", "square"]:
		list.append(get_character_data(character_id))

	return list
