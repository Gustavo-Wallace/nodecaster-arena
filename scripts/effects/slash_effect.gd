extends Node2D

@export var duration: float = 0.16
@export var slash_length: float = 74.0
@export var slash_width: float = 10.0
@export var visual_shape: String = "circle"
@export var primary_color: Color = Color(0.74, 0.36, 1.0)
@export var secondary_color: Color = Color(1.0, 0.78, 1.0)
@export var arc_multiplier: float = 1.0

var _time_left: float = 0.0
var _sparks: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func setup(origin: Vector2, target: Vector2, new_length: float, new_width: float, shape_id: String, primary: Color, secondary: Color, new_duration: float, new_arc_multiplier: float) -> void:
	global_position = target
	rotation = origin.direction_to(target).angle()
	slash_length = new_length
	slash_width = new_width
	visual_shape = shape_id
	primary_color = primary
	secondary_color = secondary
	duration = new_duration
	arc_multiplier = new_arc_multiplier


func _ready() -> void:
	_rng.randomize()
	_time_left = duration
	_build_sparks()
	queue_redraw()


func _process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	queue_redraw()
	if _time_left <= 0.0:
		queue_free()


func _draw() -> void:
	var alpha := clampf(_time_left / maxf(duration, 0.001), 0.0, 1.0)
	var progress := 1.0 - alpha
	var glow_color := Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.26)
	var core_color := Color(secondary_color.r, secondary_color.g, secondary_color.b, alpha)
	var active_width := slash_width * (1.0 - progress * 0.22)

	match visual_shape:
		"triangle":
			_draw_precision_slash(glow_color, core_color, active_width)
		"square":
			_draw_heavy_slash(glow_color, core_color, active_width)
		_:
			_draw_arc_slash(glow_color, core_color, active_width)

	for spark in _sparks:
		var direction: Vector2 = spark["direction"]
		var distance := lerpf(slash_length * 0.14, float(spark["distance"]), progress)
		var spark_size := lerpf(float(spark["size"]), 1.0, progress)
		draw_line(direction * distance, direction * (distance + spark_size * 2.6), Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.72), spark_size, true)


func _draw_arc_slash(glow_color: Color, core_color: Color, active_width: float) -> void:
	var arc_radius := slash_length * 0.54
	var arc_span := PI * clampf(arc_multiplier, 0.72, 1.3)
	var start_angle := -arc_span * 0.76
	var end_angle := arc_span * 0.24
	draw_arc(Vector2.ZERO, arc_radius, start_angle, end_angle, 24, glow_color, active_width * 2.5, true)
	draw_arc(Vector2.ZERO, arc_radius, start_angle, end_angle, 24, core_color, active_width, true)


func _draw_precision_slash(glow_color: Color, core_color: Color, active_width: float) -> void:
	var start := Vector2(-slash_length * 0.5, -slash_length * 0.28)
	var end := Vector2(slash_length * 0.5, slash_length * 0.28)
	draw_line(start, end, glow_color, active_width * 2.15, true)
	draw_line(start, end, core_color, active_width * 0.8, true)
	draw_line(start + Vector2(8.0, -4.0), end + Vector2(-14.0, -7.0), Color(primary_color.r, primary_color.g, primary_color.b, glow_color.a * 0.72), active_width * 0.38, true)


func _draw_heavy_slash(glow_color: Color, core_color: Color, active_width: float) -> void:
	var start := Vector2(-slash_length * 0.54, -slash_length * 0.2)
	var end := Vector2(slash_length * 0.54, slash_length * 0.2)
	draw_line(start, end, glow_color, active_width * 2.7, true)
	draw_line(start, end, core_color, active_width, true)
	draw_circle(Vector2.ZERO, active_width * 0.64, Color(primary_color.r, primary_color.g, primary_color.b, glow_color.a * 0.9))


func _build_sparks() -> void:
	_sparks.clear()
	for index in range(6):
		var angle := _rng.randf_range(-PI * 0.84, PI * 0.34)
		_sparks.append({
			"direction": Vector2.RIGHT.rotated(angle),
			"distance": _rng.randf_range(slash_length * 0.34, slash_length * 0.64),
			"size": _rng.randf_range(1.2, 2.6),
		})
