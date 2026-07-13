extends Node

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/ui/character_select.tscn"
const SPELL_CRAFTING_SCENE := "res://scenes/ui/spell_crafting_menu.tscn"
const PROGRESS_SCENE := "res://scenes/ui/echo_skill_tree.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
const SPELL_BLUEPRINT_SCRIPT := preload("res://scripts/spells/spell_blueprint.gd")
const SPELL_SHAPE_DATA := preload("res://scripts/spells/spell_shape_data.gd")
const SPELL_ELEMENT_DATA := preload("res://scripts/spells/spell_element_data.gd")
const SPELL_DELIVERY_DATA := preload("res://scripts/spells/spell_delivery_data.gd")

var selected_character_id: String = "circle"
var selected_spell_shape_id: String = "circle"
var selected_spell_element_id: String = "arcane"
var selected_spell_delivery_id: String = "simple_projectile"

var characters := {
	"circle": {
		"id": "circle",
		"display_name": "Circle",
		"profile": "Balanced",
		"description": "A stable and versatile form.",
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
		"display_name": "Triangle",
		"profile": "Fast and offensive",
		"description": "A fast, fragile, and aggressive form.",
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
		"display_name": "Square",
		"profile": "Resilient",
		"description": "A solid, slow, and durable form.",
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
		"display_name": "Diamond",
		"profile": "Caster",
		"description": "An unstable form specialized in arcane power.",
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


func select_spell_shape(shape_id: String) -> void:
	selected_spell_shape_id = str(SPELL_SHAPE_DATA.get_data(shape_id).get("id", "circle"))


func select_spell_element(element_id: String) -> void:
	selected_spell_element_id = str(SPELL_ELEMENT_DATA.get_data(element_id).get("id", "arcane"))


func select_spell_delivery(delivery_id: String) -> void:
	var delivery_data: Dictionary = SPELL_DELIVERY_DATA.get_data(delivery_id)
	if bool(delivery_data.get("available", false)):
		selected_spell_delivery_id = str(delivery_data.get("id", "simple_projectile"))


func get_spell_blueprint():
	return SPELL_BLUEPRINT_SCRIPT.new(selected_spell_shape_id, selected_spell_element_id, selected_spell_delivery_id)


func get_spell_shape_list() -> Array[Dictionary]:
	return SPELL_SHAPE_DATA.get_available()


func get_spell_element_list() -> Array[Dictionary]:
	return SPELL_ELEMENT_DATA.get_available()


func get_spell_delivery_list() -> Array[Dictionary]:
	return SPELL_DELIVERY_DATA.get_all()


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
