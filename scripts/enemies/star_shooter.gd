extends "res://scripts/enemies/base_enemy.gd"

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/projectiles/enemy_projectile.tscn")

enum ShooterState {
	MOVE,
	CHARGE,
}

@export var fill_color: Color = Color(1.0, 0.8, 0.28)
@export var charge_color: Color = Color(1.0, 0.34, 0.24)
@export var outline_color: Color = Color(1.0, 0.96, 0.68)
@export var preferred_distance: float = 300.0
@export var too_close_distance: float = 190.0
@export var fire_interval: float = 2.35
@export var charge_duration: float = 0.48
@export var projectile_speed: float = 250.0
@export var projectile_damage: int = 10

var _state := ShooterState.MOVE
var _fire_cooldown_left: float = 1.2
var _charge_time_left: float = 0.0
var _aim_direction: Vector2 = Vector2.RIGHT


func _update_behavior(delta: float) -> void:
	match _state:
		ShooterState.MOVE:
			_update_move(delta)
		ShooterState.CHARGE:
			_update_charge(delta)
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
		velocity = to_player * speed * 0.6
	else:
		velocity = Vector2.ZERO

	_fire_cooldown_left = maxf(_fire_cooldown_left - delta, 0.0)
	if _fire_cooldown_left <= 0.0 and to_player != Vector2.ZERO:
		_state = ShooterState.CHARGE
		_charge_time_left = charge_duration
		_aim_direction = to_player


func _update_charge(delta: float) -> void:
	velocity = Vector2.ZERO
	_charge_time_left -= delta
	if _charge_time_left <= 0.0:
		_fire_projectile()
		_state = ShooterState.MOVE
		_fire_cooldown_left = fire_interval


func _fire_projectile() -> void:
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate() as Area2D
	var parent := get_parent()
	if parent != null:
		parent.add_child(projectile)
	else:
		get_tree().current_scene.add_child(projectile)
	projectile.set("fill_color", Color(1.0, 0.3, 0.28))
	projectile.set("outline_color", Color(1.0, 0.86, 0.52))
	projectile.call("setup", global_position + _aim_direction * (radius + 10.0), _aim_direction, projectile_damage, projectile_speed)


func _draw_enemy_shape(_health_ratio: float) -> void:
	var draw_radius := radius
	var draw_color := fill_color
	if _state == ShooterState.CHARGE:
		var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.026)
		draw_radius += pulse * 4.0
		draw_color = charge_color
		draw_line(Vector2.ZERO, _aim_direction * radius * 2.4, Color(1.0, 0.42, 0.26, 0.88), 2.2)

	var points := PackedVector2Array()
	for index in range(10):
		var angle := -PI * 0.5 + TAU * float(index) / 10.0
		var point_radius := draw_radius if index % 2 == 0 else draw_radius * 0.46
		points.append(Vector2.from_angle(angle) * point_radius)
	points.append(points[0])
	draw_colored_polygon(points, draw_color)
	draw_polyline(points, outline_color, 2.0, true)
