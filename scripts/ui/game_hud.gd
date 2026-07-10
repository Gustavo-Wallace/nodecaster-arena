extends Control

@onready var health_label: Label = $HealthLabel
@onready var wave_label: Label = $WaveLabel
@onready var enemies_label: Label = $EnemiesLabel
@onready var score_label: Label = $ScoreLabel
@onready var message_label: Label = $MessageLabel


func _ready() -> void:
	for label in [health_label, wave_label, enemies_label, score_label, message_label]:
		label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
		label.add_theme_font_size_override("font_size", 24)

	message_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48))
	set_wave_info(0, 0, 0)
	set_wave_message("")


func bind_player(player: Node) -> void:
	if player.has_signal("health_changed"):
		player.connect("health_changed", Callable(self, "_on_player_health_changed"))

	var current_health = player.get("current_health")
	var max_health = player.get("max_health")
	if current_health != null and max_health != null:
		_set_health_text(int(current_health), int(max_health))


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	_set_health_text(current_health, max_health)


func _set_health_text(current_health: int, max_health: int) -> void:
	health_label.text = "VIDA %d / %d" % [current_health, max_health]


func set_wave_info(wave_number: int, enemies_remaining: int, score: int) -> void:
	wave_label.text = "ONDA %d" % wave_number
	enemies_label.text = "INIMIGOS %d" % enemies_remaining
	score_label.text = "PONTOS %d" % score


func set_wave_message(message: String) -> void:
	message_label.text = message
