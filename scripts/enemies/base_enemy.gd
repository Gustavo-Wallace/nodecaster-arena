extends CharacterBody2D

signal died(enemy: Node)
signal damage_taken(enemy: Node, amount: int, world_position: Vector2)

@export var speed: float = 140.0
@export var max_health: int = 40
@export var enemy_id: String = "enemy"
@export var enemy_display_name: String = "Enemy"
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
var _hit_tween: Tween
var _burn_time_left: float = 0.0
var _burn_tick_left: float = 0.0
var _burn_damage: int = 0
var _slow_time_left: float = 0.0
var _slow_multiplier: float = 1.0


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
	_update_elemental_effects(delta)
	_update_behavior(delta)
	velocity *= _slow_multiplier
	move_and_slide()
	_try_damage_player()


func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	damage_taken.emit(self, amount, global_position)
	_play_hit_feedback()
	queue_redraw()

	if current_health == 0:
		_die()


func apply_elemental_effect(effect_id: String, effect_power: float, source_damage: int) -> void:
	match effect_id:
		"burn":
			_burn_time_left = maxf(_burn_time_left, 1.8)
			_burn_tick_left = minf(_burn_tick_left, 0.22)
			_burn_damage = maxi(_burn_damage, maxi(1, int(round(float(source_damage) * effect_power))))
		"slow":
			_slow_time_left = maxf(_slow_time_left, 1.4)
			_slow_multiplier = minf(_slow_multiplier, clampf(effect_power, 0.35, 0.92))
	queue_redraw()


func _update_elemental_effects(delta: float) -> void:
	if _burn_time_left > 0.0:
		_burn_time_left = maxf(_burn_time_left - delta, 0.0)
		_burn_tick_left = maxf(_burn_tick_left - delta, 0.0)
		if _burn_tick_left <= 0.0 and _burn_damage > 0:
			_burn_tick_left = 0.6
			take_damage(_burn_damage)
			if _is_dead:
				return

	if _slow_time_left > 0.0:
		_slow_time_left = maxf(_slow_time_left - delta, 0.0)
		if _slow_time_left <= 0.0:
			_slow_multiplier = 1.0

	queue_redraw()


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


func _play_hit_feedback() -> void:
	if is_instance_valid(_hit_tween):
		_hit_tween.kill()

	scale = Vector2.ONE * 1.16
	modulate = Color(1.45, 1.45, 1.45, 1.0)

	_hit_tween = create_tween()
	_hit_tween.set_parallel(true)
	_hit_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(self, "modulate", Color.WHITE, 0.12)


func _update_collision_shape() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius


func _draw() -> void:
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(current_health) / float(max_health)

	_draw_enemy_shape(health_ratio)
	_draw_elemental_feedback()
	_draw_health_arc(health_ratio)


func _draw_elemental_feedback() -> void:
	if _burn_time_left > 0.0:
		var pulse := 1.08 + sin(float(Time.get_ticks_msec()) * 0.018) * 0.08
		draw_arc(Vector2.ZERO, radius * pulse + 5.0, 0.0, TAU, 24, Color(1.0, 0.38, 0.1, 0.92), 2.0, true)
	if _slow_time_left > 0.0:
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 24, Color(0.48, 0.88, 1.0, 0.88), 2.0, true)


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
