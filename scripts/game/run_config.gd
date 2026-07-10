extends Node

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/ui/character_select.tscn"
const PROGRESS_SCENE := "res://scenes/ui/progress_screen.tscn"
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
	"diamond": {
		"id": "diamond",
		"display_name": "Losango",
		"profile": "Conjurador",
		"description": "Forma instavel especializada em poder arcano.",
		"max_health": 86,
		"move_speed": 320.0,
		"projectile_damage": 18,
		"projectile_speed": 620.0,
		"fire_interval": 0.50,
		"projectile_count": 1,
		"visual_shape": "diamond",
		"fill_color": Color(0.34, 0.92, 0.92),
		"outline_color": Color(0.9, 1.0, 1.0),
		"unlock_id": "character_diamond",
		"unlock_cost": 25,
	},
}


func select_character(character_id: String) -> void:
	if characters.has(character_id) and is_character_unlocked(character_id):
		selected_character_id = character_id


func get_selected_character_data() -> Dictionary:
	if not is_character_unlocked(selected_character_id):
		selected_character_id = "circle"

	return get_character_data(selected_character_id)


func get_character_data(character_id: String) -> Dictionary:
	if not characters.has(character_id):
		character_id = "circle"

	var character_data: Dictionary = characters[character_id].duplicate(true)
	character_data["unlocked"] = is_character_unlocked(character_id)
	return character_data


func get_character_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []

	for character_id in ["circle", "triangle", "square", "diamond"]:
		list.append(get_character_data(character_id))

	return list


func is_character_unlocked(character_id: String) -> bool:
	if character_id in ["circle", "triangle", "square"]:
		return true

	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return false

	return bool(save_manager.call("is_character_unlocked", character_id))
