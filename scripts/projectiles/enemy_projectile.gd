extends Area2D

@export var speed: float = 240.0
@export var damage: int = 10
@export var lifetime: float = 3.0
@export var radius: float = 7.0
@export var bounds_margin: float = 120.0
@export var fill_color: Color = Color(1.0, 0.25, 0.62)
@export var outline_color: Color = Color(1.0, 0.78, 0.92)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var direction: Vector2 = Vector2.RIGHT
var _life_left: float


func _ready() -> void:
	add_to_group("enemy_projectiles")
	_life_left = lifetime
	body_entered.connect(_on_body_entered)
	_update_collision_radius()
	queue_redraw()


func setup(spawn_position: Vector2, new_direction: Vector2, new_damage: int = 10, new_speed: float = 240.0) -> void:
	global_position = spawn_position
	direction = new_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	damage = new_damage
	speed = new_speed
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_life_left -= delta

	if _life_left <= 0.0 or _is_far_outside_view():
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.call("take_damage", damage)

	queue_free()


func _update_collision_radius() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius


func _is_far_outside_view() -> bool:
	var viewport_rect := get_viewport_rect().grow(bounds_margin)
	return not viewport_rect.has_point(global_position)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, outline_color, 1.5, true)
