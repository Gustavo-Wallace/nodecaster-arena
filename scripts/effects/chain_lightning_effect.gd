extends Node2D

@export var duration: float = 0.18
@export var line_width: float = 4.0
@export var primary_color: Color = Color(0.4, 0.9, 1.0)
@export var secondary_color: Color = Color(0.9, 0.98, 1.0)
@export var visual_shape: String = "circle"

var _time_left: float = 0.0
var _world_points: Array[Vector2] = []
var _zigzag_points := PackedVector2Array()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_time_left = duration
	_build_zigzag()
	queue_redraw()


func setup(world_points: Array[Vector2], new_primary_color: Color, new_secondary_color: Color, new_line_width: float, new_duration: float, new_visual_shape: String = "circle") -> void:
	_world_points = world_points.duplicate()
	primary_color = new_primary_color
	secondary_color = new_secondary_color
	line_width = new_line_width
	duration = new_duration
	visual_shape = new_visual_shape

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
	_draw_connection_markers(alpha, core_color)
	_draw_travel_pulses(alpha, 1.0 - alpha, core_color)

	for index in range(_world_points.size()):
		_draw_impact_marker(_world_points[index], _get_node_direction(index), alpha, core_color)


func _draw_impact_marker(point: Vector2, direction: Vector2, alpha: float, core_color: Color) -> void:
	var marker_radius := maxf(5.0, line_width * 1.7)
	var glow_color := Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.42)

	match visual_shape:
		"triangle":
			_draw_polygon_marker(point, marker_radius * 1.2, 3, direction.angle(), glow_color, core_color)
			_draw_polygon_marker(point, marker_radius * 0.56, 3, direction.angle() + PI, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.24), core_color)
		"square":
			_draw_polygon_marker(point, marker_radius * 1.1, 4, PI * 0.25, glow_color, core_color)
			_draw_polygon_marker(point, marker_radius * 0.58, 4, PI * 0.25, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.2), core_color)
		"diamond":
			_draw_polygon_marker(point, marker_radius * 1.14, 4, 0.0, glow_color, core_color)
		"star":
			_draw_star_marker(point, marker_radius, glow_color, core_color)
		_:
			var inner_radius := marker_radius * (0.72 + (1.0 - alpha) * 0.24)
			var outer_radius := marker_radius * (1.24 + (1.0 - alpha) * 0.36)
			draw_circle(point, inner_radius, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.16))
			draw_arc(point, inner_radius, 0.0, TAU, 20, core_color, maxf(1.1, line_width * 0.32), true)
			draw_arc(point, outer_radius, 0.0, TAU, 24, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.8), maxf(1.0, line_width * 0.26), true)
			draw_circle(point, maxf(1.6, line_width * 0.5), core_color)


func _draw_connection_markers(alpha: float, core_color: Color) -> void:
	if _world_points.size() < 2:
		return

	for index in range(_world_points.size() - 1):
		var start := _world_points[index]
		var end := _world_points[index + 1]
		var direction := start.direction_to(end)
		var midpoint := start.lerp(end, 0.5)
		var marker_color := Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.22)
		_draw_shape_marker(midpoint, maxf(3.0, line_width * 0.72), direction, marker_color, Color(core_color.r, core_color.g, core_color.b, alpha * 0.52))


func _draw_travel_pulses(alpha: float, animation_progress: float, core_color: Color) -> void:
	if _world_points.size() < 2:
		return

	for index in range(_world_points.size() - 1):
		var start := _world_points[index]
		var end := _world_points[index + 1]
		var direction := start.direction_to(end)
		var distance := start.distance_to(end)
		var pulse_count := clampi(int(round(distance / 150.0)), 1, 3)
		for pulse_index in range(pulse_count):
			var pulse_progress := fposmod(animation_progress * 1.8 + float(pulse_index) / float(pulse_count), 1.0)
			var pulse_position := start.lerp(end, pulse_progress)
			var pulse_alpha := alpha * (0.42 + 0.3 * sin(pulse_progress * PI))
			var fill_color := Color(primary_color.r, primary_color.g, primary_color.b, pulse_alpha)
			var outline_color := Color(core_color.r, core_color.g, core_color.b, pulse_alpha)
			_draw_shape_marker(pulse_position, maxf(2.8, line_width * 0.64), direction, fill_color, outline_color)


