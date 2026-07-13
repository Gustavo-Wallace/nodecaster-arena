extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int, world_position: Vector2)
signal shield_changed(charges: int)
signal shield_absorbed(world_position: Vector2)
signal died

@export var speed: float = 320.0
@export var max_health: int = 100
@export var radius: float = 18.0
@export var visual_shape: String = "circle"
@export var fill_color: Color = Color(0.18, 0.78, 1.0)
@export var outline_color: Color = Color(0.82, 0.98, 1.0)
@export_range(0.1, 1.0, 0.01) var incoming_damage_multiplier: float = 1.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_health: int
var arena_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
var _is_dead: bool = false
var _hit_tween: Tween
var shield_charges: int = 0
var post_hit_invulnerability_duration: float = 0.0
var _damage_invulnerability_left: float = 0.0


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

	_damage_invulnerability_left = maxf(_damage_invulnerability_left - _delta, 0.0)
	velocity = _read_movement_input() * speed
	move_and_slide()
	_clamp_to_arena()


func set_arena_rect(new_arena_rect: Rect2) -> void:
	arena_rect = new_arena_rect
	_clamp_to_arena()


func apply_character_data(character_data: Dictionary) -> void:
	speed = float(character_data.get("move_speed", speed))
	max_health = int(character_data.get("max_health", max_health))
	current_health = max_health
	visual_shape = str(character_data.get("visual_shape", visual_shape))
	fill_color = character_data.get("fill_color", fill_color)
	outline_color = character_data.get("outline_color", outline_color)
	health_changed.emit(current_health, max_health)
	queue_redraw()


func apply_elemental_identity(fill: Color, outline: Color) -> void:
	fill_color = fill
	outline_color = outline
	queue_redraw()


func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0 or _damage_invulnerability_left > 0.0:
		return

	if shield_charges > 0:
		shield_charges -= 1
		shield_changed.emit(shield_charges)
		shield_absorbed.emit(global_position)
		_damage_invulnerability_left = 0.12
		_play_shield_feedback()
		queue_redraw()
		return

	var final_amount := maxi(int(ceil(float(amount) * incoming_damage_multiplier)), 1)
	current_health = maxi(current_health - final_amount, 0)
	_damage_invulnerability_left = post_hit_invulnerability_duration
	health_changed.emit(current_health, max_health)
	damage_taken.emit(final_amount, global_position)
	_play_hit_feedback()

	if current_health == 0:
		_die()


func heal(amount: int) -> void:
	if _is_dead or amount <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func increase_max_health(amount: int, heal_amount: int) -> void:
	if _is_dead or amount <= 0:
		return

	max_health += amount
	current_health = mini(current_health + heal_amount, max_health)
	health_changed.emit(current_health, max_health)


func grant_shield(charges: int = 1) -> void:
	if _is_dead or charges <= 0:
		return

	shield_charges += charges
	shield_changed.emit(shield_charges)
	queue_redraw()


func set_shield_charges(charges: int) -> void:
	if _is_dead:
		return

	shield_charges = maxi(charges, 0)
	shield_changed.emit(shield_charges)
	queue_redraw()


func set_post_hit_invulnerability(duration: float) -> void:
	post_hit_invulnerability_duration = maxf(duration, 0.0)


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


func _play_hit_feedback() -> void:
	if is_instance_valid(_hit_tween):
		_hit_tween.kill()

	scale = Vector2.ONE * 1.12
	modulate = Color(1.0, 0.42, 0.42, 1.0)

	_hit_tween = create_tween()
	_hit_tween.set_parallel(true)
	_hit_tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(self, "modulate", Color.WHITE, 0.16)


func _play_shield_feedback() -> void:
	if is_instance_valid(_hit_tween):
		_hit_tween.kill()

	modulate = Color(0.52, 0.95, 1.0, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(self, "modulate", Color.WHITE, 0.18)


func _update_collision_radius() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius


func _draw() -> void:
	match visual_shape:
		"triangle":
			var points := PackedVector2Array([
				Vector2(0.0, -radius),
				Vector2(radius * 0.92, radius * 0.78),
				Vector2(-radius * 0.92, radius * 0.78),
			])
			draw_colored_polygon(points, fill_color)
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), outline_color, 2.5)
		"diamond":
			var points := PackedVector2Array([
				Vector2(0.0, -radius),
				Vector2(radius * 0.82, 0.0),
				Vector2(0.0, radius),
				Vector2(-radius * 0.82, 0.0),
			])
			draw_colored_polygon(points, fill_color)
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), outline_color, 2.5)
		"square":
			var side := radius * 1.62
			var rect := Rect2(Vector2(-side * 0.5, -side * 0.5), Vector2(side, side))
			draw_rect(rect, fill_color, true)
			draw_rect(rect, outline_color, false, 2.5)
		_:
			draw_circle(Vector2.ZERO, radius, fill_color)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, outline_color, 2.5, true)

	draw_circle(Vector2.ZERO, radius * 0.28, Color(1.0, 1.0, 1.0, 0.9))
	if shield_charges > 0:
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 40, Color(0.46, 0.94, 1.0, 0.9), 2.5, true)
		draw_arc(Vector2.ZERO, radius + 12.0, -PI * 0.6, PI * 0.35, 20, Color(0.8, 1.0, 1.0, 0.55), 1.5, true)
