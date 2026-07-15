extends Node2D

const NEON_STYLE := preload("res://scripts/ui/neon_style.gd")

@export var duration: float = 0.72
@export var rise_distance: float = 38.0
@export var drift: Vector2 = Vector2.ZERO

@onready var label: Label = $Label

var _time_left: float
var _start_position: Vector2
var _end_position: Vector2
var _text := "0"
var _color := Color.WHITE


func _ready() -> void:
	_time_left = duration
	_start_position = global_position
	_end_position = global_position + Vector2(drift.x, -rise_distance + drift.y)
	_apply_label()


func setup(text: String, world_position: Vector2, color: Color = Color.WHITE, new_duration: float = 0.72) -> void:
	_text = text
	_color = color
	global_position = world_position
	duration = new_duration
	_time_left = duration
	_start_position = world_position
	_end_position = world_position + Vector2(drift.x, -rise_distance + drift.y)

	if is_node_ready():
		_apply_label()


func _process(delta: float) -> void:
	_time_left -= delta
	var progress := 1.0 - clampf(_time_left / duration, 0.0, 1.0)

	global_position = _start_position.lerp(_end_position, progress)
	scale = Vector2.ONE * (1.0 + 0.18 * sin(progress * PI))
	modulate.a = 1.0 - progress

	if _time_left <= 0.0:
		queue_free()


func _apply_label() -> void:
	label.text = _text
	label.add_theme_color_override("font_color", _color)
	label.add_theme_color_override("font_shadow_color", Color(NEON_STYLE.BACKGROUND.r, NEON_STYLE.BACKGROUND.g, NEON_STYLE.BACKGROUND.b, 0.94))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 18)
