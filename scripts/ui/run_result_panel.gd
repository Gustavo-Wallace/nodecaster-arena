extends Control

signal restart_requested
signal main_menu_requested

@onready var title_label: Label = $Panel/TitleLabel
@onready var subtitle_label: Label = $Panel/SubtitleLabel
@onready var scroll_container: ScrollContainer = $Panel/ScrollContainer
@onready var stats_label: Label = $Panel/ScrollContainer/Content/SummaryRow/StatsLabel
@onready var kills_label: Label = $Panel/ScrollContainer/Content/SummaryRow/KillsLabel
@onready var build_label: Label = $Panel/ScrollContainer/Content/BuildLabel
@onready var restart_button: Button = $Panel/RestartButton
@onready var menu_button: Button = $Panel/MenuButton

var _open_tween: Tween


func _ready() -> void:
	hide()
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))

	for label in [subtitle_label, stats_label, kills_label, build_label]:
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func show_result(victory: bool, stats: Dictionary, max_wave: int) -> void:
	scroll_container.scroll_vertical = 0
	title_label.text = "VICTORY" if victory else "DEFEAT"
	title_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.78) if victory else Color(1.0, 0.46, 0.46))
	subtitle_label.text = "Simulation complete. You stabilized the core." if victory else "Core disintegrated. The arcane chain collapsed."

	var wave_reached := int(stats.get("max_wave_reached", 0))
	var final_score := int(stats.get("final_score", 0))
	var run_time := float(stats.get("run_time_seconds", 0.0))
	var total_enemies := int(stats.get("total_enemies_defeated", 0))
	var upgrades_chosen := int(stats.get("upgrades_chosen", 0))
	var character_name := str(stats.get("character_name", "Circle"))
	var ecos_earned := int(stats.get("ecos_earned", 0))
	var total_ecos := int(stats.get("total_ecos", 0))
	var score_record := "Yes" if bool(stats.get("new_best_score", false)) else "No"
	var wave_record := "Yes" if bool(stats.get("new_best_wave", false)) else "No"

	stats_label.text = "Form: %s\nWave: %d/%d\nScore: %d\nTime: %s\n\nEchoes: +%d / Total %d\nNew Score Record: %s\nNew Wave Record: %s\n\nEnemies Defeated: %d\nMutations: %d" % [
		character_name,
		wave_reached,
		max_wave,
		final_score,
		_format_time(run_time),
		ecos_earned,
		total_ecos,
		score_record,
		wave_record,
		total_enemies,
		upgrades_chosen,
	]

	kills_label.text = "%s\n%s" % [_format_kill_breakdown(stats), _format_modifier_breakdown(stats)]
	build_label.text = _format_build(stats)
	show()
	_play_open_animation()


func _on_restart_pressed() -> void:
	_play_audio("play_button_click")
	restart_requested.emit()


func _on_menu_pressed() -> void:
	_play_audio("play_button_click")
	main_menu_requested.emit()


func _play_open_animation() -> void:
	if is_instance_valid(_open_tween):
		_open_tween.kill()

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	scale = Vector2.ONE * 0.96
	pivot_offset = size * 0.5
	_open_tween = create_tween()
	_open_tween.set_parallel(true)
	_open_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	_open_tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _format_time(seconds: float) -> String:
	var total_seconds := int(round(seconds))
	var minutes := int(total_seconds / 60)
	var remaining_seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _format_kill_breakdown(stats: Dictionary) -> String:
	var kills = stats.get("enemy_kills", {})
	var miniboss_text := "Defeated" if bool(stats.get("miniboss_defeated", false)) else "Not Defeated"
	var boss_text := "Defeated" if bool(stats.get("boss_defeated", false)) else "Not Defeated"

	return "Circles: %d  Triangles: %d  Squares: %d\nDiamonds: %d  Bombers: %d  Snipers: %d\nMini-Boss: %s  Boss: %s" % [
		int(kills.get("circle_chaser", 0)),
		int(kills.get("triangle_dasher", 0)),
		int(kills.get("square_tank", 0)),
		int(kills.get("diamond_shooter", 0)),
		int(kills.get("star_bomber", 0)),
		int(kills.get("line_sniper", 0)),
		miniboss_text,
		boss_text,
	]


func _format_modifier_breakdown(stats: Dictionary) -> String:
	var modifiers = stats.get("wave_modifiers", [])
	var modifier_count := int(stats.get("modifier_wave_count", 0))
	if not (modifiers is Array) or modifiers.is_empty():
		return "Modifiers: none"

	var unique_labels: Array[String] = []
	for modifier in modifiers:
		var label := str(modifier)
		if not unique_labels.has(label):
			unique_labels.append(label)

	var text := ""
	for index in range(unique_labels.size()):
		if index > 0:
			text += ", "
		text += unique_labels[index]

	return "Modifiers: %d wave(s)\n%s" % [modifier_count, text]


func _format_build(stats: Dictionary) -> String:
	var graph = stats.get("spell_graph", {})
	var blueprint = stats.get("spell_blueprint", {})
	var base_spell_lines: Array[String] = []
	if blueprint is Dictionary and not blueprint.is_empty():
		base_spell_lines = [
			"Base Spell: %s" % str(blueprint.get("shape_name", "Circle")),
			"Element: %s" % str(blueprint.get("element_name", "Arcane")),
			"Cast Type: %s" % str(blueprint.get("delivery_name", "Simple Projectile")),
		]
	if graph is Dictionary and not graph.is_empty():
		var branches = graph.get("branches", {})
		var lines: Array[String] = base_spell_lines.duplicate()
		if lines.is_empty():
			lines.append("Base Spell: Branching build")
		var run_nodes: Array[String] = []
		for branch_data in [
			{"id": "form", "name": "Form"},
			{"id": "energy", "name": "Energy"},
			{"id": "rhythm", "name": "Rhythm"},
			{"id": "core", "name": "Core"},
		]:
			var labels = branches.get(str(branch_data["id"]), [])
			if labels is Array and not labels.is_empty():
				run_nodes.append("%s: %s" % [str(branch_data["name"]), ", ".join(labels)])
		lines.append("Run Nodes: " + (" | ".join(run_nodes) if not run_nodes.is_empty() else "None"))

		var graph_synergies = graph.get("synergies", [])
		lines.append("Synergies: " + (", ".join(graph_synergies) if graph_synergies is Array and not graph_synergies.is_empty() else "None"))
		return "\n".join(lines)

	var build_nodes = stats.get("build_nodes", [])
	if build_nodes.is_empty():
		return "\n".join(base_spell_lines) if not base_spell_lines.is_empty() else "Projectile"

	var labels: Array[String] = []
	for node_label in build_nodes:
		labels.append(str(node_label))

	var build_text := ""
	for index in range(labels.size()):
		if index > 0:
			build_text += " -> "
		build_text += labels[index]

	return "\n".join(base_spell_lines + ["Run Nodes: " + build_text]) if not base_spell_lines.is_empty() else build_text


func _format_synergies(stats: Dictionary) -> String:
	var synergies = stats.get("active_synergies", [])
	if not (synergies is Array) or synergies.is_empty():
		return "None"

	var labels: Array[String] = []
	for synergy in synergies:
		labels.append(str(synergy))

	var text := ""
	for index in range(labels.size()):
		if index > 0:
			text += ", "
		text += labels[index]

	return text


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)
