extends CharacterBody2D

signal died(enemy: Node)

@export var speed: float = 145.0
@export var max_health: int = 40
@export var contact_damage: int = 10
@export var contact_damage_cooldown: float = 0.65
@export var radius: float = 16.0
@export var contact_distance: float = 40.0
@export var fill_color: Color = Color(1.0, 0.28, 0.34)
@export var outline_color: Color = Color(1.0, 0.76, 0.68)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_health: int
var player: Node2D
var _contact_cooldown_left: float = 0.0
var _is_dead: bool = false


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_update_collision_radius()
	queue_redraw()


func setup(target_player: Node2D) -> void:
	player = target_player


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_contact_cooldown_left = maxf(_contact_cooldown_left - delta, 0.0)

	if is_instance_valid(player):
		var direction := global_position.direction_to(player.global_position)
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_try_damage_player()


func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	queue_redraw()

	if current_health == 0:
		_die()


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


func _update_collision_radius() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius


func _draw() -> void:
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(current_health) / float(max_health)

	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, outline_color, 2.0, true)
	draw_arc(Vector2.ZERO, radius + 5.0, -PI / 2.0, -PI / 2.0 + TAU * health_ratio, 32, Color(1.0, 0.95, 0.62), 2.0, true)
