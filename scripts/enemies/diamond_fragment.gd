extends "res://scripts/enemies/base_enemy.gd"

@export var fill_color: Color = Color(1.0, 0.58, 0.84)
@export var outline_color: Color = Color(1.0, 0.88, 0.96)


func _update_behavior(_delta: float) -> void:
	velocity = _get_direction_to_player() * speed


func _draw_enemy_shape(_health_ratio: float) -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius * 0.72, 0.0),
		Vector2(0.0, radius),
		Vector2(-radius * 0.72, 0.0),
		Vector2(0.0, -radius),
	])
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, outline_color, 1.4, true)
