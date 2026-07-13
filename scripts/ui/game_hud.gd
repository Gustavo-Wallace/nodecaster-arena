extends Control

signal graph_requested

@onready var health_label: Label = $HealthLabel
@onready var health_bar_fill: ColorRect = $HealthBarFill
@onready var wave_label: Label = $WaveLabel
@onready var enemies_label: Label = $EnemiesLabel
@onready var score_label: Label = $ScoreLabel
@onready var time_label: Label = $TimeLabel
@onready var meta_label: Label = $MetaLabel
@onready var build_label: Label = $BuildLabel
@onready var graph_button: Button = $GraphButton
@onready var message_label: Label = $MessageLabel

const HEALTH_BAR_WIDTH := 264.0

var _last_health := -1
var _health_tween: Tween
var _message_tween: Tween


func _ready() -> void:
	for label in [health_label, wave_label, enemies_label, score_label, time_label, meta_label, build_label, message_label]:
		label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
		label.add_theme_font_size_override("font_size", 20)

	wave_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.58))
	message_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48))
	message_label.add_theme_font_size_override("font_size", 24)
	meta_label.add_theme_color_override("font_color", Color(0.56, 0.9, 1.0))
	meta_label.add_theme_font_size_override("font_size", 15)
	build_label.add_theme_color_override("font_color", Color(0.76, 0.76, 1.0))
	build_label.add_theme_font_size_override("font_size", 14)
	graph_button.pressed.connect(_on_graph_pressed)
	graph_button.focus_mode = Control.FOCUS_NONE
	set_wave_info(0, 0, 0)
	set_wave_message("")
	set_meta_info("")
	set_build_summary(0, 0)
	set_run_time(0.0)


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
	health_label.text = "HEALTH %d / %d" % [current_health, max_health]
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = clampf(float(current_health) / float(max_health), 0.0, 1.0)

	health_bar_fill.size = Vector2(HEALTH_BAR_WIDTH * health_ratio, health_bar_fill.size.y)
	if health_ratio <= 0.3:
		health_bar_fill.color = Color(1.0, 0.26, 0.22)
	elif health_ratio <= 0.6:
		health_bar_fill.color = Color(1.0, 0.72, 0.28)
	else:
		health_bar_fill.color = Color(0.32, 0.95, 0.62)

	if _last_health >= 0 and current_health < _last_health:
		_flash_health_bar()
	_last_health = current_health


func set_wave_info(wave_number: int, enemies_remaining: int, score: int, max_wave: int = 0, wave_title: String = "") -> void:
	if max_wave > 0:
		wave_label.text = "WAVE %d/%d" % [wave_number, max_wave]
	else:
		wave_label.text = "WAVE %d" % wave_number

	if not wave_title.is_empty():
		wave_label.text += " - %s" % wave_title

	enemies_label.text = "ENEMIES %d" % enemies_remaining
	score_label.text = "SCORE %d" % score


func set_run_time(seconds: float) -> void:
	var total_seconds := int(seconds)
	var minutes := int(total_seconds / 60)
	var remaining_seconds := total_seconds % 60
	time_label.text = "TIME %02d:%02d" % [minutes, remaining_seconds]


func set_meta_info(info: String) -> void:
	meta_label.text = info


func set_build_summary(node_count: int, synergy_count: int) -> void:
	build_label.text = "NODES %d | SYNERGIES %d" % [node_count, synergy_count]


func _on_graph_pressed() -> void:
	graph_requested.emit()


func set_wave_message(message: String) -> void:
	message_label.text = message
	if is_instance_valid(_message_tween):
		_message_tween.kill()

	if message.is_empty():
		return

	message_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	message_label.scale = Vector2.ONE * 0.96
	_message_tween = create_tween()
	_message_tween.set_parallel(true)
	_message_tween.tween_property(message_label, "modulate", Color.WHITE, 0.18)
	_message_tween.tween_property(message_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _flash_health_bar() -> void:
	if is_instance_valid(_health_tween):
		_health_tween.kill()

	health_bar_fill.modulate = Color(1.6, 1.6, 1.6, 1.0)
	_health_tween = create_tween()
	_health_tween.tween_property(health_bar_fill, "modulate", Color.WHITE, 0.18)
