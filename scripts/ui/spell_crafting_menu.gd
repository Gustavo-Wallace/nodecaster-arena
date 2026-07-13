extends Control

@onready var shape_list: VBoxContainer = $Panel/Columns/ShapeColumn/Options
@onready var element_list: VBoxContainer = $Panel/Columns/ElementColumn/Options
@onready var delivery_list: VBoxContainer = $Panel/Columns/DeliveryColumn/Options
@onready var preview: Control = $Panel/Preview
@onready var selection_label: Label = $Panel/SelectionLabel
@onready var detail_label: Label = $Panel/DetailLabel
@onready var start_button: Button = $Panel/StartButton
@onready var back_button: Button = $Panel/BackButton

var _run_config: Node
var _shape_buttons: Dictionary = {}
var _element_buttons: Dictionary = {}
var _delivery_buttons: Dictionary = {}


func _ready() -> void:
	_run_config = get_node_or_null("/root/RunConfig")
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_setup_button_feedback(start_button)
	_setup_button_feedback(back_button)
	_build_options()
	_refresh_selection()


func _build_options() -> void:
	if _run_config == null:
		return

	for shape in _run_config.call("get_spell_shape_list"):
		var data: Dictionary = shape
		var button := _create_option_button(str(data.get("display_name", "Forma")), str(data.get("modifiers_text", "")), true)
		button.pressed.connect(_on_shape_selected.bind(str(data.get("id", "circle"))))
		shape_list.add_child(button)
		_shape_buttons[str(data.get("id", "circle"))] = button

	for element in _run_config.call("get_spell_element_list"):
		var data: Dictionary = element
		var button := _create_option_button(str(data.get("display_name", "Elemento")), str(data.get("modifiers_text", "")), true)
		var primary_color = data.get("primary_color", Color.WHITE)
		if primary_color is Color:
			button.add_theme_color_override("font_color", primary_color)
		button.pressed.connect(_on_element_selected.bind(str(data.get("id", "arcane"))))
		element_list.add_child(button)
		_element_buttons[str(data.get("id", "arcane"))] = button

	for delivery in _run_config.call("get_spell_delivery_list"):
		var data: Dictionary = delivery
		var available := bool(data.get("available", false))
		var button := _create_option_button(str(data.get("display_name", "Lancamento")), str(data.get("description", "")), available, not available)
		if not available:
			button.text = "%s (EM BREVE)" % str(data.get("display_name", "Lancamento"))
		else:
			button.pressed.connect(_on_delivery_selected.bind(str(data.get("id", "simple_projectile"))))
		delivery_list.add_child(button)
		_delivery_buttons[str(data.get("id", "simple_projectile"))] = button


func _create_option_button(title: String, description: String, enabled: bool, compact: bool = false) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, 46.0 if compact else 58.0)
	button.text = title if compact else title + "\n" + description
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14 if compact else 15)
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.54, 0.62))
	_setup_button_feedback(button)
	return button


func _on_shape_selected(shape_id: String) -> void:
	_play_audio("play_button_click")
	_run_config.call("select_spell_shape", shape_id)
	_refresh_selection()


func _on_element_selected(element_id: String) -> void:
	_play_audio("play_button_click")
	_run_config.call("select_spell_element", element_id)
	_refresh_selection()


func _on_delivery_selected(delivery_id: String) -> void:
	_play_audio("play_button_click")
	_run_config.call("select_spell_delivery", delivery_id)
	_refresh_selection()


func _refresh_selection() -> void:
	if _run_config == null:
		return

	var blueprint = _run_config.call("get_spell_blueprint")
	var summary: Dictionary = blueprint.get_summary()
	var shape: Dictionary = blueprint.get_shape_data()
	var element: Dictionary = blueprint.get_element_data()
	var delivery: Dictionary = blueprint.get_delivery_data()
	selection_label.text = "%s + %s + %s" % [
		str(summary.get("shape_name", "Circulo")),
		str(summary.get("element_name", "Arcano")),
		str(summary.get("delivery_name", "Projetil Simples")),
	]
	detail_label.text = "%s\n%s\n%s\n\n%s" % [
		str(shape.get("description", "")),
		str(element.get("description", "")),
		str(delivery.get("description", "")),
		str(shape.get("modifiers_text", "")),
	]
	preview.call("setup", str(shape.get("visual_shape", "circle")), element.get("primary_color", Color.WHITE), element.get("secondary_color", Color.WHITE))
	_refresh_button_states(_shape_buttons, str(summary.get("shape_id", "circle")))
	_refresh_button_states(_element_buttons, str(summary.get("element_id", "arcane")))
	_refresh_button_states(_delivery_buttons, str(summary.get("delivery_id", "simple_projectile")))


func _refresh_button_states(buttons: Dictionary, selected_id: String) -> void:
	for option_id in buttons:
		var button := buttons[option_id] as Button
		if option_id == selected_id:
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)
			button.add_theme_color_override("font_outline_color", Color(0.36, 0.9, 1.0))
			button.add_theme_constant_override("outline_size", 2)
		else:
			button.modulate = Color(0.76, 0.82, 0.9, 0.88)
			button.add_theme_constant_override("outline_size", 0)


func _on_start_pressed() -> void:
	_play_audio("play_button_click")
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_back_pressed() -> void:
	_play_audio("play_button_click")
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _setup_button_feedback(button: Button) -> void:
	button.mouse_entered.connect(_on_button_hovered.bind(button, true))
	button.mouse_exited.connect(_on_button_hovered.bind(button, false))


func _on_button_hovered(button: Button, hovered: bool) -> void:
	if button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * (1.02 if hovered else 1.0), 0.1)


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)
