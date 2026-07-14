extends "res://scripts/enemies/base_enemy.gd"

signal split_requested(enemy: Node, world_position: Vector2, fragment_count: int)

@export var fill_color: Color = Color(0.94, 0.36, 0.72)
@export var outline_color: Color = Color(1.0, 0.78, 0.94)
@export var split_count_min: int = 2
@export var split_count_max: int = 3

var _has_split: bool = false
var _split_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_split_rng.randomize()
	super._ready()


func _update_behavior(_delta: float) -> void:
	velocity = _get_direction_to_player() * speed


func _die() -> void:
	if not _has_split:
		_has_split = true
		var fragment_count := _split_rng.randi_range(split_count_min, split_count_max)
		split_requested.emit(self, global_position, fragment_count)
	super._die()


func _draw_enemy_shape(_health_ratio: float) -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -radius * 1.15),
		Vector2(radius * 0.86, 0.0),
		Vector2(0.0, radius * 1.15),
		Vector2(-radius * 0.86, 0.0),
		Vector2(0.0, -radius * 1.15),
	])
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, outline_color, 2.2, true)
	draw_line(Vector2(-radius * 0.46, 0.0), Vector2(radius * 0.46, 0.0), Color(1.0, 0.94, 1.0, 0.64), 1.3)
