extends "res://scripts/enemies/base_enemy.gd"

@export var fill_color: Color = Color(0.36, 0.88, 0.54)
@export var outline_color: Color = Color(0.82, 1.0, 0.82)


func _update_behavior(_delta: float) -> void:
	velocity = _get_direction_to_player() * speed


func _draw_enemy_shape(_health_ratio: float) -> void:
	var side := radius * 1.8
	var rect := Rect2(Vector2(-side * 0.5, -side * 0.5), Vector2(side, side))

	draw_rect(rect, fill_color, true)
	draw_rect(rect, outline_color, false, 2.5)
