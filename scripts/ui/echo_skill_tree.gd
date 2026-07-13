extends Control

const SECTION_LAYOUT := [
	{
		"panel": "UnlocksPanel",
		"title": "UNLOCKS",
		"color": Color(0.42, 0.9, 1.0),
		"groups": [
			{"title": "UNLOCK MATRIX", "skills": ["unlock_matrix"]},
			{"title": "SPELL SHAPES", "skills": ["unlock_diamond_shape", "unlock_star_shape"]},
			{"title": "ELEMENTS", "skills": ["unlock_shadow_element", "unlock_light_element"]},
			{"title": "CAST TYPES", "skills": ["unlock_persistent_waves", "unlock_summoning", "unlock_orbitals", "unlock_dual_casting"]},
		],
	},
	{
		"panel": "CorePanel",
		"title": "CORE / UTILITY",
		"color": Color(0.52, 1.0, 0.72),
		"groups": [
			{"title": "DEFENSE", "skills": ["resonant_shell", "stable_window", "emergency_pulse"]},
			{"title": "RUN CONTROL", "skills": ["prepared_choice", "expanded_choices", "arcane_memory", "directed_tuning"]},
		],
	},
	{
		"panel": "ElementsPanel",
		"title": "ELEMENT MASTERY",
		"color": Color(0.78, 0.52, 1.0),
		"groups": [
			{"title": "ARCANE", "color": Color(0.78, 0.52, 1.0), "skills": ["arcane_focus", "arcane_echo"]},
			{"title": "FIRE", "color": Color(1.0, 0.38, 0.2), "skills": ["longer_burn", "hotter_burn"]},
			{"title": "ICE", "color": Color(0.4, 0.8, 1.0), "skills": ["longer_chill", "deeper_chill"]},
			{"title": "ELECTRIC", "color": Color(1.0, 0.86, 0.22), "skills": ["higher_voltage", "static_charge"]},
		],
	},
	{
		"panel": "CastTypesPanel",
		"title": "CAST TYPE MASTERY",
		"color": Color(1.0, 0.84, 0.36),
		"groups": [
			{"title": "SIMPLE PROJECTILE", "skills": ["projectile_calibration", "opening_pierce", "stable_volley"]},
			{"title": "CHAIN LIGHTNING", "skills": ["conductive_path", "static_memory", "reduced_falloff"]},
			{"title": "AREA FIELD", "skills": ["lingering_field", "wider_field", "initial_pulse"]},
			{"title": "SLASH", "skills": ["blade_rhythm", "extended_edge", "second_cut"]},
		],
	},
]

@onready var ecos_label: Label = $Header/EcosLabel
@onready var back_button: Button = $Header/BackButton
@onready var center_button: Button = $Header/CenterButton
@onready var board_scroll: ScrollContainer = $Main/BoardScroll
@onready var name_label: Label = $Main/DetailsPanel/NameLabel
@onready var branch_label: Label = $Main/DetailsPanel/BranchLabel
@onready var description_label: Label = $Main/DetailsPanel/DescriptionLabel
@onready var cost_label: Label = $Main/DetailsPanel/CostLabel
@onready var status_label: Label = $Main/DetailsPanel/StatusLabel
@onready var prerequisites_label: Label = $Main/DetailsPanel/PrerequisitesLabel
@onready var buy_button: Button = $Main/DetailsPanel/BuyButton

