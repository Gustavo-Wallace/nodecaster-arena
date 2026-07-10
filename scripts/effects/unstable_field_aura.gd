extends Node2D

@export var radius: float = 60.0
@export var color: Color = Color(0.42, 0.95, 1.0, 0.22)

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 5.5)
	var draw_radius := radius + pulse * 7.0
	draw_circle(Vector2.ZERO, draw_radius, Color(color.r, color.g, color.b, color.a * 0.45))
	draw_arc(Vector2.ZERO, draw_radius, 0.0, TAU, 64, Color(color.r, color.g, color.b, 0.62), 2.0, true)
