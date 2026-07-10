extends "res://scripts/enemies/base_enemy.gd"

signal summon_requested(count: int, world_position: Vector2)

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/projectiles/enemy_projectile.tscn")

enum BossPattern {
	RADIAL_SHOT,
	SUMMON,
}

@export var fill_color: Color = Color(0.36, 0.62, 1.0)
@export var warning_color: Color = Color(0.94, 0.38, 1.0)
@export var outline_color: Color = Color(0.82, 0.92, 1.0)
@export var pattern_interval: float = 3.2
@export var warning_duration: float = 0.8
@export var radial_projectiles: int = 12
@export var projectile_damage: int = 14
@export var projectile_speed: float = 225.0
@export var summon_count: int = 3

var _pattern_cooldown_left: float = 1.6
var _warning_left: float = 0.0
var _is_warning: bool = false
var _next_pattern := BossPattern.RADIAL_SHOT


func _update_behavior(delta: float) -> void:
	if _is_warning:
		velocity = Vector2.ZERO
		_warning_left -= delta
		if _warning_left <= 0.0:
			_execute_pattern()
			_is_warning = false
			_pattern_cooldown_left = pattern_interval
		queue_redraw()
		return

	velocity = _get_direction_to_player() * speed
	_pattern_cooldown_left = maxf(_pattern_cooldown_left - delta, 0.0)

	if _pattern_cooldown_left == 0.0:
		_is_warning = true
		_warning_left = warning_duration
		queue_redraw()


func _execute_pattern() -> void:
	match _next_pattern:
		BossPattern.RADIAL_SHOT:
			_fire_radial()
			_next_pattern = BossPattern.SUMMON
		BossPattern.SUMMON:
			summon_requested.emit(summon_count, global_position)
			_next_pattern = BossPattern.RADIAL_SHOT


func _fire_radial() -> void:
	var parent := get_parent()
	if parent == null:
		return

	for index in range(radial_projectiles):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / float(radial_projectiles))
		var projectile := ENEMY_PROJECTILE_SCENE.instantiate() as Node2D
		parent.add_child(projectile)
		projectile.call("setup", global_position + direction * (radius + 12.0), direction, projectile_damage, projectile_speed)


func _draw_enemy_shape(_health_ratio: float) -> void:
	var draw_color := warning_color if _is_warning else fill_color
	var draw_radius := radius * (1.12 if _is_warning else 1.0)
	var points := PackedVector2Array()

	for index in range(6):
		var angle := -PI / 2.0 + TAU * float(index) / 6.0
		points.append(Vector2.RIGHT.rotated(angle) * draw_radius)

	draw_colored_polygon(points, draw_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[5], points[0]]), outline_color, 3.0)

	if _is_warning:
		var warning_radius := draw_radius + 11.0
		draw_arc(Vector2.ZERO, warning_radius, 0.0, TAU, 42, Color(1.0, 0.78, 1.0), 3.0, true)
		if _next_pattern == BossPattern.SUMMON:
			draw_circle(Vector2.ZERO, radius * 0.32, Color(1.0, 0.95, 0.45, 0.9))
