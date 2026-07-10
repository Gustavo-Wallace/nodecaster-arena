extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

@export var speed: float = 320.0
@export var max_health: int = 100
@export var radius: float = 18.0
@export var fill_color: Color = Color(0.18, 0.78, 1.0)
@export var outline_color: Color = Color(0.82, 0.98, 1.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_health: int
var arena_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
var _is_dead: bool = false


func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	_update_collision_radius()
	health_changed.emit(current_health, max_health)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return

	velocity = _read_movement_input() * speed
	move_and_slide()
	_clamp_to_arena()


func set_arena_rect(new_arena_rect: Rect2) -> void:
	arena_rect = new_arena_rect
	_clamp_to_arena()


func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		_die()


func _read_movement_input() -> Vector2:
	var input_vector := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0

	return input_vector.normalized()


func _clamp_to_arena() -> void:
	if arena_rect.size == Vector2.ZERO:
		return

	global_position = Vector2(
		clampf(global_position.x, arena_rect.position.x + radius, arena_rect.end.x - radius),
		clampf(global_position.y, arena_rect.position.y + radius, arena_rect.end.y - radius)
	)


func _die() -> void:
	_is_dead = true
	died.emit()


func _update_collision_radius() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, outline_color, 2.5, true)
	draw_circle(Vector2.ZERO, radius * 0.34, Color(1.0, 1.0, 1.0, 0.9))
