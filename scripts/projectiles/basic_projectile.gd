extends Area2D

@export var speed: float = 520.0
@export var damage: int = 12
@export var pierce_left: int = 0
@export var lifetime: float = 1.6
@export var radius: float = 6.0
@export var fill_color: Color = Color(1.0, 0.92, 0.28)
@export var outline_color: Color = Color(1.0, 1.0, 0.82)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var direction: Vector2 = Vector2.RIGHT
var _life_left: float


func _ready() -> void:
	add_to_group("player_projectiles")
	_life_left = lifetime
	body_entered.connect(_on_body_entered)
	_update_collision_radius()
	queue_redraw()


func setup(spawn_position: Vector2, target_position: Vector2) -> void:
	global_position = spawn_position
	direction = spawn_position.direction_to(target_position)

	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_life_left -= delta

	if _life_left <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return

	if body.has_method("take_damage"):
		body.call("take_damage", damage)

	if pierce_left <= 0:
		queue_free()
	else:
		pierce_left -= 1


func _update_collision_radius() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, outline_color, 1.5, true)
