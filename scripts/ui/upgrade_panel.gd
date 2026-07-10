extends Control

signal upgrade_selected(upgrade: Dictionary)

@onready var title_label: Label = $Panel/TitleLabel
@onready var option_1_button: Button = $Panel/Option1Button
@onready var option_2_button: Button = $Panel/Option2Button
@onready var option_3_button: Button = $Panel/Option3Button

var option_buttons: Array[Button] = []
var _upgrades: Array[Dictionary] = []


func _ready() -> void:
	hide()
	option_buttons = [option_1_button, option_2_button, option_3_button]
	title_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
	title_label.add_theme_font_size_override("font_size", 30)

	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		button.pressed.connect(_on_option_pressed.bind(index))
		button.add_theme_font_size_override("font_size", 18)


func show_upgrades(upgrades: Array[Dictionary]) -> void:
	_upgrades = upgrades

	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		if index >= _upgrades.size():
			button.hide()
			continue

		var upgrade := _upgrades[index]
		button.show()
		button.text = "%s\n%s" % [
			str(upgrade.get("name", "Upgrade")),
			str(upgrade.get("description", "")),
		]

	show()


func _on_option_pressed(index: int) -> void:
	if index < 0 or index >= _upgrades.size():
		return

	hide()
	upgrade_selected.emit(_upgrades[index])
