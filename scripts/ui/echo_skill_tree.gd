extends Control

const NODE_SIZE := Vector2(142.0, 58.0)
const TREE_OFFSET := Vector2(24.0, 42.0)

@onready var ecos_label: Label = $EcosLabel
@onready var back_button: Button = $BackButton
@onready var tree_area: Control = $TreeArea
@onready var name_label: Label = $DetailsPanel/NameLabel
@onready var branch_label: Label = $DetailsPanel/BranchLabel
@onready var description_label: Label = $DetailsPanel/DescriptionLabel
@onready var cost_label: Label = $DetailsPanel/CostLabel
@onready var status_label: Label = $DetailsPanel/StatusLabel
@onready var prerequisites_label: Label = $DetailsPanel/PrerequisitesLabel
@onready var buy_button: Button = $DetailsPanel/BuyButton

var _skills: Array[Dictionary] = []
var _skill_buttons: Dictionary = {}
var _selected_skill_id := ""


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	_setup_button_feedback(back_button)
	_setup_button_feedback(buy_button)
	_create_branch_labels()
	_refresh_tree(false)


func _draw() -> void:
	for skill in _skills:
		var skill_id := str(skill.get("id", ""))
		var prerequisites = skill.get("prerequisites", [])
		if not (prerequisites is Array or prerequisites is PackedStringArray):
			continue

		for prerequisite in prerequisites:
			var prerequisite_id := str(prerequisite)
			if not _skill_buttons.has(skill_id) or not _skill_buttons.has(prerequisite_id):
				continue

			var branch_color := _get_branch_color(str(skill.get("branch", "")))
			var line_color := Color(branch_color.r, branch_color.g, branch_color.b, 0.32)
			if bool(skill.get("purchased", false)):
				line_color.a = 0.78

			draw_line(_get_button_center(prerequisite_id), _get_button_center(skill_id), line_color, 3.0, true)


func _refresh_tree(keep_selection: bool = true) -> void:
	_clear_skill_buttons()
	_load_skills()
	_build_skill_buttons()
	_update_ecos_label()

	if not keep_selection or _selected_skill_id.is_empty() or not _skill_buttons.has(_selected_skill_id):
		_selected_skill_id = str(_skills[0].get("id", "")) if not _skills.is_empty() else ""

	_update_details()
	queue_redraw()


func _load_skills() -> void:
	_skills.clear()
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return

	var loaded_skills: Array = save_manager.call("get_skill_definitions")
	for skill in loaded_skills:
		if skill is Dictionary:
			_skills.append(skill)


func _build_skill_buttons() -> void:
	for skill in _skills:
		var button := Button.new()
		var skill_id := str(skill.get("id", ""))
		button.name = "Skill_%s" % skill_id
		button.text = str(skill.get("name", "Skill"))
		var skill_position: Vector2 = skill.get("position", Vector2.ZERO)
		button.position = TREE_OFFSET + skill_position
		button.size = NODE_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.clip_contents = true
		button.pressed.connect(_select_skill.bind(skill_id))
		button.add_theme_font_size_override("font_size", 14)
		_setup_button_feedback(button)
		_apply_skill_button_style(button, skill)
		tree_area.add_child(button)
		_skill_buttons[skill_id] = button


func _clear_skill_buttons() -> void:
	for value in _skill_buttons.values():
		var button := value as Button
		if is_instance_valid(button):
			tree_area.remove_child(button)
			button.queue_free()
	_skill_buttons.clear()


func _update_ecos_label() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		ecos_label.text = "Ecos disponiveis: 0"
		return

	var summary: Dictionary = save_manager.call("get_summary")
	ecos_label.text = "Ecos disponiveis: %d" % int(summary.get("ecos", 0))


func _select_skill(skill_id: String) -> void:
	_selected_skill_id = skill_id
	_play_audio("play_button_click")
	_update_details()
	_refresh_button_styles()
	queue_redraw()


func _update_details() -> void:
	var skill := _get_selected_skill()
	if skill.is_empty():
		name_label.text = "Nenhuma skill"
		branch_label.text = ""
		description_label.text = ""
		cost_label.text = ""
		status_label.text = ""
		prerequisites_label.text = ""
		buy_button.disabled = true
		return

	name_label.text = str(skill.get("name", "Skill"))
	branch_label.text = _format_branch(str(skill.get("branch", "")))
	description_label.text = str(skill.get("description", ""))
	cost_label.text = "Custo: %d Ecos" % int(skill.get("cost", 0))
	prerequisites_label.text = _format_prerequisites(skill)

	if bool(skill.get("purchased", false)):
		status_label.text = "Status: comprada"
		buy_button.text = "Comprada"
		buy_button.disabled = true
	elif bool(skill.get("future", false)):
		status_label.text = "Status: em breve"
		buy_button.text = "Indisponivel"
		buy_button.disabled = true
	elif bool(skill.get("can_purchase", false)):
		status_label.text = "Status: disponivel"
		buy_button.text = "Comprar"
		buy_button.disabled = false
	else:
		status_label.text = "Status: %s" % str(skill.get("locked_reason", "bloqueada")).to_lower()
		buy_button.text = "Comprar"
		buy_button.disabled = true

	var branch_color := _get_branch_color(str(skill.get("branch", "")))
	branch_label.add_theme_color_override("font_color", branch_color)


