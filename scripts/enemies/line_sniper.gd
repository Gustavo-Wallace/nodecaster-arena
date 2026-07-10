extends "res://scripts/enemies/base_enemy.gd"

signal laser_fired(enemy: Node, origin: Vector2, direction: Vector2, max_range: float, width: float, damage: int)

enum SniperState {
	MOVE,
	AIM,
	RECOVER,
}

@export var fill_color: Color = Color(0.72, 0.8, 1.0)
@export var warning_color: Color = Color(1.0, 0.28, 0.28, 0.86)
@export var outline_color: Color = Color(0.92, 0.96, 1.0)
@export var preferred_distance: float = 340.0
@export var too_close_distance: float = 230.0
@export var aim_interval: float = 2.7
@export var aim_duration: float = 0.75
@export var recover_duration: float = 0.45
@export var laser_range: float = 760.0
@export var laser_width: float = 20.0
@export var laser_damage: int = 16

var _state := SniperState.MOVE
var _aim_cooldown_left := 1.4
var _state_time_left := 0.0
var _aim_direction := Vector2.RIGHT


func _update_behavior(delta: float) -> void:
	match _state:
		SniperState.MOVE:
			_update_move(delta)
		SniperState.AIM:
			_update_aim(delta)
		SniperState.RECOVER:
			_update_recover(delta)

	queue_redraw()


func _update_move(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	var to_player := global_position.direction_to(player.global_position)
	var distance := global_position.distance_to(player.global_position)
	if distance < too_close_distance:
		velocity = -to_player * speed
	elif distance > preferred_distance:
		velocity = to_player * speed * 0.55
	else:
		velocity = Vector2.ZERO

	if to_player != Vector2.ZERO:
		rotation = to_player.angle()

	_aim_cooldown_left = maxf(_aim_cooldown_left - delta, 0.0)
	if _aim_cooldown_left <= 0.0 and to_player != Vector2.ZERO:
		_state = SniperState.AIM
		_state_time_left = aim_duration
		_aim_direction = to_player.normalized()


func _update_aim(delta: float) -> void:
	velocity = Vector2.ZERO
	rotation = _aim_direction.angle()
	_state_time_left -= delta
	if _state_time_left <= 0.0:
		laser_fired.emit(self, global_position, _aim_direction, laser_range, laser_width, laser_damage)
		_state = SniperState.RECOVER
		_state_time_left = recover_duration


func _update_recover(delta: float) -> void:
	velocity = Vector2.ZERO
	_state_time_left -= delta
	if _state_time_left <= 0.0:
		_state = SniperState.MOVE
		_aim_cooldown_left = aim_interval


func _draw_enemy_shape(_health_ratio: float) -> void:
	var rect := Rect2(Vector2(-radius * 1.35, -radius * 0.32), Vector2(radius * 2.7, radius * 0.64))
	draw_rect(rect, fill_color, true)
	draw_rect(rect, outline_color, false, 2.0)

	if _state == SniperState.AIM:
		draw_line(Vector2.ZERO, Vector2(laser_range, 0.0), warning_color, 3.0)
