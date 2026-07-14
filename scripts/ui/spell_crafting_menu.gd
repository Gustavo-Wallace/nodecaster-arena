extends Control

const WORKSHOP_OPTION_CARD_SCRIPT := preload("res://scripts/ui/workshop_option_card.gd")

const SHAPE_CARD_COPY := {
	"circle": {"description": "Balanced and stable.", "details": ["Flexible all-round matrix."]},
	"triangle": {"description": "Fast and aggressive.", "details": ["Quick casts, focused pressure."]},
	"square": {"description": "Heavy and wide.", "details": ["Large, durable spell patterns."]},
	"diamond": {"description": "Precise and quick.", "details": ["Fast rhythm, focused output."]},
	"star": {"description": "Chaotic multi-hit form.", "details": ["Reserved for future matrices."]},
	"pentagon": {"description": "Experimental matrix pattern.", "details": ["Reserved for future matrices."]},
}

const ELEMENT_CARD_COPY := {
	"arcane": {"description": "Pure direct energy.", "details": ["Clean impact, no status effect."]},
	"fire": {"description": "Burns enemies over time.", "details": ["Adds brief damage after impact."]},
	"ice": {"description": "Slows enemies briefly.", "details": ["Creates room through control."]},
	"electric": {"description": "Sparks and chains energy.", "details": ["Boosts chain links and field pulses."]},
	"shadow": {"description": "Amplifies direct impact.", "details": ["A stronger violet direct hit."]},
}

const DELIVERY_CARD_COPY := {
	"simple_projectile": ["Strong: Flexible direct fire", "Weak: Modest group clear", "Scales: Pierce / Ricochet / Speed"],
	"chain_lightning": ["Strong: Cluster clear", "Weak: Isolated targets", "Scales: Links / Range / Falloff"],
	"area": ["Strong: Space control", "Weak: Enemies can leave", "Scales: Size / Duration / Tick rate"],
	"slash": ["Strong: Close burst", "Weak: Limited reach", "Scales: Range / Targets / Cadence"],
	"persistent_waves": ["Strong: Lined-up groups", "Weak: Scattered targets", "Scales: Width / Speed / Lifetime"],
	"summon": ["Strong: Persistent damage", "Weak: Slow early clear", "Scales: Count / Speed / Lifetime"],
}

const DELIVERY_CARD_DESCRIPTIONS := {
	"simple_projectile": "Automatic focused fire.",
	"chain_lightning": "Links nearby targets.",
	"area": "Pulsing zone control.",
	"slash": "Instant close-range cut.",
	"persistent_waves": "Moving directional waves.",
	"summon": "Reflections attack nearby targets.",
}

@onready var shape_list: VBoxContainer = $Panel/Columns/ShapeColumn/OptionsScroll/Options
@onready var element_list: VBoxContainer = $Panel/Columns/ElementColumn/OptionsScroll/Options
@onready var delivery_list: VBoxContainer = $Panel/Columns/DeliveryColumn/OptionsScroll/Options
@onready var preview: Control = $Panel/PreviewPanel/Preview
@onready var formula_label: Label = $Panel/PreviewPanel/FormulaLabel
@onready var summary_label: Label = $Panel/PreviewPanel/SummaryLabel
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

	for shape_option in _run_config.call("get_spell_shape_list"):
		var data: Dictionary = shape_option
		var button := _create_option_card("shape", data)
		if bool(data.get("available", false)):
			button.pressed.connect(_on_shape_selected.bind(str(data.get("id", "circle"))))
		shape_list.add_child(button)
		_shape_buttons[str(data.get("id", "circle"))] = button

	for element_option in _run_config.call("get_spell_element_list"):
		var data: Dictionary = element_option
		var button := _create_option_card("element", data)
		if bool(data.get("available", false)):
			button.pressed.connect(_on_element_selected.bind(str(data.get("id", "arcane"))))
		element_list.add_child(button)
		_element_buttons[str(data.get("id", "arcane"))] = button

	for delivery_option in _run_config.call("get_spell_delivery_list"):
		var data: Dictionary = delivery_option
		var button := _create_option_card("cast_type", data)
		if bool(data.get("available", false)):
			button.pressed.connect(_on_delivery_selected.bind(str(data.get("id", "simple_projectile"))))
		delivery_list.add_child(button)
		_delivery_buttons[str(data.get("id", "simple_projectile"))] = button


