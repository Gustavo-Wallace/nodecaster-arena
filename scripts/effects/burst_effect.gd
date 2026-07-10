extends Node2D

@export var duration: float = 0.46
@export var particle_count: int = 12
@export var start_radius: float = 5.0
@export var end_radius: float = 34.0
@export var color: Color = Color(1.0, 0.58, 0.24)

var _time_left: float
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_time_left = duration
	_build_particles()
	queue_redraw()


func setup(world_position: Vector2, burst_color: Color = Color(1.0, 0.58, 0.24), new_particle_count: int = 12) -> void:
	global_position = world_position
	color = burst_color
	particle_count = new_particle_count

	if is_node_ready():
		_time_left = duration
		_build_particles()
		queue_redraw()


func _process(delta: float) -> void:
	_time_left -= delta
	queue_redraw()

	if _time_left <= 0.0:
		queue_free()


func _draw() -> void:
	var progress := 1.0 - clampf(_time_left / duration, 0.0, 1.0)
	var alpha := 1.0 - progress
	var ring_color := Color(color.r, color.g, color.b, 0.55 * alpha)

	draw_arc(Vector2.ZERO, lerpf(start_radius, end_radius, progress), 0.0, TAU, 36, ring_color, 2.0, true)

	for particle in _particles:
		var direction: Vector2 = particle["direction"]
		var distance: float = lerpf(start_radius, float(particle["distance"]), progress)
		var size: float = lerpf(float(particle["size"]), 1.0, progress)
		var particle_color := Color(color.r, color.g, color.b, alpha)
		draw_circle(direction * distance, size, particle_color)


func _build_particles() -> void:
	_particles.clear()

	for index in range(particle_count):
		var angle := TAU * float(index) / float(maxi(particle_count, 1))
		angle += _rng.randf_range(-0.18, 0.18)
		_particles.append({
			"direction": Vector2.RIGHT.rotated(angle),
			"distance": _rng.randf_range(end_radius * 0.72, end_radius * 1.18),
			"size": _rng.randf_range(2.0, 4.4),
		})
