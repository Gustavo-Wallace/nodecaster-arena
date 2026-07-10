extends "res://scripts/enemies/base_enemy.gd"

@export var fill_color: Color = Color(1.0, 0.28, 0.34)
@export var outline_color: Color = Color(1.0, 0.76, 0.68)


func _update_behavior(_delta: float) -> void:
	velocity = _get_direction_to_player() * speed


func _draw_enemy_shape(_health_ratio: float) -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, outline_color, 2.0, true)
