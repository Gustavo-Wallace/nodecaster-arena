extends "res://scripts/enemies/base_enemy.gd"

signal exploded(enemy: Node, world_position: Vector2, radius: float, damage: int)

enum BomberState {
	CHASE,
	ARMING,
}

@export var fill_color: Color = Color(1.0, 0.58, 0.16)
@export var warning_color: Color = Color(1.0, 0.18, 0.18)
@export var outline_color: Color = Color(1.0, 0.9, 0.58)
@export var trigger_distance: float = 58.0
@export var arm_duration: float = 0.75
@export var explosion_radius: float = 82.0
@export var explosion_damage: int = 18

var _state := BomberState.CHASE
var _arm_time_left := 0.0


func _update_behavior(delta: float) -> void:
	match _state:
		BomberState.CHASE:
			_update_chase()
		BomberState.ARMING:
			_update_arming(delta)

	queue_redraw()


func _update_chase() -> void:
	velocity = _get_direction_to_player() * speed
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= trigger_distance:
		_state = BomberState.ARMING
		_arm_time_left = arm_duration
		velocity = Vector2.ZERO


func _update_arming(delta: float) -> void:
	velocity = Vector2.ZERO
	_arm_time_left -= delta
	if _arm_time_left <= 0.0:
		_explode_self()


func _explode_self() -> void:
	if _is_dead:
		return

	score_value = 0
	contact_damage = 0
	_is_dead = true
	exploded.emit(self, global_position, explosion_radius, explosion_damage)
	died.emit(self)
	queue_free()


func _draw_enemy_shape(_health_ratio: float) -> void:
	var draw_color := fill_color
	var draw_radius := radius
	if _state == BomberState.ARMING:
		var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.035)
		draw_color = warning_color
		draw_radius += pulse * 8.0
		draw_arc(Vector2.ZERO, explosion_radius, 0.0, TAU, 48, Color(1.0, 0.2, 0.15, 0.45), 2.0, true)

	var points := PackedVector2Array()
	for index in range(10):
		var angle := -PI / 2.0 + TAU * float(index) / 10.0
		var point_radius := draw_radius if index % 2 == 0 else draw_radius * 0.48
		points.append(Vector2.RIGHT.rotated(angle) * point_radius)

	draw_colored_polygon(points, draw_color)
	points.append(points[0])
	draw_polyline(points, outline_color, 2.0)
