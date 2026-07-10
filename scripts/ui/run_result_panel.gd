extends Control

signal restart_requested

@onready var title_label: Label = $Panel/TitleLabel
@onready var subtitle_label: Label = $Panel/SubtitleLabel
@onready var stats_label: Label = $Panel/StatsLabel
@onready var kills_label: Label = $Panel/KillsLabel
@onready var build_label: Label = $Panel/BuildLabel
@onready var restart_button: Button = $Panel/RestartButton


func _ready() -> void:
	hide()
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))

	for label in [subtitle_label, stats_label, kills_label, build_label]:
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))

	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restart_button.pressed.connect(_on_restart_pressed)


func show_result(victory: bool, stats: Dictionary, max_wave: int) -> void:
	title_label.text = "VITORIA" if victory else "DERROTA"
	title_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.78) if victory else Color(1.0, 0.46, 0.46))
	subtitle_label.text = "Simulacao concluida. Voce estabilizou o nucleo." if victory else "Nucleo desintegrado. A cadeia arcana entrou em colapso."

	var wave_reached := int(stats.get("max_wave_reached", 0))
	var final_score := int(stats.get("final_score", 0))
	var run_time := float(stats.get("run_time_seconds", 0.0))
	var total_enemies := int(stats.get("total_enemies_defeated", 0))
	var upgrades_chosen := int(stats.get("upgrades_chosen", 0))

	stats_label.text = "Onda: %d/%d\nPontuacao: %d\nTempo: %s\nInimigos derrotados: %d\nUpgrades escolhidos: %d" % [
		wave_reached,
		max_wave,
		final_score,
		_format_time(run_time),
		total_enemies,
		upgrades_chosen,
	]

	kills_label.text = _format_kill_breakdown(stats)
	build_label.text = "Build: %s" % _format_build(stats)
	show()


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _format_time(seconds: float) -> String:
	var total_seconds := int(round(seconds))
	var minutes := int(total_seconds / 60)
	var remaining_seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _format_kill_breakdown(stats: Dictionary) -> String:
	var kills = stats.get("enemy_kills", {})
	var miniboss_text := "Derrotado" if bool(stats.get("miniboss_defeated", false)) else "Nao derrotado"
	var boss_text := "Derrotado" if bool(stats.get("boss_defeated", false)) else "Nao derrotado"

	return "Circulos: %d  Triangulos: %d  Quadrados: %d\nMini-Boss: %s  Boss: %s" % [
		int(kills.get("circle_chaser", 0)),
		int(kills.get("triangle_dasher", 0)),
		int(kills.get("square_tank", 0)),
		miniboss_text,
		boss_text,
	]


func _format_build(stats: Dictionary) -> String:
	var build_nodes = stats.get("build_nodes", [])
	if build_nodes.is_empty():
		return "Projetil"

	var labels: Array[String] = []
	for node_label in build_nodes:
		labels.append(str(node_label))

	var build_text := ""
	for index in range(labels.size()):
		if index > 0:
			build_text += " -> "
		build_text += labels[index]

	return build_text
