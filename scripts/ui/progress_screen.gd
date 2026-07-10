extends Control

@onready var ecos_label: Label = $Panel/EcosLabel
@onready var records_label: Label = $Panel/RecordsLabel
@onready var unlocks_list: VBoxContainer = $Panel/UnlocksList
@onready var back_button: Button = $Panel/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_refresh()


func _refresh() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		ecos_label.text = "Ecos: 0"
		records_label.text = "Sem save carregado."
		return

	var summary: Dictionary = save_manager.call("get_summary")
	ecos_label.text = "Ecos: %d" % int(summary.get("ecos", 0))
	records_label.text = "Maior pontuacao: %d    Maior onda: %d    Vitorias: %d" % [
		int(summary.get("best_score", 0)),
		int(summary.get("best_wave", 0)),
		int(summary.get("victories", 0)),
	]

	for child in unlocks_list.get_children():
		unlocks_list.remove_child(child)
		child.queue_free()

	var unlocks: Array = save_manager.call("get_unlock_definitions")
	for unlock_data in unlocks:
		unlocks_list.add_child(_create_unlock_row(unlock_data))


func _create_unlock_row(unlock_data: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(820.0, 96.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	row.add_child(margin)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(text_box)

	var title := Label.new()
	title.text = "%s - %s Ecos" % [
		str(unlock_data.get("display_name", "Desbloqueio")),
		int(unlock_data.get("cost", 0)),
	]
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
	text_box.add_child(title)

	var description := Label.new()
	description.text = str(unlock_data.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color(0.76, 0.86, 0.92))
	text_box.add_child(description)

	var button := Button.new()
	button.custom_minimum_size = Vector2(170.0, 42.0)
	if bool(unlock_data.get("unlocked", false)):
		button.text = "Desbloqueado"
		button.disabled = true
	elif bool(unlock_data.get("can_unlock", false)):
		button.text = "Desbloquear"
		button.pressed.connect(_on_unlock_pressed.bind(str(unlock_data.get("id", ""))))
	else:
		button.text = "Ecos insuficientes"
		button.disabled = true
	layout.add_child(button)

	return row


func _on_unlock_pressed(unlock_id: String) -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.call("unlock", unlock_id)
	_refresh()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
