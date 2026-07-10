extends Control

@onready var play_button: Button = $Panel/PlayButton
@onready var progress_button: Button = $Panel/ProgressButton
@onready var options_button: Button = $Panel/OptionsButton
@onready var quit_button: Button = $Panel/QuitButton
@onready var meta_label: Label = $Panel/MetaLabel


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	progress_button.pressed.connect(_on_progress_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	for button in [play_button, progress_button, options_button, quit_button]:
		_setup_button_feedback(button)
	_update_meta_label()


func _draw() -> void:
	draw_circle(Vector2(130.0, 120.0), 42.0, Color(0.14, 0.46, 0.62, 0.28))
	draw_rect(Rect2(Vector2(1060.0, 120.0), Vector2(74.0, 74.0)), Color(0.24, 0.62, 0.38, 0.22), true)
	var points := PackedVector2Array([
		Vector2(1040.0, 560.0),
		Vector2(1115.0, 660.0),
		Vector2(965.0, 660.0),
	])
	draw_colored_polygon(points, Color(0.62, 0.25, 0.72, 0.22))


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
		meta_label.text = "Ecos: 0"
		return

	var summary: Dictionary = save_manager.call("get_summary")
	meta_label.text = "Ecos: %d   Melhor onda: %d   Vitorias: %d" % [
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
