extends Node2D

signal hit_requested(enemy: Node2D, damage: int, effect_id: String, effect_power: float, empowered: bool)

var owner_player: Node2D
var lifetime: float = 7.0
var attack_range: float = 280.0
var attack_interval: float = 0.9
var damage: int = 4
var move_speed: float = 140.0
var visual_shape: String = "circle"
var fill_color: Color = Color(0.77, 0.36, 1.0)
var outline_color: Color = Color(1.0, 0.78, 1.0)
var element_effect_id: String = "direct"
var element_effect_power: float = 0.0
var empowered_interval: int = 0
var empowered_damage_multiplier: float = 1.25

var _time_left: float = 0.0
var _attack_left: float = 0.04
var _attack_count: int = 0
var _anchor_offset: Vector2 = Vector2.ZERO
var _bolt_start := Vector2.ZERO
var _bolt_end := Vector2.ZERO
var _bolt_time: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(spawn_position: Vector2, player_node: Node2D, parameters: Dictionary) -> void:
	global_position = spawn_position
	owner_player = player_node
	lifetime = float(parameters.get("lifetime", lifetime))
	attack_range = float(parameters.get("attack_range", attack_range))
	attack_interval = float(parameters.get("attack_interval", attack_interval))
	damage = int(parameters.get("damage", damage))
	move_speed = float(parameters.get("move_speed", move_speed))
	visual_shape = str(parameters.get("visual_shape", visual_shape))
	fill_color = parameters.get("fill_color", fill_color)
	outline_color = parameters.get("outline_color", outline_color)
	element_effect_id = str(parameters.get("element_effect_id", element_effect_id))
	element_effect_power = float(parameters.get("element_effect_power", element_effect_power))
	empowered_interval = int(parameters.get("empowered_interval", empowered_interval))
	empowered_damage_multiplier = float(parameters.get("empowered_damage_multiplier", empowered_damage_multiplier))
	_rng.randomize()
	_anchor_offset = Vector2.from_angle(_rng.randf_range(0.0, TAU)) * _rng.randf_range(30.0, 72.0)
	_attack_left = 0.04
	if is_node_ready():
		_time_left = lifetime
		queue_redraw()


func _ready() -> void:
	_time_left = lifetime
	scale = Vector2.ONE * 0.35
	var appear := create_tween()
	appear.tween_property(self, "scale", Vector2.ONE * 0.68, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(owner_player):
		queue_free()
		return
	_time_left = maxf(_time_left - delta, 0.0)
	_attack_left = maxf(_attack_left - delta, 0.0)
	_bolt_time = maxf(_bolt_time - delta, 0.0)
	var target := _get_nearest_target()
	var desired_position := owner_player.global_position + _anchor_offset
	if target != null and global_position.distance_to(target.global_position) > attack_range * 0.55:
		desired_position = target.global_position - global_position.direction_to(target.global_position) * attack_range * 0.42
	global_position = global_position.move_toward(desired_position, move_speed * delta)
	if target != null and global_position.distance_to(target.global_position) <= attack_range and _attack_left <= 0.0:
		_attack_left = attack_interval
		_attack_count += 1
		var empowered := empowered_interval > 0 and _attack_count % empowered_interval == 0
		hit_requested.emit(target, maxi(1, int(round(float(damage) * (empowered_damage_multiplier if empowered else 1.0)))), element_effect_id, element_effect_power, empowered)
		_bolt_start = to_local(global_position)
		_bolt_end = to_local(target.global_position)
		_bolt_time = 0.1
	if _time_left <= 0.0:
		_expire()
	queue_redraw()


func _get_nearest_target() -> Node2D:
	var nearest: Node2D = null
	var acquisition_range := attack_range * 1.85
	var nearest_distance := acquisition_range * acquisition_range
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _expire() -> void:
	set_process(false)
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(self, "modulate:a", 0.0, 0.18)
	fade.tween_property(self, "scale", Vector2.ONE * 0.2, 0.18)
	fade.chain().tween_callback(queue_free)


func _draw() -> void:
	var alpha := clampf(_time_left / maxf(lifetime, 0.01), 0.25, 1.0)
	var fill := Color(fill_color.r, fill_color.g, fill_color.b, 0.38 * alpha)
	var outline := Color(outline_color.r, outline_color.g, outline_color.b, 0.9 * alpha)
	var radius := 14.0
	match visual_shape:
		"triangle":
			var triangle := PackedVector2Array([Vector2(0.0, -radius), Vector2(radius * 0.86, radius * 0.72), Vector2(-radius * 0.86, radius * 0.72)])
			draw_colored_polygon(triangle, fill)
			draw_polyline(PackedVector2Array([triangle[0], triangle[1], triangle[2], triangle[0]]), outline, 1.8, true)
		"square":
			var square := Rect2(Vector2(-radius, -radius), Vector2(radius * 2.0, radius * 2.0))
			draw_rect(square, fill, true)
			draw_rect(square, outline, false, 1.8, true)
		"diamond":
			var diamond := PackedVector2Array([Vector2(0.0, -radius), Vector2(radius, 0.0), Vector2(0.0, radius), Vector2(-radius, 0.0)])
			draw_colored_polygon(diamond, fill)
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline, 1.8, true)
		_:
			draw_circle(Vector2.ZERO, radius, fill)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, outline, 1.8, true)
	if _bolt_time > 0.0:
		var bolt_alpha := _bolt_time / 0.1
		draw_line(_bolt_start, _bolt_end, Color(fill_color.r, fill_color.g, fill_color.b, bolt_alpha * 0.42), 4.4)
		draw_line(_bolt_start, _bolt_end, Color(outline_color.r, outline_color.g, outline_color.b, bolt_alpha), 1.3)
