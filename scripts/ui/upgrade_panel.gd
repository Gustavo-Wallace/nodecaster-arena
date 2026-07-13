extends Control

signal upgrade_selected(upgrade: Dictionary)
signal reroll_requested

@onready var title_label: Label = $Panel/TitleLabel
@onready var option_1_button: Button = $Panel/Option1Button
@onready var option_2_button: Button = $Panel/Option2Button
@onready var option_3_button: Button = $Panel/Option3Button
@onready var option_4_button: Button = $Panel/Option4Button
@onready var reroll_button: Button = $Panel/RerollButton

var option_buttons: Array[Button] = []
var option_category_labels: Array[Label] = []
var option_title_labels: Array[Label] = []
var option_description_labels: Array[Label] = []
var option_impact_labels: Array[Label] = []
var _upgrades: Array[Dictionary] = []
var _panel_tween: Tween
var _rerolls_left: int = 0


func _ready() -> void:
	hide()
	option_buttons = [option_1_button, option_2_button, option_3_button, option_4_button]
	title_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
	title_label.add_theme_font_size_override("font_size", 30)

	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		button.pressed.connect(_on_option_pressed.bind(index))
		_setup_option_card(button)

	reroll_button.pressed.connect(_on_reroll_pressed)
	reroll_button.focus_mode = Control.FOCUS_NONE
	reroll_button.add_theme_stylebox_override("normal", _create_card_style(Color(0.08, 0.14, 0.17, 0.98), Color(0.4, 0.82, 1.0, 0.9)))
	reroll_button.add_theme_stylebox_override("hover", _create_card_style(Color(0.12, 0.2, 0.24, 1.0), Color(0.75, 0.94, 1.0, 1.0)))


func _setup_option_card(button: Button) -> void:
	button.text = ""
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _create_card_style(Color(0.09, 0.105, 0.13, 0.96), Color(0.34, 0.42, 0.52, 0.85)))
	button.add_theme_stylebox_override("hover", _create_card_style(Color(0.12, 0.14, 0.17, 0.98), Color(0.72, 0.88, 1.0, 0.95)))
	button.add_theme_stylebox_override("pressed", _create_card_style(Color(0.07, 0.08, 0.1, 0.98), Color(1.0, 0.9, 0.48, 1.0)))
	button.mouse_entered.connect(_on_option_hovered.bind(button, true))
	button.mouse_exited.connect(_on_option_hovered.bind(button, false))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 14.0
	margin.offset_top = 14.0
	margin.offset_right = -14.0
	margin.offset_bottom = -14.0
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 8)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(layout)

	var category := Label.new()
	category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	category.add_theme_font_size_override("font_size", 13)
	category.add_theme_color_override("font_color", Color(1.0, 0.92, 0.58))
	category.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(category)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(title)

	var description := Label.new()
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color(0.82, 0.86, 0.9))
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(description)

	var impact := Label.new()
	impact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	impact.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	impact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	impact.add_theme_font_size_override("font_size", 14)
	impact.add_theme_color_override("font_color", Color(0.96, 0.9, 0.58))
	impact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(impact)

	option_category_labels.append(category)
	option_title_labels.append(title)
	option_description_labels.append(description)
	option_impact_labels.append(impact)


func show_upgrades(upgrades: Array[Dictionary], rerolls_left: int = 0) -> void:
	_upgrades = upgrades
	_rerolls_left = maxi(rerolls_left, 0)

	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		if index >= _upgrades.size():
			button.hide()
			continue

		var upgrade := _upgrades[index]
		button.show()
		var category := str(upgrade.get("category", "projectile"))
		var branch := str(upgrade.get("branch", _get_branch_for_category(category)))
		option_category_labels[index].text = "RAMO: " + _format_branch(branch)
		var current_stack := int(upgrade.get("current_stack", 0))
		if current_stack > 0:
			option_category_labels[index].text += "   STACK %d" % current_stack
		option_category_labels[index].add_theme_color_override("font_color", _get_branch_color(branch))
		option_title_labels[index].text = str(upgrade.get("name", "Upgrade"))
		option_description_labels[index].text = str(upgrade.get("description", ""))
		option_impact_labels[index].text = _format_upgrade_impact(upgrade)

	_update_reroll_button()
	_animate_open()
	show()


