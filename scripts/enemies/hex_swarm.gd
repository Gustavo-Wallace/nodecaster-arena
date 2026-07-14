extends "res://scripts/enemies/base_enemy.gd"

@export var fill_color: Color = Color(0.24, 0.94, 0.78)
@export var outline_color: Color = Color(0.78, 1.0, 0.9)


func _update_behavior(_delta: float) -> void:
	velocity = _get_direction_to_player() * speed


func _draw_enemy_shape(_health_ratio: float) -> void:
	var points := PackedVector2Array()
	for index in range(6):
		var angle := PI / 6.0 + TAU * float(index) / 6.0
		points.append(Vector2.from_angle(angle) * radius)
	points.append(points[0])
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, outline_color, 1.8, true)
	draw_circle(Vector2.ZERO, radius * 0.28, Color(0.86, 1.0, 0.94, 0.46))
