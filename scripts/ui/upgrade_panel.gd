extends Control

signal upgrade_selected(upgrade: Dictionary)

@onready var title_label: Label = $Panel/TitleLabel
@onready var option_1_button: Button = $Panel/Option1Button
@onready var option_2_button: Button = $Panel/Option2Button
@onready var option_3_button: Button = $Panel/Option3Button

var option_buttons: Array[Button] = []
var option_title_labels: Array[Label] = []
var option_description_labels: Array[Label] = []
var _upgrades: Array[Dictionary] = []


func _ready() -> void:
	hide()
	option_buttons = [option_1_button, option_2_button, option_3_button]
	title_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
	title_label.add_theme_font_size_override("font_size", 30)

	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		button.pressed.connect(_on_option_pressed.bind(index))
		_setup_option_card(button)


func _setup_option_card(button: Button) -> void:
	button.text = ""
	button.clip_contents = true

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
	layout.add_theme_constant_override("separation", 10)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(layout)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(1.0, 34.0)
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(spacer_top)

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

	option_title_labels.append(title)
	option_description_labels.append(description)


func show_upgrades(upgrades: Array[Dictionary]) -> void:
	_upgrades = upgrades

	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		if index >= _upgrades.size():
			button.hide()
			continue

		var upgrade := _upgrades[index]
		button.show()
		option_title_labels[index].text = str(upgrade.get("name", "Upgrade"))
		option_description_labels[index].text = str(upgrade.get("description", ""))

	show()


func _on_option_pressed(index: int) -> void:
	if index < 0 or index >= _upgrades.size():
		return

	hide()
	upgrade_selected.emit(_upgrades[index])