func _on_buy_pressed() -> void:
	if _selected_skill_id.is_empty():
		return

	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return

	var purchased := bool(save_manager.call("purchase_skill", _selected_skill_id))
	_play_audio("play_unlock" if purchased else "play_error")
	_refresh_tree(true)
	_pulse_selected_button()


func _get_selected_skill() -> Dictionary:
	for skill in _skills:
		if str(skill.get("id", "")) == _selected_skill_id:
			return skill

	return {}


func _get_skill_name(skill_id: String) -> String:
	for skill in _skills:
		if str(skill.get("id", "")) == skill_id:
			return str(skill.get("name", skill_id))

	return skill_id


func _format_prerequisites(skill: Dictionary) -> String:
	var prerequisites = skill.get("prerequisites", [])
	if not (prerequisites is Array or prerequisites is PackedStringArray) or prerequisites.is_empty():
		return "Requisitos: nenhum"

	var names: Array[String] = []
	for prerequisite in prerequisites:
		names.append(_get_skill_name(str(prerequisite)))

	return "Requisitos: %s" % ", ".join(names)


func _refresh_button_styles() -> void:
	for skill in _skills:
		var skill_id := str(skill.get("id", ""))
		if _skill_buttons.has(skill_id):
			var button := _skill_buttons[skill_id] as Button
			_apply_skill_button_style(button, skill)


func _apply_skill_button_style(button: Button, skill: Dictionary) -> void:
	var branch_color := _get_branch_color(str(skill.get("branch", "")))
	var bg_color := Color(0.08, 0.09, 0.11, 0.96)
	var border_color := Color(branch_color.r, branch_color.g, branch_color.b, 0.42)
	var font_color := Color(0.78, 0.84, 0.9)

	if bool(skill.get("purchased", false)):
		bg_color = Color(branch_color.r * 0.42, branch_color.g * 0.42, branch_color.b * 0.42, 0.98)
		border_color = Color(branch_color.r, branch_color.g, branch_color.b, 1.0)
		font_color = Color(0.95, 1.0, 1.0)
	elif bool(skill.get("can_purchase", false)):
		bg_color = Color(0.11, 0.12, 0.14, 0.98)
		border_color = Color(1.0, 0.86, 0.38, 1.0)
		font_color = Color(0.96, 0.94, 0.82)
	elif bool(skill.get("future", false)):
		bg_color = Color(0.045, 0.05, 0.06, 0.92)
		border_color = Color(0.2, 0.24, 0.3, 0.76)
		font_color = Color(0.46, 0.5, 0.56)

	if str(skill.get("id", "")) == _selected_skill_id:
		border_color = Color(1.0, 1.0, 1.0, 1.0)

	button.add_theme_stylebox_override("normal", _create_node_style(bg_color, border_color))
	button.add_theme_stylebox_override("hover", _create_node_style(bg_color.lightened(0.08), border_color.lightened(0.1)))
	button.add_theme_stylebox_override("pressed", _create_node_style(bg_color.darkened(0.08), Color(1.0, 0.92, 0.48, 1.0)))
	button.add_theme_color_override("font_color", font_color)


func _create_node_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _create_branch_labels() -> void:
	var labels := [
		{"text": "NUCLEO", "position": Vector2(64.0, 20.0), "branch": "core"},
		{"text": "PROJETEIS", "position": Vector2(64.0, 210.0), "branch": "projectile"},
		{"text": "NOS ARCANOS", "position": Vector2(64.0, 390.0), "branch": "arcane"},
		{"text": "FORMAS", "position": Vector2(64.0, 530.0), "branch": "forms"},
	]

	for label_data in labels:
		var label := Label.new()
		label.text = str(label_data.get("text", ""))
		var label_position: Vector2 = label_data.get("position", Vector2.ZERO)
		label.position = label_position
		label.size = Vector2(240.0, 28.0)
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", _get_branch_color(str(label_data.get("branch", ""))))
		tree_area.add_child(label)


func _get_button_center(skill_id: String) -> Vector2:
	var button := _skill_buttons[skill_id] as Button
	return tree_area.position + button.position + button.size * 0.5


func _get_branch_color(branch: String) -> Color:
	match branch:
		"core":
			return Color(0.52, 1.0, 0.72)
		"projectile":
			return Color(1.0, 0.84, 0.36)
		"arcane":
			return Color(0.78, 0.52, 1.0)
		"forms":
			return Color(0.42, 0.9, 1.0)
		_:
			return Color(0.86, 0.96, 1.0)


func _format_branch(branch: String) -> String:
	match branch:
		"core":
			return "Ramo: Nucleo"
		"projectile":
			return "Ramo: Projeteis"
		"arcane":
			return "Ramo: Nos Arcanos"
		"forms":
			return "Ramo: Formas"
		_:
			return "Ramo: Geral"


func _pulse_selected_button() -> void:
	if not _skill_buttons.has(_selected_skill_id):
		return

	var button := _skill_buttons[_selected_skill_id] as Button
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 1.1, 0.08)
	tween.tween_property(button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_back_pressed() -> void:
	_play_audio("play_button_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _setup_button_feedback(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_entered.connect(_on_button_hovered.bind(button, true))
	button.mouse_exited.connect(_on_button_hovered.bind(button, false))


func _on_button_hovered(button: Button, hovered: bool) -> void:
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * (1.04 if hovered else 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)
