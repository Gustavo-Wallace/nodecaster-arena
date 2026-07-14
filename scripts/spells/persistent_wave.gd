extends Node2D

signal hit_requested(enemy: Node2D, damage: int, effect_id: String, effect_power: float, first_impact: bool)

@export var speed: float = 340.0
@export var max_range: float = 500.0
@export var lifetime: float = 1.4
@export var damage: int = 9
@export var wave_width: float = 70.0
@export var wave_length: float = 28.0
@export var hit_cooldown_per_enemy: float = 0.35
@export var visual_shape: String = "circle"
@export var fill_color: Color = Color(0.77, 0.36, 1.0)
@export var outline_color: Color = Color(1.0, 0.78, 1.0)
@export var element_effect_id: String = "direct"
@export var element_effect_power: float = 0.0

var direction: Vector2 = Vector2.RIGHT
var _time_left: float = 0.0
var _distance_traveled: float = 0.0
var _elapsed_time: float = 0.0
var _next_hit_time_by_enemy: Dictionary = {}
var _had_first_impact := false


func setup(spawn_position: Vector2, new_direction: Vector2, parameters: Dictionary) -> void:
	global_position = spawn_position
	direction = new_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	speed = float(parameters.get("speed", speed))
	max_range = float(parameters.get("range", max_range))
	lifetime = float(parameters.get("lifetime", lifetime))
	damage = int(parameters.get("damage", damage))
	wave_width = float(parameters.get("width", wave_width))
	wave_length = float(parameters.get("length", wave_length))
	hit_cooldown_per_enemy = float(parameters.get("hit_cooldown", hit_cooldown_per_enemy))
	visual_shape = str(parameters.get("visual_shape", visual_shape))
	fill_color = parameters.get("fill_color", fill_color)
	outline_color = parameters.get("outline_color", outline_color)
	element_effect_id = str(parameters.get("element_effect_id", element_effect_id))
	element_effect_power = float(parameters.get("element_effect_power", element_effect_power))
	if is_node_ready():
		_time_left = lifetime
		queue_redraw()


func _ready() -> void:
	_time_left = lifetime
	scale = Vector2.ONE * 0.82
	var appear_tween := create_tween()
	appear_tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	global_position += movement
	_distance_traveled += movement.length()
	_elapsed_time += delta
	_time_left = maxf(_time_left - delta, 0.0)
	_check_enemy_hits()
	queue_redraw()

	if _time_left <= 0.0 or _distance_traveled >= max_range:
		_expire()


func _check_enemy_hits() -> void:
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not _is_enemy_inside_wave(enemy):
			continue

		var enemy_id := enemy.get_instance_id()
		var next_hit_time := float(_next_hit_time_by_enemy.get(enemy_id, 0.0))
		if _elapsed_time < next_hit_time:
			continue

		_next_hit_time_by_enemy[enemy_id] = _elapsed_time + hit_cooldown_per_enemy
		hit_requested.emit(enemy, damage, element_effect_id, element_effect_power, not _had_first_impact)
		_had_first_impact = true


func _is_enemy_inside_wave(enemy: Node2D) -> bool:
	var local_enemy_position := to_local(enemy.global_position)
	var enemy_radius := float(enemy.get("radius")) if enemy.get("radius") != null else 0.0
	return absf(local_enemy_position.x) <= wave_length * 0.5 + enemy_radius and absf(local_enemy_position.y) <= wave_width * 0.5 + enemy_radius


func _expire() -> void:
	set_physics_process(false)
	var expire_tween := create_tween()
	expire_tween.set_parallel(true)
	expire_tween.tween_property(self, "modulate:a", 0.0, 0.12)
	expire_tween.tween_property(self, "scale", Vector2(1.12, 0.82), 0.12)
	expire_tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var remaining_ratio := clampf(_time_left / maxf(lifetime, 0.001), 0.0, 1.0)
	var pulse := 1.0 + sin(_elapsed_time * 13.0) * 0.05
	var half_width := wave_width * 0.5 * pulse
	var half_length := wave_length * 0.5
	var body_color := Color(fill_color.r, fill_color.g, fill_color.b, 0.2 + remaining_ratio * 0.16)
	var line_color := Color(outline_color.r, outline_color.g, outline_color.b, 0.72 * remaining_ratio)
	var trail_color := Color(fill_color.r, fill_color.g, fill_color.b, 0.22 * remaining_ratio)

	draw_line(Vector2(-half_length - wave_length * 1.4, 0.0), Vector2(-half_length, 0.0), trail_color, maxf(3.0, wave_width * 0.12), true)
	match visual_shape:
		"triangle":
			_draw_triangle_wave(half_width, half_length, body_color, line_color)
		"square":
			_draw_square_wave(half_width, half_length, body_color, line_color)
		"diamond":
			_draw_diamond_wave(half_width, half_length, body_color, line_color)
		"star":
			_draw_star_wave(half_width, half_length, body_color, line_color)
		_:
			_draw_circle_wave(half_width, half_length, body_color, line_color)


func _draw_circle_wave(half_width: float, half_length: float, body_color: Color, line_color: Color) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(half_length / maxf(half_width, 1.0), 1.0))
	draw_circle(Vector2.ZERO, half_width, body_color)
	draw_arc(Vector2.ZERO, half_width, -PI * 0.5, PI * 0.5, 24, line_color, 2.4, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_triangle_wave(half_width: float, half_length: float, body_color: Color, line_color: Color) -> void:
	var points := PackedVector2Array([
		Vector2(half_length * 1.25, 0.0),
		Vector2(-half_length, -half_width),
		Vector2(-half_length, half_width),
	])
	draw_colored_polygon(points, body_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), line_color, 2.4, true)


func _draw_square_wave(half_width: float, half_length: float, body_color: Color, line_color: Color) -> void:
	var rect := Rect2(Vector2(-half_length, -half_width), Vector2(half_length * 2.0, half_width * 2.0))
	draw_rect(rect, body_color, true)
	draw_rect(rect, line_color, false, 2.6, true)


func _draw_diamond_wave(half_width: float, half_length: float, body_color: Color, line_color: Color) -> void:
	var points := PackedVector2Array([
		Vector2(half_length * 1.35, 0.0),
		Vector2(0.0, -half_width),
		Vector2(-half_length * 1.1, 0.0),
		Vector2(0.0, half_width),
	])
	draw_colored_polygon(points, body_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), line_color, 2.4, true)


func _draw_star_wave(half_width: float, half_length: float, body_color: Color, line_color: Color) -> void:
	_draw_circle_wave(half_width, half_length, body_color, line_color)
	for offset in [-0.55, 0.0, 0.55]:
		var origin := Vector2(offset * half_length, 0.0)
		draw_line(origin + Vector2(0.0, -half_width * 0.72), origin + Vector2(0.0, half_width * 0.72), line_color, 1.4, true)
