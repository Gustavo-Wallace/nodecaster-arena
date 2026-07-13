extends Control

const NODE_SIZE := Vector2(156.0, 62.0)
const CONTENT_SIZE := Vector2(1220.0, 820.0)
const HUB_CENTER := Vector2(560.0, 390.0)

@onready var ecos_label: Label = $Header/EcosLabel
@onready var back_button: Button = $Header/BackButton
@onready var center_button: Button = $Header/CenterButton
@onready var tree_viewport: Panel = $TreeViewport
@onready var tree_content: Control = $TreeViewport/TreeContent
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
var _is_panning := false
var _pan_start_mouse := Vector2.ZERO
var _pan_start_position := Vector2.ZERO


func _ready() -> void:
	tree_viewport.gui_input.connect(_on_tree_viewport_gui_input)
	back_button.pressed.connect(_on_back_pressed)
	center_button.pressed.connect(_on_center_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	_setup_button_feedback(back_button)
	_setup_button_feedback(center_button)
	_setup_button_feedback(buy_button)
	_refresh_tree(false)
	_center_tree()


func _refresh_tree(keep_selection: bool = true) -> void:
	_clear_tree_content()
	_load_skills()
	_create_branch_labels()
	_create_connection_lines()
	_create_hub()
	_build_skill_buttons()
	_update_ecos_label()

	if not keep_selection or _selected_skill_id.is_empty() or not _skill_buttons.has(_selected_skill_id):
		_selected_skill_id = str(_skills[0].get("id", "")) if not _skills.is_empty() else ""

	_update_details()
	_refresh_button_styles()


func _load_skills() -> void:
	_skills.clear()
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return

	var loaded_skills: Array = save_manager.call("get_skill_definitions")
	for skill in loaded_skills:
		if skill is Dictionary:
			_skills.append(skill)


func _clear_tree_content() -> void:
	for child in tree_content.get_children():
		tree_content.remove_child(child)
		child.queue_free()
	_skill_buttons.clear()


func _create_branch_labels() -> void:
	var labels := [
		{"text": "NUCLEO", "position": Vector2(470.0, 30.0), "branch": "core"},
		{"text": "PROJETEIS", "position": Vector2(780.0, 220.0), "branch": "projectile"},
		{"text": "NOS ARCANOS", "position": Vector2(590.0, 615.0), "branch": "arcane"},
		{"text": "FORMAS", "position": Vector2(150.0, 300.0), "branch": "forms"},
	]

	for label_data in labels:
		var label := Label.new()
		label.text = str(label_data.get("text", ""))
		var label_position: Vector2 = label_data.get("position", Vector2.ZERO)
		label.position = label_position
		label.size = Vector2(260.0, 32.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", _get_branch_color(str(label_data.get("branch", ""))))
		tree_content.add_child(label)


func _create_hub() -> void:
	var hub := Panel.new()
	hub.name = "EchoHub"
	hub.position = HUB_CENTER - Vector2(52.0, 52.0)
	hub.size = Vector2(104.0, 104.0)
	hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub.add_theme_stylebox_override("panel", _create_node_style(Color(0.08, 0.12, 0.15, 0.96), Color(0.86, 1.0, 1.0, 0.92), 52))
	tree_content.add_child(hub)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = "ECO"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 1.0, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub.add_child(label)


func _create_connection_lines() -> void:
	for skill in _skills:
		var skill_id := str(skill.get("id", ""))
		var prerequisites = skill.get("prerequisites", [])
		if prerequisites is Array or prerequisites is PackedStringArray:
			if prerequisites.is_empty():
				_add_connection_line(HUB_CENTER, _get_skill_center(skill_id), skill)
			else:
				for prerequisite in prerequisites:
					_add_connection_line(_get_skill_center(str(prerequisite)), _get_skill_center(skill_id), skill)


func _add_connection_line(start: Vector2, end: Vector2, skill: Dictionary) -> void:
	var branch_color := _get_branch_color(str(skill.get("branch", "")))
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Color(branch_color.r, branch_color.g, branch_color.b, 0.34)
	if bool(skill.get("purchased", false)):
		line.default_color = Color(branch_color.r, branch_color.g, branch_color.b, 0.9)
		line.width = 5.0
	elif bool(skill.get("can_purchase", false)):
		line.default_color = Color(1.0, 0.86, 0.38, 0.72)

	line.add_point(start)
	line.add_point(end)
	tree_content.add_child(line)


func _build_skill_buttons() -> void:
	for skill in _skills:
		var button := Button.new()
		var skill_id := str(skill.get("id", ""))
		button.name = "Skill_%s" % skill_id
		button.text = _get_short_node_label(skill)
		var skill_position := _get_skill_position(skill_id)
		button.position = skill_position
		button.size = NODE_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.clip_contents = true
		button.pressed.connect(_select_skill.bind(skill_id))
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
		button.add_theme_constant_override("outline_size", 2)
		_setup_button_feedback(button)
		_apply_skill_button_style(button, skill)
		tree_content.add_child(button)
		_skill_buttons[skill_id] = button


func _update_ecos_label() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		ecos_label.text = "Ecos: 0"
		return

	var summary: Dictionary = save_manager.call("get_summary")
	ecos_label.text = "Ecos: %d" % int(summary.get("ecos", 0))


func _select_skill(skill_id: String) -> void:
	_selected_skill_id = skill_id
	_play_audio("play_button_click")
	_update_details()
	_refresh_button_styles()


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
		status_label.text = "Ja adquirida."
		buy_button.text = "Adquirida"
		buy_button.disabled = true
	elif bool(skill.get("future", false)):
		status_label.text = "Em breve."
		buy_button.text = "Indisponivel"
		buy_button.disabled = true
	elif bool(skill.get("can_purchase", false)):
		status_label.text = "Disponivel para compra."
		buy_button.text = "Comprar"
		buy_button.disabled = false
	else:
		status_label.text = str(skill.get("locked_reason", "Bloqueada."))
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


func _get_skill_by_id(skill_id: String) -> Dictionary:
	for skill in _skills:
		if str(skill.get("id", "")) == skill_id:
			return skill

	return {}


func _get_short_node_label(skill: Dictionary) -> String:
	match str(skill.get("id", "")):
		"resonant_shell":
			return "Casca"
		"stable_window":
			return "Janela"
		"field_repair":
			return "Reparo"
		"emergency_pulse":
			return "Pulso"
		"catalyzed_shot":
			return "Catalisa"
		"opening_charge":
			return "Abertura"
		"initial_fragment":
			return "Fragmento"
		"unlock_piercing":
			return "Perfura"
		"prepared_choice":
			return "Reroll"
		"expanded_options":
			return "+Opcoes"
		"arcane_memory":
			return "Memoria"
		"directed_affinity":
			return "Afinidade"
		"synergy_resonance":
			return "Sinergia"
		"unlock_diamond":
			return "Losango"
		_:
			return str(skill.get("name", "Skill"))


func _get_skill_name(skill_id: String) -> String:
	var skill := _get_skill_by_id(skill_id)
	if skill.is_empty():
		return skill_id

	return str(skill.get("name", skill_id))


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
	var bg_color := Color(0.045, 0.052, 0.066, 0.96)
	var border_color := Color(branch_color.r, branch_color.g, branch_color.b, 0.38)
	var font_color := Color(0.68, 0.75, 0.82)

	if bool(skill.get("purchased", false)):
		bg_color = Color(branch_color.r * 0.35, branch_color.g * 0.35, branch_color.b * 0.35, 0.98)
		border_color = Color(branch_color.r, branch_color.g, branch_color.b, 1.0)
		font_color = Color(0.96, 1.0, 1.0)
	elif bool(skill.get("can_purchase", false)):
		bg_color = Color(0.105, 0.112, 0.13, 0.98)
		border_color = Color(1.0, 0.86, 0.38, 1.0)
		font_color = Color(1.0, 0.95, 0.76)
	elif bool(skill.get("affordable", false)) and bool(skill.get("available", false)):
		bg_color = Color(0.075, 0.082, 0.1, 0.96)
		border_color = Color(branch_color.r, branch_color.g, branch_color.b, 0.62)
	elif bool(skill.get("future", false)):
		bg_color = Color(0.03, 0.034, 0.042, 0.92)
		border_color = Color(0.18, 0.22, 0.28, 0.76)
		font_color = Color(0.42, 0.46, 0.52)

	var radius := 24
	if str(skill.get("id", "")) == _selected_skill_id:
		border_color = Color(1.0, 1.0, 1.0, 1.0)
		radius = 28

	button.add_theme_stylebox_override("normal", _create_node_style(bg_color, border_color, radius))
	button.add_theme_stylebox_override("hover", _create_node_style(bg_color.lightened(0.08), border_color.lightened(0.1), radius))
	button.add_theme_stylebox_override("pressed", _create_node_style(bg_color.darkened(0.08), Color(1.0, 0.92, 0.48, 1.0), radius))
	button.add_theme_color_override("font_color", font_color)


func _create_node_style(bg_color: Color, border_color: Color, corner_radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.18)
	style.shadow_size = 6
	return style


func _get_skill_position(skill_id: String) -> Vector2:
	var skill := _get_skill_by_id(skill_id)
	if skill.is_empty():
		return Vector2.ZERO

	var position: Vector2 = skill.get("position", Vector2.ZERO)
	return position


func _get_skill_center(skill_id: String) -> Vector2:
	return _get_skill_position(skill_id) + NODE_SIZE * 0.5


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


func _on_tree_viewport_gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button != null:
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_is_panning = mouse_button.pressed
			_pan_start_mouse = get_global_mouse_position()
			_pan_start_position = tree_content.position
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_pan_by(Vector2(0.0, 72.0))
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_pan_by(Vector2(0.0, -72.0))
		return

	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion != null and _is_panning:
		var delta := get_global_mouse_position() - _pan_start_mouse
		_set_tree_position(_pan_start_position + delta)


func _pan_by(delta: Vector2) -> void:
	_set_tree_position(tree_content.position + delta)


func _center_tree() -> void:
	var bounds := _get_skill_bounds()
	var centered_position := tree_viewport.size * 0.5 - bounds.get_center()
	_set_tree_position(centered_position)


func _set_tree_position(new_position: Vector2) -> void:
	var viewport_size := tree_viewport.size
	var min_position := viewport_size - CONTENT_SIZE
	var max_position := Vector2.ZERO

	if CONTENT_SIZE.x <= viewport_size.x:
		new_position.x = (viewport_size.x - CONTENT_SIZE.x) * 0.5
	else:
		new_position.x = clampf(new_position.x, min_position.x, max_position.x)

	if CONTENT_SIZE.y <= viewport_size.y:
		new_position.y = (viewport_size.y - CONTENT_SIZE.y) * 0.5
	else:
		new_position.y = clampf(new_position.y, min_position.y, max_position.y)

	tree_content.position = new_position


func _get_skill_bounds() -> Rect2:
	var bounds := Rect2(HUB_CENTER, Vector2.ZERO)
	for skill in _skills:
		var skill_id := str(skill.get("id", ""))
		var skill_position := _get_skill_position(skill_id)
		var skill_rect := Rect2(skill_position, NODE_SIZE)
		bounds = bounds.merge(skill_rect)

	return bounds.grow(120.0)


func _on_center_pressed() -> void:
	_play_audio("play_button_click")
	_center_tree()


func _pulse_selected_button() -> void:
	if not _skill_buttons.has(_selected_skill_id):
		return

	var button := _skill_buttons[_selected_skill_id] as Button
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 1.08, 0.08)
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
	tween.tween_property(button, "scale", Vector2.ONE * (1.035 if hovered else 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)
