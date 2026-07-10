extends Node2D

@export var duration: float = 0.48
@export var start_radius: float = 8.0
@export var end_radius: float = 72.0
@export var width: float = 3.0
@export var color: Color = Color(1.0, 0.72, 0.28)

var _time := 0.0


func setup(world_position: Vector2, new_color: Color, new_start_radius: float = 8.0, new_end_radius: float = 72.0, new_duration: float = 0.48, new_width: float = 3.0) -> void:
	global_position = world_position
	color = new_color
	start_radius = new_start_radius
	end_radius = new_end_radius
	duration = new_duration
	width = new_width
	_time = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

	if _time >= duration:
		queue_free()


func _draw() -> void:
	var progress := clampf(_time / maxf(duration, 0.001), 0.0, 1.0)
	var alpha := pow(1.0 - progress, 1.6)
	var radius := lerpf(start_radius, end_radius, progress)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color.r, color.g, color.b, color.a * alpha), width * (1.0 - progress * 0.45), true)
