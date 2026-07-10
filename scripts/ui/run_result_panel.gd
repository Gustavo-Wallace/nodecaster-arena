extends Control

signal restart_requested

@onready var title_label: Label = $Panel/TitleLabel
@onready var details_label: Label = $Panel/DetailsLabel
@onready var restart_button: Button = $Panel/RestartButton


func _ready() -> void:
	hide()
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
	details_label.add_theme_font_size_override("font_size", 22)
	details_label.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	restart_button.pressed.connect(_on_restart_pressed)


func show_result(victory: bool, wave_reached: int, max_wave: int, final_score: int) -> void:
	title_label.text = "VITORIA" if victory else "DERROTA"
	title_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.78) if victory else Color(1.0, 0.46, 0.46))
	details_label.text = "Onda %d/%d\nPontuacao final: %d\nPressione R para reiniciar" % [wave_reached, max_wave, final_score]
	show()


func _on_restart_pressed() -> void:
	restart_requested.emit()
