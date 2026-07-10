extends CharacterBody2D

signal died(enemy: Node)

@export var speed: float = 140.0
@export var max_health: int = 40
@export var score_value: int = 10
@export var contact_damage: int = 10
@export var contact_damage_cooldown: float = 0.65
@export var radius: float = 16.0
@export var contact_distance: float = 40.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_health: int
var player: Node2D
var _contact_cooldown_left: float = 0.0
var _is_dead: bool = false


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_update_collision_shape()
	queue_redraw()


func setup(target_player: Node2D) -> void:
	player = target_player


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_contact_cooldown_left = maxf(_contact_cooldown_left - delta, 0.0)
	_update_behavior(delta)
	move_and_slide()
	_try_damage_player()


func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	queue_redraw()

	if current_health == 0:
		_die()


func _update_behavior(_delta: float) -> void:
	velocity = Vector2.ZERO


func _get_direction_to_player() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO

	return global_position.direction_to(player.global_position)


func _try_damage_player() -> void:
	if _contact_cooldown_left > 0.0 or not is_instance_valid(player):
		return

	if global_position.distance_to(player.global_position) > contact_distance:
		return

	if player.has_method("take_damage"):
		player.call("take_damage", contact_damage)
		_contact_cooldown_left = contact_damage_cooldown


func _die() -> void:
	_is_dead = true
	died.emit(self)
	queue_free()


func _update_collision_shape() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius


func _draw() -> void:
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(current_health) / float(max_health)

	_draw_enemy_shape(health_ratio)
	_draw_health_arc(health_ratio)


func _draw_enemy_shape(_health_ratio: float) -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.25, 0.3))


func _draw_health_arc(health_ratio: float) -> void:
	if health_ratio >= 1.0:
		return

	draw_arc(
		Vector2.ZERO,
		radius + 5.0,
		-PI / 2.0,
		-PI / 2.0 + TAU * health_ratio,
		32,
		Color(1.0, 0.95, 0.62),
		2.0,
		true
	)
