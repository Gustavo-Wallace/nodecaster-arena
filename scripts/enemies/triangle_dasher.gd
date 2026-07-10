extends "res://scripts/enemies/base_enemy.gd"

enum DashState {
	CHASE,
	WARNING,
	DASH,
	RECOVER,
}

@export var fill_color: Color = Color(0.92, 0.42, 1.0)
@export var warning_color: Color = Color(1.0, 0.92, 0.24)
@export var outline_color: Color = Color(1.0, 0.82, 1.0)
@export var dash_indicator_color: Color = Color(1.0, 0.95, 0.34, 0.85)
@export var dash_interval: float = 2.35
@export var warning_duration: float = 0.55
@export var dash_duration: float = 0.36
@export var recovery_duration: float = 0.45
@export var dash_speed: float = 520.0
@export var warning_speed_multiplier: float = 0.15

var _dash_state := DashState.CHASE
var _state_time_left: float = 0.0
var _dash_cooldown_left: float = 1.2
var _dash_direction: Vector2 = Vector2.RIGHT


func _update_behavior(delta: float) -> void:
	match _dash_state:
		DashState.CHASE:
			_update_chase(delta)
		DashState.WARNING:
			_update_warning(delta)
		DashState.DASH:
			_update_dash(delta)
		DashState.RECOVER:
			_update_recover(delta)

	queue_redraw()


func _update_chase(delta: float) -> void:
	var direction := _get_direction_to_player()
	velocity = direction * speed

	if direction != Vector2.ZERO:
		rotation = direction.angle()

	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	if _dash_cooldown_left == 0.0 and direction != Vector2.ZERO:
		_begin_warning(direction)


func _update_warning(delta: float) -> void:
	velocity = _dash_direction * speed * warning_speed_multiplier
	rotation = _dash_direction.angle()
	_state_time_left -= delta

	if _state_time_left <= 0.0:
		_begin_dash()


func _update_dash(delta: float) -> void:
	velocity = _dash_direction * dash_speed
	rotation = _dash_direction.angle()
	_state_time_left -= delta

	if _state_time_left <= 0.0:
		_begin_recover()


func _update_recover(delta: float) -> void:
	velocity = Vector2.ZERO
	_state_time_left -= delta

	if _state_time_left <= 0.0:
		_dash_state = DashState.CHASE
		_dash_cooldown_left = dash_interval


func _begin_warning(direction: Vector2) -> void:
	_dash_state = DashState.WARNING
	_state_time_left = warning_duration
	_dash_direction = direction.normalized()

	if _dash_direction == Vector2.ZERO:
		_dash_direction = Vector2.RIGHT


func _begin_dash() -> void:
	_dash_state = DashState.DASH
	_state_time_left = dash_duration


func _begin_recover() -> void:
	_dash_state = DashState.RECOVER
	_state_time_left = recovery_duration


func _draw_enemy_shape(_health_ratio: float) -> void:
	var draw_color := fill_color
	var draw_scale := 1.0

	if _dash_state == DashState.WARNING:
		var pulse := sin(float(Time.get_ticks_msec()) * 0.02) * 0.12
		draw_color = warning_color
		draw_scale = 1.08 + pulse
		draw_line(Vector2.ZERO, Vector2(radius * 2.7, 0.0), dash_indicator_color, 3.0)
	elif _dash_state == DashState.DASH:
		draw_color = Color(1.0, 0.62, 0.18)

	var points := PackedVector2Array([
		Vector2(radius * draw_scale, 0.0),
		Vector2(-radius * 0.78 * draw_scale, -radius * 0.9 * draw_scale),
		Vector2(-radius * 0.78 * draw_scale, radius * 0.9 * draw_scale),
	])

	draw_colored_polygon(points, draw_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), outline_color, 2.0)
