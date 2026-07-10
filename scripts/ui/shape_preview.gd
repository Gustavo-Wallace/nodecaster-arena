extends Control

@export var visual_shape: String = "circle"
@export var fill_color: Color = Color(0.18, 0.78, 1.0)
@export var outline_color: Color = Color(0.82, 0.98, 1.0)


func setup(shape: String, fill: Color, outline: Color) -> void:
	visual_shape = shape
	fill_color = fill
	outline_color = outline
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.32

	match visual_shape:
		"triangle":
			var points := PackedVector2Array([
				center + Vector2(0.0, -radius),
				center + Vector2(radius * 0.92, radius * 0.78),
				center + Vector2(-radius * 0.92, radius * 0.78),
			])
			draw_colored_polygon(points, fill_color)
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), outline_color, 2.5)
		"square":
			var side := radius * 1.55
			var rect := Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side))
			draw_rect(rect, fill_color, true)
			draw_rect(rect, outline_color, false, 2.5)
		_:
			draw_circle(center, radius, fill_color)
			draw_arc(center, radius, 0.0, TAU, 40, outline_color, 2.5, true)
