extends Control

const SHAPE_PREVIEW_SCRIPT := preload("res://scripts/ui/shape_preview.gd")
const NEON_STYLE := preload("res://scripts/ui/neon_style.gd")
const NEUTRAL_FORM_FILL := Color(0.38, 0.48, 0.58, 1.0)
const NEUTRAL_FORM_OUTLINE := Color(0.82, 0.9, 0.98, 1.0)
const FALLBACK_CHARACTERS := [
	{
		"id": "circle",
		"display_name": "Circle",
		"profile": "Balanced",
		"description": "A stable and versatile form.",
		"max_health": 100,
		"move_speed": 320,
		"projectile_damage": 12,
		"fire_interval": 0.45,
		"visual_shape": "circle",
		"fill_color": Color(0.25, 0.74, 1.0),
		"outline_color": Color(0.86, 0.98, 1.0),
	},
	{
		"id": "triangle",
		"display_name": "Triangle",
		"profile": "Fast and aggressive",
		"description": "A fast, fragile, and offensive form.",
		"max_health": 82,
		"move_speed": 380,
		"projectile_damage": 14,
		"fire_interval": 0.39,
		"visual_shape": "triangle",
		"fill_color": Color(0.94, 0.42, 1.0),
		"outline_color": Color(1.0, 0.86, 1.0),
	},
	{
		"id": "square",
		"display_name": "Square",
		"profile": "Resilient",
		"description": "A solid, slow, and durable form.",
		"max_health": 135,
		"move_speed": 270,
		"projectile_damage": 12,
		"fire_interval": 0.48,
		"visual_shape": "square",
		"fill_color": Color(0.43, 0.95, 0.58),
		"outline_color": Color(0.86, 1.0, 0.88),
	},
]

@onready var cards_row: HBoxContainer = $Panel/CardsRow
@onready var back_button: Button = $Panel/BackButton
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var subtitle_label: Label = $Panel/SubtitleLabel


func _ready() -> void:
	NEON_STYLE.apply_panel(panel, NEON_STYLE.MAGENTA)
	NEON_STYLE.apply_button(back_button)
	title_label.add_theme_color_override("font_color", NEON_STYLE.TEXT_PRIMARY)
	subtitle_label.add_theme_color_override("font_color", NEON_STYLE.TEXT_MUTED)
	back_button.pressed.connect(_on_back_pressed)
	_setup_button_feedback(back_button)
	_build_cards()


func _build_cards() -> void:
	var run_config := get_node_or_null("/root/RunConfig")
	var characters: Array = FALLBACK_CHARACTERS
	if run_config != null:
		characters = run_config.call("get_character_list")

	for character in characters:
		cards_row.add_child(_create_character_card(character))


func _create_character_card(character: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(260.0, 410.0)
	var unlocked := bool(character.get("unlocked", true))
	if not unlocked:
		card.modulate = Color(0.72, 0.76, 0.82, 1.0)
	var card_accent: Color = NEON_STYLE.CYAN if unlocked else Color(0.3, 0.36, 0.44, 1.0)
	card.add_theme_stylebox_override("panel", NEON_STYLE.panel_style(Color(0.018, 0.044, 0.08, 0.98), Color(card_accent.r, card_accent.g, card_accent.b, 0.7), 1, 7))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	margin.add_child(layout)

	var title := Label.new()
	title.text = str(character.get("display_name", "Form"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", NEON_STYLE.TEXT_PRIMARY)
	layout.add_child(title)

	var profile := Label.new()
	profile.text = str(character.get("profile", ""))
	profile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile.add_theme_color_override("font_color", NEON_STYLE.WARNING)
	layout.add_child(profile)

	var preview := Control.new()
	preview.custom_minimum_size = Vector2(210.0, 78.0)
	preview.set_script(SHAPE_PREVIEW_SCRIPT)
	preview.call("setup", str(character.get("visual_shape", "circle")), NEUTRAL_FORM_FILL, NEUTRAL_FORM_OUTLINE)
	layout.add_child(preview)

	var description := Label.new()
	description.text = str(character.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_color_override("font_color", NEON_STYLE.TEXT_MUTED)
	layout.add_child(description)

	var stats := Label.new()
	stats.text = "Health %d\nSpeed %d\nDamage %d\nCadence %.2fs" % [
		int(character.get("max_health", 100)),
		int(character.get("move_speed", 320)),
		int(character.get("projectile_damage", 12)),
		float(character.get("fire_interval", 0.45)),
	]
	if not unlocked:
		stats.text += "\nLocked: %d Echoes" % int(character.get("unlock_cost", 0))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_color_override("font_color", NEON_STYLE.TEXT_PRIMARY)
	layout.add_child(stats)

	var choose_button := Button.new()
	choose_button.text = "Choose" if unlocked else "Locked"
	choose_button.disabled = not unlocked
	NEON_STYLE.apply_button(choose_button, NEON_STYLE.MAGENTA)
	if unlocked:
		choose_button.pressed.connect(_on_character_chosen.bind(str(character.get("id", "circle"))))
		_setup_button_feedback(choose_button)
	layout.add_child(choose_button)

	return card


func _on_character_chosen(character_id: String) -> void:
	_play_audio("play_button_click")
	var run_config := get_node_or_null("/root/RunConfig")
	if run_config != null:
		run_config.call("select_character", character_id)
	get_tree().change_scene_to_file("res://scenes/ui/spell_crafting_menu.tscn")


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
