extends Node2D

const SLASH_GEOMETRY := preload("res://scripts/spells/slash_visual_geometry.gd")

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
		"diamond":
			_draw_diamond_slash(glow_color, core_color, active_width)
		"star":
			_draw_star_slash(glow_color, core_color, active_width)
		_:
			_draw_arc_slash(glow_color, core_color, active_width)

	if visual_shape == "circle":
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
	var impact_center := Vector2(slash_length * 0.42, 0.0)
	draw_circle(impact_center, active_width * 1.45, Color(primary_color.r, primary_color.g, primary_color.b, glow_color.a * 1.6))
	draw_arc(impact_center, active_width * 1.65, 0.0, TAU, 16, core_color, maxf(1.0, active_width * 0.18), true)


func _draw_precision_slash(glow_color: Color, core_color: Color, active_width: float) -> void:
	_draw_polygon_slash("triangle", glow_color, core_color, active_width)


func _draw_heavy_slash(glow_color: Color, core_color: Color, active_width: float) -> void:
	_draw_polygon_slash("square", glow_color, core_color, active_width)


func _draw_diamond_slash(glow_color: Color, core_color: Color, active_width: float) -> void:
	_draw_polygon_slash("diamond", glow_color, core_color, active_width)


func _draw_star_slash(glow_color: Color, core_color: Color, active_width: float) -> void:
	_draw_polygon_slash("star", glow_color, core_color, active_width)


func _draw_polygon_slash(shape_id: String, glow_color: Color, core_color: Color, active_width: float) -> void:
	var polygon := SLASH_GEOMETRY.get_slash_polygon(shape_id, Vector2.ZERO, slash_length, active_width)
	if polygon.is_empty():
		_draw_arc_slash(glow_color, core_color, active_width)
		return

	var fill_color := Color(primary_color.r, primary_color.g, primary_color.b, glow_color.a * 2.25)
	draw_colored_polygon(polygon, fill_color)
	draw_polyline(SLASH_GEOMETRY.close_polygon(polygon), core_color, maxf(1.35, active_width * 0.4), true)
	_draw_shape_impact(shape_id, active_width, glow_color, core_color)


func _draw_shape_impact(shape_id: String, active_width: float, glow_color: Color, core_color: Color) -> void:
	var impact_center := Vector2(slash_length * 0.62, 0.0)
	var impact_size := maxf(4.0, active_width * 0.95)
	var impact := SLASH_GEOMETRY.get_impact_polygon(shape_id, impact_center, impact_size)
	if impact.is_empty():
		return

	draw_colored_polygon(impact, Color(primary_color.r, primary_color.g, primary_color.b, glow_color.a * 2.6))
	draw_polyline(SLASH_GEOMETRY.close_polygon(impact), core_color, maxf(1.0, active_width * 0.22), true)
	var fragment_offsets: Array[Vector2] = [Vector2(-impact_size * 1.2, -impact_size * 0.82), Vector2(impact_size * 0.52, impact_size * 0.94)]
	for offset: Vector2 in fragment_offsets:
		var fragment := SLASH_GEOMETRY.get_impact_polygon(shape_id, impact_center + offset, impact_size * 0.36)
		draw_colored_polygon(fragment, Color(primary_color.r, primary_color.g, primary_color.b, glow_color.a * 1.7))


func _build_sparks() -> void:
	_sparks.clear()
	if visual_shape != "circle":
		return
	for index in range(6):
		var angle := _rng.randf_range(-PI * 0.84, PI * 0.34)
		_sparks.append({
			"direction": Vector2.RIGHT.rotated(angle),
			"distance": _rng.randf_range(slash_length * 0.34, slash_length * 0.64),
			"size": _rng.randf_range(1.2, 2.6),
		})
