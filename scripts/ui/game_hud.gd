extends Control

@onready var health_label: Label = $HealthLabel


func _ready() -> void:
	health_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
	health_label.add_theme_font_size_override("font_size", 24)


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
