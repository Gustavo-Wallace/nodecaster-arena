extends Control

const SHAPE_PREVIEW_SCRIPT := preload("res://scripts/ui/shape_preview.gd")
const FALLBACK_CHARACTERS := [
	{
		"id": "circle",
		"display_name": "Circulo",
		"profile": "Equilibrado",
		"description": "Forma estavel e versatil.",
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
		"display_name": "Triangulo",
		"profile": "Rapido e agressivo",
		"description": "Forma veloz, fragil e ofensiva.",
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
		"display_name": "Quadrado",
		"profile": "Resistente",
		"description": "Forma solida, lenta e duravel.",
		"max_health": 135,
		"move_speed": 270,
		"projectile_damage": 12,
		"fire_interval": 0.48,
		"visual_shape": "square",
		"fill_color": Color(0.43, 0.95, 0.58),
		"outline_color": Color(0.86, 1.0, 0.88),
	},
	{
		"id": "diamond",
		"display_name": "Losango",
		"profile": "Conjurador",
		"description": "Forma instavel especializada em poder arcano.",
		"max_health": 86,
		"move_speed": 320,
		"projectile_damage": 18,
		"fire_interval": 0.50,
		"visual_shape": "diamond",
		"fill_color": Color(0.34, 0.92, 0.92),
		"outline_color": Color(0.9, 1.0, 1.0),
		"unlocked": false,
		"unlock_cost": 25,
	},
]

@onready var cards_row: HBoxContainer = $Panel/CardsRow
@onready var back_button: Button = $Panel/BackButton


func _ready() -> void:
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
	title.text = str(character.get("display_name", "Forma"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
	layout.add_child(title)

	var profile := Label.new()
	profile.text = str(character.get("profile", ""))
	profile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile.add_theme_color_override("font_color", Color(1.0, 0.92, 0.54))
	layout.add_child(profile)

	var preview := Control.new()
	preview.custom_minimum_size = Vector2(210.0, 78.0)
	preview.set_script(SHAPE_PREVIEW_SCRIPT)
	preview.call("setup", str(character.get("visual_shape", "circle")), character.get("fill_color", Color.WHITE), character.get("outline_color", Color.WHITE))
	layout.add_child(preview)

	var description := Label.new()
	description.text = str(character.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_color_override("font_color", Color(0.78, 0.88, 0.94))
	layout.add_child(description)

	var stats := Label.new()
	stats.text = "Vida %d\nVelocidade %d\nDano %d\nCadencia %.2fs" % [
		int(character.get("max_health", 100)),
		int(character.get("move_speed", 320)),
		int(character.get("projectile_damage", 12)),
		float(character.get("fire_interval", 0.45)),
	]
	if not unlocked:
		stats.text += "\nBloqueado: %d Ecos" % int(character.get("unlock_cost", 0))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
	layout.add_child(stats)

	var choose_button := Button.new()
	choose_button.text = "Escolher" if unlocked else "Bloqueado"
	choose_button.disabled = not unlocked
	if unlocked:
		choose_button.pressed.connect(_on_character_chosen.bind(str(character.get("id", "circle"))))
		_setup_button_feedback(choose_button)
	layout.add_child(choose_button)

	return card


func _on_character_chosen(character_id: String) -> void:
	var run_config := get_node_or_null("/root/RunConfig")
	if run_config != null:
		run_config.call("select_character", character_id)
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _setup_button_feedback(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_entered.connect(_on_button_hovered.bind(button, true))
	button.mouse_exited.connect(_on_button_hovered.bind(button, false))


func _on_button_hovered(button: Button, hovered: bool) -> void:
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * (1.04 if hovered else 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
