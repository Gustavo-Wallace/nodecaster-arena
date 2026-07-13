extends Area2D

signal explosion_requested(world_position: Vector2, radius: float, damage: int)
signal bounce_requested(world_position: Vector2)

@export var speed: float = 520.0
@export var damage: int = 12
@export var pierce_left: int = 0
@export var bounce_left: int = 0
@export var explosion_radius: float = 0.0
@export var explosion_damage: int = 0
@export var size_multiplier: float = 1.0
@export var visual_shape: String = "circle"
@export var lifetime: float = 1.6
@export var radius: float = 6.0
@export var fill_color: Color = Color(1.0, 0.92, 0.28)
@export var outline_color: Color = Color(1.0, 1.0, 0.82)
@export var trail_style: String = "standard"
@export var glow_strength: float = 0.0
@export var element_effect_id: String = "direct"
@export var element_effect_power: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var direction: Vector2 = Vector2.RIGHT
var arena_rect: Rect2
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
	_try_bounce()
	_life_left -= delta
	queue_redraw()

	if _life_left <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return

	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	if body.has_method("apply_elemental_effect") and element_effect_id != "direct":
		body.call("apply_elemental_effect", element_effect_id, element_effect_power, damage)

	if explosion_radius > 0.0 and explosion_damage > 0:
		explosion_requested.emit(global_position, explosion_radius, explosion_damage)

	if pierce_left <= 0:
		queue_free()
	else:
		pierce_left -= 1


func _try_bounce() -> void:
	if arena_rect.size == Vector2.ZERO:
		return

	if arena_rect.has_point(global_position):
		return

	if bounce_left <= 0:
		queue_free()
		return

	var bounced := false
	if global_position.x < arena_rect.position.x or global_position.x > arena_rect.end.x:
		direction.x *= -1.0
		global_position.x = clampf(global_position.x, arena_rect.position.x, arena_rect.end.x)
		bounced = true
	if global_position.y < arena_rect.position.y or global_position.y > arena_rect.end.y:
		direction.y *= -1.0
		global_position.y = clampf(global_position.y, arena_rect.position.y, arena_rect.end.y)
		bounced = true

	if bounced:
		bounce_left -= 1
		rotation = direction.angle()
		modulate = Color(1.25, 1.25, 1.25, 1.0)
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.12)
		bounce_requested.emit(global_position)


func _update_collision_radius() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius * size_multiplier


func _draw() -> void:
	var draw_radius := radius * size_multiplier
	var trail_length := clampf(speed * 0.075, 28.0, 74.0) * maxf(size_multiplier, 0.85)
	var trail_width := maxf(2.0, draw_radius * 0.62)
	var trail_color := Color(fill_color.r, fill_color.g, fill_color.b, 0.34)
	match trail_style:
		"cutting":
			draw_line(Vector2(-trail_length, -trail_width * 0.42), Vector2(-draw_radius * 0.2, 0.0), trail_color, maxf(1.5, trail_width * 0.62))
			draw_line(Vector2(-trail_length * 0.82, trail_width * 0.42), Vector2(-draw_radius * 0.2, 0.0), Color(outline_color.r, outline_color.g, outline_color.b, 0.3), maxf(1.0, trail_width * 0.34))
		"piercing":
			draw_line(Vector2(-trail_length * 1.15, 0.0), Vector2(-draw_radius * 0.2, 0.0), Color(outline_color.r, outline_color.g, outline_color.b, 0.5), maxf(1.2, trail_width * 0.46))
		"spark":
			draw_line(Vector2(-trail_length, 0.0), Vector2(-draw_radius * 0.5, 0.0), trail_color, trail_width)
			draw_circle(Vector2(-trail_length * 0.45, -trail_width), maxf(1.5, draw_radius * 0.22), outline_color)
			draw_circle(Vector2(-trail_length * 0.72, trail_width * 0.7), maxf(1.2, draw_radius * 0.16), outline_color)
		_:
			draw_line(Vector2(-trail_length, 0.0), Vector2(-draw_radius * 0.5, 0.0), trail_color, trail_width)
			draw_line(Vector2(-trail_length * 0.62, 0.0), Vector2(-draw_radius * 0.2, 0.0), Color(outline_color.r, outline_color.g, outline_color.b, 0.22), maxf(1.0, trail_width * 0.42))

	if glow_strength > 0.0:
		draw_circle(Vector2.ZERO, draw_radius * (1.45 + glow_strength * 0.3), Color(fill_color.r, fill_color.g, fill_color.b, 0.09 + glow_strength * 0.08))

	match visual_shape:
		"triangle":
			var triangle_points := PackedVector2Array([
				Vector2(draw_radius * 1.15, 0.0),
				Vector2(-draw_radius * 0.8, -draw_radius * 0.86),
				Vector2(-draw_radius * 0.8, draw_radius * 0.86),
			])
			draw_colored_polygon(triangle_points, fill_color)
			draw_polyline(PackedVector2Array([triangle_points[0], triangle_points[1], triangle_points[2], triangle_points[0]]), outline_color, 1.5)
		"square":
			var side := draw_radius * 1.72
			var square_rect := Rect2(Vector2(-side, -side) * 0.5, Vector2(side, side))
			draw_rect(square_rect, fill_color, true)
			draw_rect(square_rect, outline_color, false, 1.5)
		"diamond":
			var points := PackedVector2Array([
				Vector2(0.0, -draw_radius),
				Vector2(draw_radius * 0.9, 0.0),
				Vector2(0.0, draw_radius),
				Vector2(-draw_radius * 0.9, 0.0),
			])
			draw_colored_polygon(points, fill_color)
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), outline_color, 1.5)
		_:
			draw_circle(Vector2.ZERO, draw_radius, fill_color)
			draw_arc(Vector2.ZERO, draw_radius, 0.0, TAU, 24, outline_color, 1.5, true)
