extends Control

signal graph_requested

const NEON_STYLE := preload("res://scripts/ui/neon_style.gd")

@onready var hud_back: Panel = $HudBack
@onready var health_label: Label = $HealthLabel
@onready var health_bar_back: ColorRect = $HealthBarBack
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
	hud_back.add_theme_stylebox_override("panel", NEON_STYLE.panel_style(Color(0.014, 0.032, 0.067, 0.9), Color(NEON_STYLE.CYAN.r, NEON_STYLE.CYAN.g, NEON_STYLE.CYAN.b, 0.56), 1, 6))
	health_bar_back.color = Color(0.025, 0.06, 0.09, 0.96)
	for label in [health_label, wave_label, enemies_label, score_label, time_label, meta_label, build_label, message_label]:
		label.add_theme_color_override("font_color", NEON_STYLE.TEXT_PRIMARY)
		label.add_theme_font_size_override("font_size", 20)

	wave_label.add_theme_color_override("font_color", NEON_STYLE.WARNING)
	message_label.add_theme_color_override("font_color", NEON_STYLE.MAGENTA)
	message_label.add_theme_font_size_override("font_size", 24)
	meta_label.add_theme_color_override("font_color", NEON_STYLE.CYAN)
	meta_label.add_theme_font_size_override("font_size", 15)
	build_label.add_theme_color_override("font_color", Color(0.72, 0.72, 1.0, 1.0))
	build_label.add_theme_font_size_override("font_size", 14)
	graph_button.pressed.connect(_on_graph_pressed)
	graph_button.focus_mode = Control.FOCUS_NONE
	graph_button.add_theme_color_override("font_color", NEON_STYLE.TEXT_PRIMARY)
	graph_button.add_theme_stylebox_override("normal", NEON_STYLE.button_style(Color(0.025, 0.07, 0.11, 0.96), Color(NEON_STYLE.CYAN.r, NEON_STYLE.CYAN.g, NEON_STYLE.CYAN.b, 0.72)))
	graph_button.add_theme_stylebox_override("hover", NEON_STYLE.button_style(Color(0.05, 0.12, 0.18, 1.0), NEON_STYLE.CYAN))
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
		health_bar_fill.color = NEON_STYLE.DANGER
	elif health_ratio <= 0.6:
		health_bar_fill.color = NEON_STYLE.WARNING
	else:
		health_bar_fill.color = NEON_STYLE.HEALTH

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
