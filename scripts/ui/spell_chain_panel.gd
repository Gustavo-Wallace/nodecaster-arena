extends Control

@onready var title_label: Label = $Panel/TitleLabel
@onready var node_row: HBoxContainer = $Panel/ScrollContainer/NodeRow

var _nodes: Array[Dictionary] = []
var _pulse_last_node := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
	title_label.add_theme_font_size_override("font_size", 18)


func set_chain_nodes(nodes: Array[Dictionary]) -> void:
	_nodes.clear()
	for node_data in nodes:
		_nodes.append(node_data.duplicate(true))

	_rebuild_nodes()


func add_node(node_data: Dictionary) -> void:
	_nodes.append(node_data)
	_pulse_last_node = true
	_rebuild_nodes()
	call_deferred("_pulse_last_node_visual")


func _rebuild_nodes() -> void:
	for child in node_row.get_children():
		node_row.remove_child(child)
		child.queue_free()

	for index in range(_nodes.size()):
		if index > 0:
			node_row.add_child(_create_connector_label())

		node_row.add_child(_create_node_card(_nodes[index]))


func _create_node_card(node_data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(104.0, 38.0)
	card.add_theme_stylebox_override("panel", _create_node_style(str(node_data.get("category", "projectile"))))

	var label := Label.new()
	label.text = str(node_data.get("node_label", node_data.get("name", "No")))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	label.add_theme_font_size_override("font_size", 15)
	card.add_child(label)

	return card


func _create_connector_label() -> Label:
	var connector := Label.new()
	connector.text = "->"
	connector.custom_minimum_size = Vector2(28.0, 38.0)
	connector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	connector.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	connector.add_theme_color_override("font_color", Color(0.52, 0.76, 0.92))
	connector.add_theme_font_size_override("font_size", 18)
	return connector


func _create_node_style(category: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _get_category_color(category)
	style.border_color = Color(0.88, 0.96, 1.0, 0.75)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_content_margin(SIDE_LEFT, 10.0)
	style.set_content_margin(SIDE_RIGHT, 10.0)
	style.set_content_margin(SIDE_TOP, 6.0)
	style.set_content_margin(SIDE_BOTTOM, 6.0)
	return style


func _get_category_color(category: String) -> Color:
	match category:
		"base":
			return Color(0.16, 0.36, 0.48, 0.94)
		"power":
			return Color(0.62, 0.16, 0.24, 0.94)
		"rhythm":
			return Color(0.48, 0.28, 0.72, 0.94)
		"body":
			return Color(0.20, 0.50, 0.36, 0.94)
		"projectile":
			return Color(0.58, 0.42, 0.12, 0.94)
		_:
			return Color(0.28, 0.34, 0.42, 0.94)


func _pulse_last_node_visual() -> void:
	if not _pulse_last_node or node_row.get_child_count() == 0:
		return

	_pulse_last_node = false
	var last_child := node_row.get_child(node_row.get_child_count() - 1) as Control
	if last_child == null:
		return

	last_child.scale = Vector2.ONE * 1.18
	last_child.pivot_offset = last_child.size * 0.5
	var tween := create_tween()
	tween.tween_property(last_child, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
