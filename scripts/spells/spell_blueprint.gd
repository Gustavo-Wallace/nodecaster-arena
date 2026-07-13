class_name SpellBlueprint
extends RefCounted

const SPELL_SHAPE_DATA := preload("res://scripts/spells/spell_shape_data.gd")
const SPELL_ELEMENT_DATA := preload("res://scripts/spells/spell_element_data.gd")
const SPELL_DELIVERY_DATA := preload("res://scripts/spells/spell_delivery_data.gd")

var selected_shape_id: String = "circle"
var selected_element_id: String = "arcane"
var selected_delivery_id: String = "simple_projectile"


func _init(shape_id: String = "circle", element_id: String = "arcane", delivery_id: String = "simple_projectile") -> void:
	set_selection(shape_id, element_id, delivery_id)


func set_selection(shape_id: String, element_id: String, delivery_id: String) -> void:
	selected_shape_id = str(SPELL_SHAPE_DATA.get_data(shape_id).get("id", "circle"))
	selected_element_id = str(SPELL_ELEMENT_DATA.get_data(element_id).get("id", "arcane"))
	var delivery_data: Dictionary = SPELL_DELIVERY_DATA.get_data(delivery_id)
	selected_delivery_id = str(delivery_data.get("id", "simple_projectile"))
	if not bool(delivery_data.get("available", false)):
		selected_delivery_id = "simple_projectile"


func get_shape_data() -> Dictionary:
	return SPELL_SHAPE_DATA.get_data(selected_shape_id)


func get_element_data() -> Dictionary:
	return SPELL_ELEMENT_DATA.get_data(selected_element_id)


func get_delivery_data() -> Dictionary:
	return SPELL_DELIVERY_DATA.get_data(selected_delivery_id)


func get_initial_attributes() -> Dictionary:
	var shape := get_shape_data()
	var element := get_element_data()
	return {
		"damage_multiplier": float(shape.get("damage_multiplier", 1.0)),
		"projectile_speed_multiplier": float(shape.get("projectile_speed_multiplier", 1.0)),
		"fire_interval_multiplier": float(shape.get("fire_interval_multiplier", 1.0)),
		"size_multiplier": float(shape.get("size_multiplier", 1.0)),
		"pierce_bonus": int(shape.get("pierce_bonus", 0)),
		"duration_multiplier": float(shape.get("duration_multiplier", 1.0)),
		"area_multiplier": float(shape.get("area_multiplier", 1.0)),
		"chain_range_multiplier": float(shape.get("chain_range_multiplier", 1.0)),
		"chain_jump_range_multiplier": float(shape.get("chain_jump_range_multiplier", 1.0)),
		"chain_visual_width_multiplier": float(shape.get("chain_visual_width_multiplier", 1.0)),
		"chain_bonus_jumps": 1 if str(element.get("id", "arcane")) == "lightning" else 0,
		"chain_falloff_multiplier": 1.1 if str(element.get("id", "arcane")) == "lightning" else 1.0,
		"area_size_multiplier": float(shape.get("area_size_multiplier", 1.0)),
		"area_duration_multiplier": float(shape.get("area_duration_multiplier", 1.0)),
		"area_tick_interval_multiplier": float(shape.get("area_tick_interval_multiplier", 1.0)) * (0.84 if str(element.get("id", "arcane")) == "lightning" else 1.0),
		"area_damage_multiplier": float(shape.get("area_damage_multiplier", 1.0)),
		"visual_shape": str(shape.get("visual_shape", "circle")),
		"fill_color": element.get("primary_color", Color(0.77, 0.36, 1.0)),
		"outline_color": element.get("secondary_color", Color(1.0, 0.78, 1.0)),
		"impact_color": element.get("impact_color", Color(0.96, 0.48, 1.0)),
		"element_id": str(element.get("id", "arcane")),
		"element_effect_id": str(element.get("effect_id", "direct")),
		"element_effect_power": float(element.get("effect_power", 0.0)),
	}


func get_summary() -> Dictionary:
	return {
		"shape_id": selected_shape_id,
		"shape_name": str(get_shape_data().get("display_name", "Circulo")),
		"element_id": selected_element_id,
		"element_name": str(get_element_data().get("display_name", "Arcano")),
		"delivery_id": selected_delivery_id,
		"delivery_name": str(get_delivery_data().get("display_name", "Projetil Simples")),
	}