var _skills: Array[Dictionary] = []
var _skill_buttons: Dictionary = {}
var _selected_skill_id: String = ""


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	center_button.pressed.connect(_on_center_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	_setup_button_feedback(back_button)
	_setup_button_feedback(center_button)
	_setup_button_feedback(buy_button)
	_refresh_tree(false)
	call_deferred("_center_board")


func _refresh_tree(keep_selection: bool = true) -> void:
	_load_skills()
	_clear_sections()
	_build_sections()
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


func _clear_sections() -> void:
	_skill_buttons.clear()
	for section in SECTION_LAYOUT:
		var panel_name := str(section.get("panel", ""))
		var content := get_node_or_null("Main/BoardScroll/Board/Sections/%s/Content" % panel_name) as VBoxContainer
		if content == null:
			continue
		for child in content.get_children():
			content.remove_child(child)
			child.queue_free()


func _build_sections() -> void:
	for section in SECTION_LAYOUT:
		var panel_name := str(section.get("panel", ""))
		var content := get_node_or_null("Main/BoardScroll/Board/Sections/%s/Content" % panel_name) as VBoxContainer
		if content == null:
			continue

		var section_color: Color = section.get("color", Color(0.86, 0.96, 1.0))
		content.add_child(_create_section_title(str(section.get("title", "")), section_color))
		var groups: Array = section.get("groups", [])
		for group in groups:
			if group is Dictionary:
				_build_group(content, group, section_color)


func _build_group(content: VBoxContainer, group: Dictionary, default_color: Color) -> void:
	var group_color: Color = group.get("color", default_color)
	content.add_child(_create_group_title(str(group.get("title", "")), group_color))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var skill_ids: Array = group.get("skills", [])
	for skill_id_value in skill_ids:
		var skill_id := str(skill_id_value)
		var skill := _get_skill_by_id(skill_id)
		if skill.is_empty():
			continue
		var button := _create_skill_button(skill)
		grid.add_child(button)
	content.add_child(grid)


func _create_section_title(text_value: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	return label


func _create_group_title(text_value: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(color.r, color.g, color.b, 0.9))
	return label


func _create_skill_button(skill: Dictionary) -> Button:
	var skill_id := str(skill.get("id", ""))
	var button := Button.new()
	button.name = "Skill_%s" % skill_id
	button.text = _get_short_node_label(skill)
	button.custom_minimum_size = Vector2(178.0, 42.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.clip_contents = true
	button.pressed.connect(_on_skill_button_pressed.bind(skill_id))
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
	button.add_theme_constant_override("outline_size", 2)
	_setup_button_feedback(button)
	_apply_skill_button_style(button, skill)
	_skill_buttons[skill_id] = button
	return button


func _update_ecos_label() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		ecos_label.text = "Echoes: 0"
		return
	var summary: Dictionary = save_manager.call("get_summary")
	ecos_label.text = "Echoes: %d" % int(summary.get("ecos", 0))


func _on_skill_button_pressed(skill_id: String) -> void:
	_selected_skill_id = skill_id
	_play_audio("play_button_click")
	_update_details()
	_refresh_button_styles()


func _update_details() -> void:
	var skill := _get_selected_skill()
	if skill.is_empty():
		name_label.text = "No skill selected"
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
	cost_label.text = "Cost: %d Echoes" % int(skill.get("cost", 0))
	prerequisites_label.text = _format_prerequisites(skill)

	if bool(skill.get("purchased", false)):
		status_label.text = "Already purchased."
		buy_button.text = "Purchased"
		buy_button.disabled = true
	elif bool(skill.get("future", false)):
		status_label.text = "Coming soon."
		buy_button.text = "Unavailable"
		buy_button.disabled = true
	elif bool(skill.get("can_purchase", false)):
		status_label.text = "Available to purchase."
		buy_button.text = "Buy"
		buy_button.disabled = false
	else:
		status_label.text = str(skill.get("locked_reason", "Locked."))
		buy_button.text = "Buy"
		buy_button.disabled = true

	branch_label.add_theme_color_override("font_color", _get_branch_color(str(skill.get("branch", ""))))


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
	return _get_skill_by_id(_selected_skill_id)


func _get_skill_by_id(skill_id: String) -> Dictionary:
	for skill in _skills:
		if str(skill.get("id", "")) == skill_id:
			return skill
	return {}


func _get_short_node_label(skill: Dictionary) -> String:
	match str(skill.get("id", "")):
		"resonant_shell": return "Shell"
		"stable_window": return "Window"
		"emergency_pulse": return "Pulse"
		"prepared_choice": return "Reroll"
		"expanded_choices": return "Choices"
		"arcane_memory": return "Memory"
		"directed_tuning": return "Tuning"
		"unlock_matrix": return "Unlock Matrix"
		"unlock_diamond_shape": return "Diamond"
		"unlock_star_shape": return "Star"
		"unlock_shadow_element": return "Shadow"
		"unlock_light_element": return "Light"
		"unlock_persistent_waves": return "Waves"
		"unlock_summoning": return "Summoning"
		"unlock_orbitals": return "Orbitals"
		"unlock_dual_casting": return "Dual Cast"
		"projectile_calibration": return "Calibrate"
		"opening_pierce": return "Opening"
		"stable_volley": return "Volley"
		"conductive_path": return "Path"
		"static_memory": return "Memory"
		"reduced_falloff": return "Falloff"
		"lingering_field": return "Linger"
		"wider_field": return "Wider"
		"initial_pulse": return "Pulse"
		"blade_rhythm": return "Rhythm"
		"extended_edge": return "Edge"
		"second_cut": return "Second Cut"
		"arcane_focus": return "Focus"
		"arcane_echo": return "Echo"
		"longer_burn": return "Burn"
		"hotter_burn": return "Hotter"
		"longer_chill": return "Chill"
		"deeper_chill": return "Deeper"
		"higher_voltage": return "Voltage"
		"static_charge": return "Static"
		_: return str(skill.get("name", "Skill"))


func _format_prerequisites(skill: Dictionary) -> String:
	var prerequisites: Array = skill.get("prerequisites", [])
	if prerequisites.is_empty():
		return "Requirements: none"
	var names: Array[String] = []
	for prerequisite in prerequisites:
		var prerequisite_skill := _get_skill_by_id(str(prerequisite))
		names.append(str(prerequisite_skill.get("name", prerequisite)))
	return "Requirements: %s" % ", ".join(names)


func _refresh_button_styles() -> void:
	for skill in _skills:
		var skill_id := str(skill.get("id", ""))
		var button := _skill_buttons.get(skill_id) as Button
		if button != null:
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
	elif bool(skill.get("future", false)):
		bg_color = Color(0.03, 0.034, 0.042, 0.92)
		border_color = Color(0.18, 0.22, 0.28, 0.76)
		font_color = Color(0.42, 0.46, 0.52)

	var radius := 8
	if str(skill.get("id", "")) == _selected_skill_id:
		border_color = Color(1.0, 1.0, 1.0, 1.0)
		radius = 8
	button.add_theme_stylebox_override("normal", _create_node_style(bg_color, border_color, radius))
	button.add_theme_stylebox_override("hover", _create_node_style(bg_color.lightened(0.08), border_color.lightened(0.1), radius))
	button.add_theme_stylebox_override("pressed", _create_node_style(bg_color.darkened(0.08), Color(1.0, 0.92, 0.48, 1.0), radius))
	button.add_theme_color_override("font_color", font_color)


func _create_node_style(bg_color: Color, border_color: Color, corner_radius: int = 8) -> StyleBoxFlat:
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
	return style


func _get_branch_color(branch: String) -> Color:
	match branch:
		"core": return Color(0.52, 1.0, 0.72)
		"unlocks", "shape_unlocks", "element_unlocks", "cast_unlocks": return Color(0.42, 0.9, 1.0)
		"cast_projectile": return Color(1.0, 0.84, 0.36)
		"cast_chain": return Color(1.0, 0.95, 0.42)
		"cast_area": return Color(1.0, 0.58, 0.32)
		"cast_slash": return Color(1.0, 0.42, 0.74)
		"element_arcane": return Color(0.78, 0.52, 1.0)
		"element_fire": return Color(1.0, 0.38, 0.2)
		"element_ice": return Color(0.4, 0.8, 1.0)
		"element_electric": return Color(1.0, 0.86, 0.22)
		_: return Color(0.86, 0.96, 1.0)


func _format_branch(branch: String) -> String:
	match branch:
		"core": return "Branch: Core / Utility"
		"unlocks": return "Branch: Unlocks"
		"shape_unlocks": return "Branch: Spell Shape Unlocks"
		"element_unlocks": return "Branch: Element Unlocks"
		"cast_unlocks": return "Branch: Cast Type Unlocks"
		"cast_projectile", "cast_chain", "cast_area", "cast_slash": return "Branch: Cast Type Mastery"
		"element_arcane", "element_fire", "element_ice", "element_electric": return "Branch: Element Mastery"
		_: return "Branch: General"


func _center_board() -> void:
	board_scroll.get_h_scroll_bar().value = 0.0
	board_scroll.get_v_scroll_bar().value = 0.0


func _on_center_pressed() -> void:
	_play_audio("play_button_click")
	_center_board()


func _pulse_selected_button() -> void:
	var button := _skill_buttons.get(_selected_skill_id) as Button
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 1.05, 0.08)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_back_pressed() -> void:
	_play_audio("play_button_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _setup_button_feedback(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_entered.connect(_on_button_hovered.bind(button, true))
	button.mouse_exited.connect(_on_button_hovered.bind(button, false))


func _on_button_hovered(button: Button, hovered: bool) -> void:
	if button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * (1.025 if hovered else 1.0), 0.1)


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)