func _create_option_card(option_kind: String, data: Dictionary) -> Button:
	var content: Dictionary = _get_card_content(option_kind, data)
	var description: String = str(content.get("description", ""))
	var details: Array[String] = []
	for detail_value in content.get("details", []):
		details.append(str(detail_value))

	var card: Button = WORKSHOP_OPTION_CARD_SCRIPT.new()
	card.call("configure", option_kind, data, description, details)
	_setup_button_feedback(card)
	return card


func _get_card_content(option_kind: String, data: Dictionary) -> Dictionary:
	var option_id: String = str(data.get("id", ""))
	match option_kind:
		"shape":
			var shape_content: Dictionary = SHAPE_CARD_COPY.get(option_id, {"description": str(data.get("description", "")), "details": []})
			return shape_content
		"element":
			var element_content: Dictionary = ELEMENT_CARD_COPY.get(option_id, {"description": str(data.get("description", "")), "details": []})
			return element_content
		_:
			var details: Array[String] = []
			for detail_value in DELIVERY_CARD_COPY.get(option_id, []):
				details.append(str(detail_value))
			if details.is_empty():
				details.append("Coming in a future matrix.")
			return {
				"description": str(DELIVERY_CARD_DESCRIPTIONS.get(option_id, data.get("description", ""))),
				"details": details,
			}


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

	var blueprint: Variant = _run_config.call("get_spell_blueprint")
	var summary: Dictionary = blueprint.get_summary()
	var shape: Dictionary = blueprint.get_shape_data()
	var element: Dictionary = blueprint.get_element_data()
	var character_data: Dictionary = _run_config.call("get_selected_character_data")
	var shape_name: String = str(summary.get("shape_name", "Circle"))
	var element_name: String = str(summary.get("element_name", "Arcane"))
	var delivery_name: String = str(summary.get("delivery_name", "Simple Projectile"))
	var delivery_id: String = str(summary.get("delivery_id", "simple_projectile"))

	formula_label.text = "SPELL: %s + %s + %s" % [shape_name, element_name, delivery_name]
	summary_label.text = _format_spell_summary(shape_name, element_name, delivery_name, delivery_id)
	preview.call(
		"setup",
		str(shape.get("visual_shape", "circle")),
		element.get("primary_color", Color.WHITE),
		element.get("secondary_color", Color.WHITE),
		delivery_id,
		str(character_data.get("visual_shape", "circle"))
	)
	_refresh_button_states(_shape_buttons, str(summary.get("shape_id", "circle")))
	_refresh_button_states(_element_buttons, str(summary.get("element_id", "arcane")))
	_refresh_button_states(_delivery_buttons, delivery_id)


func _format_spell_summary(shape_name: String, element_name: String, delivery_name: String, delivery_id: String) -> String:
	var cast_phrases: Dictionary = {
		"simple_projectile": "as a focused projectile.",
		"chain_lightning": "as jumping arcs of energy.",
		"area": "as a pulsing field.",
		"slash": "as a rapid cutting arc.",
		"persistent_waves": "as moving waves.",
		"summon": "through temporary Reflections.",
	}
	var cast_phrase: String = str(cast_phrases.get(delivery_id, "through an unstable matrix."))
	return "CURRENT SPELL\nShape: %s\nElement: %s\nCast Type: %s\n\nA %s %s spell cast %s" % [
		shape_name,
		element_name,
		delivery_name,
		element_name,
		shape_name,
		cast_phrase,
	]


func _refresh_button_states(buttons: Dictionary, selected_id: String) -> void:
	for option_id in buttons:
		var button := buttons[option_id] as Button
		if button != null:
			button.call("set_selected", option_id == selected_id)


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
	tween.tween_property(button, "scale", Vector2.ONE * (1.015 if hovered else 1.0), 0.1)


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)
