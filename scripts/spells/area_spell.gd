extends Node2D

signal pulse_requested(world_position: Vector2, pulse_radius: float, damage: int, effect_id: String, effect_power: float)

@export var duration: float = 2.5
@export var tick_interval: float = 0.5
@export var radius: float = 78.0
@export var damage: int = 4
@export var visual_shape: String = "circle"
@export var fill_color: Color = Color(0.74, 0.36, 1.0)
@export var outline_color: Color = Color(1.0, 0.78, 1.0)
@export var element_effect_id: String = "direct"
@export var element_effect_power: float = 0.0

var _time_left: float = 0.0
var _tick_left: float = 0.0
var _pulse_strength: float = 0.0
var _is_expiring := false


func _ready() -> void:
	_time_left = duration
	_tick_left = 0.12
	scale = Vector2.ONE * 0.72
	var appear_tween := create_tween()
	appear_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func setup(world_position: Vector2, new_radius: float, new_duration: float, new_tick_interval: float, new_damage: int, shape_id: String, primary: Color, secondary: Color, effect_id: String, effect_power: float) -> void:
	global_position = world_position
	radius = new_radius
	duration = new_duration
	tick_interval = new_tick_interval
	damage = new_damage
	visual_shape = shape_id
	fill_color = primary
	outline_color = secondary
	element_effect_id = effect_id
	element_effect_power = effect_power

	if is_node_ready():
		_time_left = duration
		_tick_left = 0.12
		queue_redraw()


func _process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	_tick_left = maxf(_tick_left - delta, 0.0)
	_pulse_strength = maxf(_pulse_strength - delta * 3.4, 0.0)

	if _tick_left <= 0.0 and _time_left > 0.0:
		_tick_left = tick_interval
		_pulse_strength = 1.0
		pulse_requested.emit(global_position, radius, damage, element_effect_id, element_effect_power)

	if _time_left <= 0.0 and not _is_expiring:
		_is_expiring = true
		var expire_tween := create_tween()
		expire_tween.set_parallel(true)
		expire_tween.tween_property(self, "modulate:a", 0.0, 0.16)
		expire_tween.tween_property(self, "scale", Vector2.ONE * 0.82, 0.16)
		expire_tween.chain().tween_callback(queue_free)

	queue_redraw()


func _draw() -> void:
	var pulse_scale := 1.0 + _pulse_strength * 0.08
	var fill_alpha := 0.13 + _pulse_strength * 0.1
	var fill := Color(fill_color.r, fill_color.g, fill_color.b, fill_alpha)
	var outline := Color(outline_color.r, outline_color.g, outline_color.b, 0.8 + _pulse_strength * 0.16)
	draw_circle(Vector2.ZERO, radius * pulse_scale * 1.13, Color(fill_color.r, fill_color.g, fill_color.b, 0.055 + _pulse_strength * 0.05))

	match visual_shape:
		"triangle":
			var triangle := PackedVector2Array([
				Vector2(0.0, -radius * pulse_scale),
				Vector2(radius * 0.94 * pulse_scale, radius * 0.78 * pulse_scale),
				Vector2(-radius * 0.94 * pulse_scale, radius * 0.78 * pulse_scale),
			])
			draw_colored_polygon(triangle, fill)
			draw_polyline(PackedVector2Array([triangle[0], triangle[1], triangle[2], triangle[0]]), outline, 2.4, true)
		"square":
			var side := radius * 1.55 * pulse_scale
			var square := Rect2(Vector2(-side, -side) * 0.5, Vector2(side, side))
			draw_rect(square, fill, true)
			draw_rect(square, outline, false, 2.4, true)
		_:
			draw_circle(Vector2.ZERO, radius * pulse_scale, fill)
			draw_arc(Vector2.ZERO, radius * pulse_scale, 0.0, TAU, 40, outline, 2.4, true)

	draw_arc(Vector2.ZERO, radius * (0.55 + _pulse_strength * 0.25), 0.0, TAU, 28, Color(fill_color.r, fill_color.g, fill_color.b, 0.3 + _pulse_strength * 0.22), 1.4, true)
	draw_arc(Vector2.ZERO, radius * pulse_scale * 1.06, 0.0, TAU, 40, Color(fill_color.r, fill_color.g, fill_color.b, 0.22), 1.0, true)
