extends Node2D

@export var duration: float = 0.82
@export var fragment_count: int = 8
@export var intensity: float = 1.0
@export var base_color: Color = Color(1.0, 0.55, 0.28)
@export var shape_type: String = "circle"
@export var ring_count: int = 1

var _time := 0.0
var _fragments: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_fragments()
	queue_redraw()


func setup(world_position: Vector2, color: Color, new_shape_type: String = "circle", new_intensity: float = 1.0, new_fragment_count: int = -1, new_ring_count: int = 1) -> void:
	global_position = world_position
	base_color = color
	shape_type = new_shape_type
	intensity = maxf(new_intensity, 0.2)
	ring_count = maxi(new_ring_count, 0)
	if new_fragment_count > 0:
		fragment_count = new_fragment_count

	if is_node_ready():
		_time = 0.0
		_build_fragments()
		queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

	if _time >= duration:
		queue_free()


func _draw() -> void:
	var progress := clampf(_time / maxf(duration, 0.001), 0.0, 1.0)
	var alpha := pow(1.0 - progress, 1.25)

	_draw_impact_rings(progress, alpha)

	for fragment in _fragments:
		var velocity: Vector2 = fragment.get("velocity", Vector2.ZERO)
		var spin := float(fragment.get("spin", 0.0))
		var start_rotation := float(fragment.get("rotation", 0.0))
		var size := float(fragment.get("size", 4.0))
		var local_shape := str(fragment.get("shape", "circle"))
		var position := velocity * _time
		var eased_scale := lerpf(1.0, 0.35, progress)
		var fragment_color := Color(base_color.r, base_color.g, base_color.b, alpha)

		draw_set_transform(position, start_rotation + spin * _time, Vector2.ONE * eased_scale)
		_draw_fragment(local_shape, size, fragment_color)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_impact_rings(progress: float, alpha: float) -> void:
	for index in range(ring_count):
		var offset := float(index) * 0.16
		var ring_progress := clampf((progress - offset) / maxf(1.0 - offset, 0.001), 0.0, 1.0)
		if ring_progress <= 0.0:
			continue

		var ring_alpha := alpha * (0.48 - float(index) * 0.1)
		var radius := lerpf(12.0 * intensity, 58.0 * intensity + float(index) * 18.0, ring_progress)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(base_color.r, base_color.g, base_color.b, ring_alpha), maxf(1.5, 3.0 - float(index) * 0.45), true)


func _draw_fragment(local_shape: String, size: float, color: Color) -> void:
	match local_shape:
		"triangle":
			var points := PackedVector2Array([
				Vector2(0.0, -size),
				Vector2(size * 0.95, size * 0.72),
				Vector2(-size * 0.95, size * 0.72),
			])
			draw_colored_polygon(points, color)
		"hexagon":
			var points := PackedVector2Array()
			for index in range(6):
				var angle := PI / 6.0 + TAU * float(index) / 6.0
				points.append(Vector2.from_angle(angle) * size)
			draw_colored_polygon(points, color)
		"square":
			draw_rect(Rect2(Vector2(-size, -size), Vector2(size * 2.0, size * 2.0)), color, true)
		"diamond":
			var points := PackedVector2Array([
				Vector2(0.0, -size),
				Vector2(size * 0.82, 0.0),
				Vector2(0.0, size),
				Vector2(-size * 0.82, 0.0),
			])
			draw_colored_polygon(points, color)
		"line":
			draw_line(Vector2(-size * 1.5, 0.0), Vector2(size * 1.5, 0.0), color, maxf(1.5, size * 0.34))
		_:
			draw_circle(Vector2.ZERO, size, color)


func _build_fragments() -> void:
	_fragments.clear()

	for index in range(fragment_count):
		var angle := TAU * float(index) / float(maxi(fragment_count, 1))
		angle += _rng.randf_range(-0.34, 0.34)
		var speed := _rng.randf_range(78.0, 168.0) * intensity
		_fragments.append({
			"velocity": Vector2.RIGHT.rotated(angle) * speed,
			"spin": _rng.randf_range(-9.0, 9.0) * intensity,
			"rotation": _rng.randf_range(0.0, TAU),
			"size": _rng.randf_range(3.0, 6.8) * sqrt(intensity),
			"shape": _choose_fragment_shape(),
		})


func _choose_fragment_shape() -> String:
	match shape_type:
		"triangle":
			return "triangle"
		"hexagon":
			return "hexagon"
		"square":
			return "square"
		"diamond":
			return "diamond"
		"line":
			return "line"
		"star":
			var shapes := ["triangle", "diamond", "line"]
			return shapes[_rng.randi_range(0, shapes.size() - 1)]
		"boss":
			var shapes := ["triangle", "square", "diamond", "line"]
			return shapes[_rng.randi_range(0, shapes.size() - 1)]
		_:
			var shapes := ["circle", "triangle"]
			return shapes[_rng.randi_range(0, shapes.size() - 1)]
