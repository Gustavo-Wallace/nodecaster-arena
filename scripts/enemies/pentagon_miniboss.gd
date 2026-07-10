extends "res://scripts/enemies/base_enemy.gd"

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/projectiles/enemy_projectile.tscn")

@export var fill_color: Color = Color(0.92, 0.54, 0.18)
@export var warning_color: Color = Color(1.0, 0.88, 0.25)
@export var outline_color: Color = Color(1.0, 0.88, 0.62)
@export var ability_interval: float = 3.0
@export var warning_duration: float = 0.65
@export var projectile_damage: int = 12
@export var projectile_speed: float = 245.0

var _ability_cooldown_left: float = 1.4
var _warning_left: float = 0.0
var _is_warning: bool = false


func _update_behavior(delta: float) -> void:
	if _is_warning:
		velocity = Vector2.ZERO
		_warning_left -= delta
		if _warning_left <= 0.0:
			_fire_cross()
			_is_warning = false
			_ability_cooldown_left = ability_interval
		queue_redraw()
		return

	velocity = _get_direction_to_player() * speed
	_ability_cooldown_left = maxf(_ability_cooldown_left - delta, 0.0)

	if _ability_cooldown_left == 0.0:
		_is_warning = true
		_warning_left = warning_duration
		queue_redraw()


func _fire_cross() -> void:
	var parent := get_parent()
	if parent == null:
		return

	for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		var projectile := ENEMY_PROJECTILE_SCENE.instantiate() as Node2D
		parent.add_child(projectile)
		projectile.call("setup", global_position + direction * (radius + 10.0), direction, projectile_damage, projectile_speed)


func _draw_enemy_shape(_health_ratio: float) -> void:
	var draw_color := warning_color if _is_warning else fill_color
	var draw_radius := radius * (1.16 if _is_warning else 1.0)
	var points := PackedVector2Array()

	for index in range(5):
		var angle := -PI / 2.0 + TAU * float(index) / 5.0
		points.append(Vector2.RIGHT.rotated(angle) * draw_radius)

	draw_colored_polygon(points, draw_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[0]]), outline_color, 2.5)

	if _is_warning:
		draw_arc(Vector2.ZERO, draw_radius + 9.0, 0.0, TAU, 36, Color(1.0, 0.95, 0.42), 3.0, true)
