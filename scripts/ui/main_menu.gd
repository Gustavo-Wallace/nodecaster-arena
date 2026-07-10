extends Control

@onready var play_button: Button = $Panel/PlayButton
@onready var quit_button: Button = $Panel/QuitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


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
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
