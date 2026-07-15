extends Control

const NEON_STYLE := preload("res://scripts/ui/neon_style.gd")

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var subtitle_label: Label = $Panel/SubtitleLabel
@onready var play_button: Button = $Panel/PlayButton
@onready var progress_button: Button = $Panel/ProgressButton
@onready var options_button: Button = $Panel/OptionsButton
@onready var quit_button: Button = $Panel/QuitButton
@onready var meta_label: Label = $Panel/MetaLabel


func _ready() -> void:
	NEON_STYLE.apply_panel(panel, NEON_STYLE.MAGENTA)
	title_label.add_theme_color_override("font_color", NEON_STYLE.TEXT_PRIMARY)
	title_label.add_theme_color_override("font_outline_color", Color(NEON_STYLE.MAGENTA.r, NEON_STYLE.MAGENTA.g, NEON_STYLE.MAGENTA.b, 0.34))
	title_label.add_theme_constant_override("outline_size", 2)
	subtitle_label.add_theme_color_override("font_color", NEON_STYLE.TEXT_MUTED)
	meta_label.add_theme_color_override("font_color", NEON_STYLE.CYAN)
	play_button.pressed.connect(_on_play_pressed)
	progress_button.pressed.connect(_on_progress_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	for button in [play_button, progress_button, options_button, quit_button]:
		NEON_STYLE.apply_button(button, NEON_STYLE.MAGENTA if button == play_button else NEON_STYLE.CYAN, button == quit_button)
		_setup_button_feedback(button)
	_update_meta_label()


func _draw() -> void:
	draw_circle(Vector2(130.0, 120.0), 84.0, Color(NEON_STYLE.CYAN.r, NEON_STYLE.CYAN.g, NEON_STYLE.CYAN.b, 0.06))
	draw_arc(Vector2(130.0, 120.0), 42.0, 0.0, TAU, 36, Color(NEON_STYLE.CYAN.r, NEON_STYLE.CYAN.g, NEON_STYLE.CYAN.b, 0.42), 2.0, true)
	draw_rect(Rect2(Vector2(1060.0, 120.0), Vector2(74.0, 74.0)), Color(NEON_STYLE.HEALTH.r, NEON_STYLE.HEALTH.g, NEON_STYLE.HEALTH.b, 0.14), true)
	draw_rect(Rect2(Vector2(1050.0, 110.0), Vector2(94.0, 94.0)), Color(NEON_STYLE.HEALTH.r, NEON_STYLE.HEALTH.g, NEON_STYLE.HEALTH.b, 0.32), false, 2.0)
	var points := PackedVector2Array([
		Vector2(1040.0, 560.0),
		Vector2(1115.0, 660.0),
		Vector2(965.0, 660.0),
	])
	draw_colored_polygon(points, Color(NEON_STYLE.MAGENTA.r, NEON_STYLE.MAGENTA.g, NEON_STYLE.MAGENTA.b, 0.13))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color(NEON_STYLE.MAGENTA.r, NEON_STYLE.MAGENTA.g, NEON_STYLE.MAGENTA.b, 0.45), 2.0, true)


func _on_play_pressed() -> void:
	_play_audio("play_button_click")
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _on_progress_pressed() -> void:
	_play_audio("play_button_click")
	get_tree().change_scene_to_file("res://scenes/ui/echo_skill_tree.tscn")


func _on_options_pressed() -> void:
	_play_audio("play_button_click")
	get_tree().change_scene_to_file("res://scenes/ui/options_menu.tscn")


func _on_quit_pressed() -> void:
	_play_audio("play_button_click")
	get_tree().quit()


func _update_meta_label() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		meta_label.text = "Echoes: 0"
		return

	var summary: Dictionary = save_manager.call("get_summary")
	meta_label.text = "Echoes: %d   Best Wave: %d   Victories: %d" % [
		int(summary.get("ecos", 0)),
		int(summary.get("best_wave", 0)),
		int(summary.get("victories", 0)),
	]


func _setup_button_feedback(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_entered.connect(_on_button_hovered.bind(button, true))
	button.mouse_exited.connect(_on_button_hovered.bind(button, false))


func _on_button_hovered(button: Button, hovered: bool) -> void:
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * (1.05 if hovered else 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)