func _update_reroll_button() -> void:
	reroll_button.visible = _rerolls_left > 0
	reroll_button.disabled = _rerolls_left <= 0
	reroll_button.text = "Reroll (%d)" % _rerolls_left


func _on_option_pressed(index: int) -> void:
	if index < 0 or index >= _upgrades.size():
		return

	_play_audio("play_upgrade_pick")
	hide()
	upgrade_selected.emit(_upgrades[index])


func _on_reroll_pressed() -> void:
	if _rerolls_left <= 0:
		return

	_play_audio("play_button_click")
	reroll_requested.emit()


func _animate_open() -> void:
	if is_instance_valid(_panel_tween):
		_panel_tween.kill()

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	scale = Vector2.ONE * 0.97
	pivot_offset = size * 0.5
	_panel_tween = create_tween()
	_panel_tween.set_parallel(true)
	_panel_tween.tween_property(self, "modulate", Color.WHITE, 0.18)
	_panel_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_option_hovered(button: Button, hovered: bool) -> void:
	button.pivot_offset = button.size * 0.5
	var target_scale := Vector2.ONE * (1.035 if hovered else 1.0)
	var tween := create_tween()
	tween.tween_property(button, "scale", target_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _format_category(category: String) -> String:
	match category:
		"power":
			return "PODER"
		"rhythm":
			return "RITMO"
		"body":
			return "NUCLEO"
		"area":
			return "AREA"
		"projectile":
			return "PROJETIL"
		_:
			return category.to_upper()


func _get_branch_for_category(category: String) -> String:
	match category:
		"power":
			return "energy"
		"rhythm":
			return "rhythm"
		"body", "area":
			return "core"
		_:
			return "form"


func _format_branch(branch: String) -> String:
	match branch:
		"energy":
			return "ENERGIA"
		"rhythm":
			return "RITMO"
		"core":
			return "NUCLEO"
		_:
			return "FORMA"


func _get_branch_color(branch: String) -> Color:
	match branch:
		"energy":
			return Color(1.0, 0.52, 0.88)
		"rhythm":
			return Color(0.82, 0.62, 1.0)
		"core":
			return Color(0.56, 1.0, 0.72)
		_:
			return Color(1.0, 0.86, 0.42)


func _get_category_color(category: String) -> Color:
	match category:
		"power":
			return Color(1.0, 0.48, 0.48)
		"rhythm":
			return Color(0.82, 0.62, 1.0)
		"body":
			return Color(0.56, 1.0, 0.72)
		"area":
			return Color(0.42, 0.94, 1.0)
		"projectile":
			return Color(1.0, 0.86, 0.42)
		_:
			return Color(0.86, 0.96, 1.0)


func _format_upgrade_impact(upgrade: Dictionary) -> String:
	var values = upgrade.get("values", {})
	match str(upgrade.get("id", "")):
		"arcane_damage":
			return "+%d dano" % int(values.get("damage_bonus", 5))
		"unstable_cadence":
			return "%d%% intervalo" % int(round((float(values.get("interval_multiplier", 0.84)) - 1.0) * 100.0))
		"light_core":
			return "+%d velocidade" % int(values.get("speed_bonus", 35.0))
		"energy_shell":
			return "+%d vida, +%d cura" % [int(values.get("max_health_bonus", 22)), int(values.get("heal_amount", 16))]
		"swift_projectile":
			return "+%d vel. projetil" % int(values.get("projectile_speed_bonus", 80.0))
		"initial_fragmentation":
			return "+%d projetil" % int(values.get("projectile_count_bonus", 1))
		"piercing":
			return "+%d perfuracao" % int(values.get("pierce_bonus", 1))
		"ricochet":
			return "+%d ricochete" % int(values.get("bounce_bonus", 1))
		"arcane_explosion":
			return "+%d raio, +%d%% dano area" % [int(values.get("radius_bonus", 60.0)), int(round(float(values.get("damage_multiplier_bonus", 0.5)) * 100.0))]
		"heavy_orb":
			return "+40% dano, -15% velocidade"
		"cutting_echo":
			return "Eco a cada %d disparos" % int(values.get("shot_interval", 4))
		"unstable_field":
			return "+%d raio, +%d dano/pulso" % [int(values.get("radius_bonus", 60.0)), int(values.get("damage_bonus", 6))]

	return str(upgrade.get("effect_type", ""))


func _create_card_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)