func _draw_shape_marker(center: Vector2, radius: float, direction: Vector2, fill_color: Color, outline_color: Color) -> void:
	match visual_shape:
		"triangle":
			_draw_polygon_marker(center, radius * 1.16, 3, direction.angle(), fill_color, outline_color)
		"square":
			_draw_polygon_marker(center, radius, 4, PI * 0.25, fill_color, outline_color)
		"diamond":
			_draw_polygon_marker(center, radius, 4, 0.0, fill_color, outline_color)
		"star":
			_draw_star_marker(center, radius * 1.08, fill_color, outline_color)
		_:
			draw_circle(center, radius, fill_color)
			draw_arc(center, radius, 0.0, TAU, 14, outline_color, maxf(0.9, line_width * 0.22), true)


func _get_node_direction(index: int) -> Vector2:
	if _world_points.size() < 2:
		return Vector2.RIGHT
	if index < _world_points.size() - 1:
		return _world_points[index].direction_to(_world_points[index + 1])
	return _world_points[index - 1].direction_to(_world_points[index])


func _draw_polygon_marker(center: Vector2, radius: float, side_count: int, rotation: float, fill_color: Color, outline_color: Color) -> void:
	var points := _create_regular_polygon(center, radius, side_count, rotation)
	draw_colored_polygon(points, fill_color)
	draw_polyline(_close_polygon(points), outline_color, maxf(1.2, line_width * 0.4), true)


func _draw_star_marker(center: Vector2, radius: float, fill_color: Color, outline_color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(10):
		var angle := -PI * 0.5 + float(index) * PI / 5.0
		var point_radius := radius if index % 2 == 0 else radius * 0.42
		points.append(center + Vector2.from_angle(angle) * point_radius)
	draw_colored_polygon(points, fill_color)
	draw_polyline(_close_polygon(points), outline_color, maxf(1.2, line_width * 0.4), true)


func _create_regular_polygon(center: Vector2, radius: float, side_count: int, rotation: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(side_count):
		var angle := rotation + TAU * float(index) / float(side_count)
		points.append(center + Vector2.from_angle(angle) * radius)
	return points


func _close_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var closed_points := points.duplicate()
	if not closed_points.is_empty():
		closed_points.append(closed_points[0])
	return closed_points


func _build_zigzag() -> void:
	_zigzag_points.clear()
	if _world_points.size() < 2:
		return

	for index in range(_world_points.size() - 1):
		var start := _world_points[index]
		var end := _world_points[index + 1]
		if visual_shape == "square":
			_zigzag_points.append(start)
			var corner := Vector2(end.x, start.y)
			if start.distance_to(corner) > 1.0 and corner.distance_to(end) > 1.0:
				_zigzag_points.append(corner)
			_zigzag_points.append(end)
			continue

		var direction := start.direction_to(end)
		var distance := start.distance_to(end)
		var perpendicular := Vector2(-direction.y, direction.x)
		var segment_count := clampi(int(round(distance / 44.0)), 2, 7)
		if visual_shape == "circle":
			segment_count = clampi(int(round(distance / 60.0)), 2, 5)
		elif visual_shape == "star":
			segment_count = clampi(int(round(distance / 34.0)), 3, 8)
		var jitter_amount := 6.0 if visual_shape == "circle" else 10.0
		if visual_shape == "triangle":
			jitter_amount = 14.0
		elif visual_shape == "star":
			jitter_amount = 16.0
		_zigzag_points.append(start)
		for point_index in range(1, segment_count):
			var progress := float(point_index) / float(segment_count)
			var jitter := _rng.randf_range(-jitter_amount, jitter_amount)
			_zigzag_points.append(start.lerp(end, progress) + perpendicular * jitter)
		_zigzag_points.append(end)
