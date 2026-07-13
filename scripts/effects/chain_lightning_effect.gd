extends Node2D

@export var duration: float = 0.18
@export var line_width: float = 4.0
@export var primary_color: Color = Color(0.4, 0.9, 1.0)
@export var secondary_color: Color = Color(0.9, 0.98, 1.0)

var _time_left: float = 0.0
var _world_points: Array[Vector2] = []
var _zigzag_points := PackedVector2Array()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_time_left = duration
	_build_zigzag()
	queue_redraw()


func setup(world_points: Array[Vector2], new_primary_color: Color, new_secondary_color: Color, new_line_width: float, new_duration: float) -> void:
	_world_points = world_points.duplicate()
	primary_color = new_primary_color
	secondary_color = new_secondary_color
	line_width = new_line_width
	duration = new_duration

	if is_node_ready():
		_time_left = duration
		_build_zigzag()
		queue_redraw()


func _process(delta: float) -> void:
	_time_left -= delta
	queue_redraw()
	if _time_left <= 0.0:
		queue_free()


func _draw() -> void:
	if _zigzag_points.size() < 2:
		return

	var alpha := clampf(_time_left / maxf(duration, 0.001), 0.0, 1.0)
	var glow_color := Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.28)
	var core_color := Color(secondary_color.r, secondary_color.g, secondary_color.b, alpha)
	draw_polyline(_zigzag_points, glow_color, line_width * 2.4, true)
	draw_polyline(_zigzag_points, core_color, line_width, true)

	for point in _world_points:
		draw_circle(point, line_width * 1.45, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.44))
		draw_circle(point, maxf(1.6, line_width * 0.5), core_color)


func _build_zigzag() -> void:
	_zigzag_points.clear()
	if _world_points.size() < 2:
		return

	for index in range(_world_points.size() - 1):
		var start := _world_points[index]
		var end := _world_points[index + 1]
		var direction := start.direction_to(end)
		var distance := start.distance_to(end)
		var perpendicular := Vector2(-direction.y, direction.x)
		var segment_count := clampi(int(round(distance / 44.0)), 2, 7)
		_zigzag_points.append(start)
		for point_index in range(1, segment_count):
			var progress := float(point_index) / float(segment_count)
			var jitter := _rng.randf_range(-10.0, 10.0)
			_zigzag_points.append(start.lerp(end, progress) + perpendicular * jitter)
		_zigzag_points.append(end)
