extends Control

signal close_requested

const NODE_SIZE := Vector2(118.0, 38.0)
const ROOT_SIZE := Vector2(154.0, 50.0)
const ROOT_CENTER := Vector2(560.0, 220.0)

const BRANCH_LAYOUT := {
	"energy": {"start": Vector2(430.0, 74.0), "step": Vector2(-104.0, 0.0), "label_position": Vector2(220.0, 38.0)},
	"form": {"start": Vector2(642.0, 174.0), "step": Vector2(90.0, 0.0), "label_position": Vector2(642.0, 132.0)},
	"rhythm": {"start": Vector2(642.0, 280.0), "step": Vector2(90.0, 0.0), "label_position": Vector2(642.0, 328.0)},
	"core": {"start": Vector2(430.0, 280.0), "step": Vector2(-104.0, 0.0), "label_position": Vector2(220.0, 328.0)},
}

const BRANCH_COLORS := {
	"energy": Color(0.96, 0.46, 0.86),
	"form": Color(1.0, 0.78, 0.28),
	"rhythm": Color(0.68, 0.58, 1.0),
	"core": Color(0.42, 0.94, 0.72),
}

@onready var title_label: Label = $Panel/TitleLabel
@onready var summary_label: Label = $Panel/SummaryLabel
@onready var synergy_label: Label = $Panel/SynergyLabel
@onready var close_button: Button = $Panel/CloseButton
@onready var graph_canvas: Control = $Panel/GraphCanvas

var _branch_nodes: Dictionary = {}
var _synergies: Array[String] = []
var _base_spell: Dictionary = {}
var _open_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	close_button.pressed.connect(_on_close_pressed)
	close_button.focus_mode = Control.FOCUS_NONE
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
	summary_label.add_theme_font_size_override("font_size", 14)
	summary_label.add_theme_color_override("font_color", Color(0.68, 0.84, 1.0))
	synergy_label.add_theme_font_size_override("font_size", 16)
	synergy_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.48))
	set_graph_data({}, [])


func open_graph(branch_nodes: Dictionary, synergies: Array, base_spell: Dictionary = {}) -> void:
	set_graph_data(branch_nodes, synergies, base_spell)
	show()
	if is_instance_valid(_open_tween):
		_open_tween.kill()

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	$Panel.scale = Vector2.ONE * 0.96
	$Panel.pivot_offset = $Panel.size * 0.5
	_open_tween = create_tween()
	_open_tween.set_parallel(true)
	_open_tween.tween_property(self, "modulate", Color.WHITE, 0.16)
	_open_tween.tween_property($Panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_graph() -> void:
	hide()


func set_graph_data(branch_nodes: Dictionary, synergies: Array, base_spell: Dictionary = {}) -> void:
	_branch_nodes = branch_nodes.duplicate(true)
	_base_spell = base_spell.duplicate(true)
	_synergies.clear()
	for synergy in synergies:
		_synergies.append(str(synergy))
	_rebuild_graph()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and (key_event.keycode == KEY_G or key_event.keycode == KEY_ESCAPE):
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _on_close_pressed() -> void:
	close_requested.emit()


func _rebuild_graph() -> void:
	for child in graph_canvas.get_children():
		graph_canvas.remove_child(child)
		child.queue_free()

	for branch in ["energy", "form", "rhythm", "core"]:
		_create_branch_label(branch)
		_create_branch_nodes(branch)
	_create_root_node()

	var node_count := 0
	for nodes in _branch_nodes.values():
		if nodes is Array:
			node_count += nodes.size()
	var base_text := "%s + %s + %s" % [
		str(_base_spell.get("shape_name", "Circle")),
		str(_base_spell.get("element_name", "Arcane")),
		str(_base_spell.get("delivery_name", "Simple Projectile")),
	]
	summary_label.text = "Base: %s  |  Nodes: %d  |  Branches: %d" % [base_text, node_count, _get_active_branch_count()]
	synergy_label.text = "Synergies: " + (", ".join(_synergies) if not _synergies.is_empty() else "none")


func _create_root_node() -> void:
	var root_label := str(_base_spell.get("shape_name", "Projectile")).to_upper()
	var root := _create_node_card(root_label, Color(0.2, 0.48, 0.68), ROOT_SIZE, 16)
	root.position = ROOT_CENTER - ROOT_SIZE * 0.5
	graph_canvas.add_child(root)


func _create_branch_label(branch: String) -> void:
	var layout: Dictionary = BRANCH_LAYOUT[branch]
	var label := Label.new()
	label.text = branch.to_upper()
	label.position = layout["label_position"]
	label.size = Vector2(180.0, 24.0)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", BRANCH_COLORS[branch])
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph_canvas.add_child(label)


func _create_branch_nodes(branch: String) -> void:
	var layout: Dictionary = BRANCH_LAYOUT[branch]
	var start: Vector2 = layout["start"]
	var step: Vector2 = layout["step"]
	var branch_color: Color = BRANCH_COLORS[branch]
	var previous_center := ROOT_CENTER
	var nodes = _branch_nodes.get(branch, [])

	for index in range(nodes.size()):
		var node: Dictionary = nodes[index]
		var node_position := start + step * float(index)
		var center := node_position + NODE_SIZE * 0.5
		_create_connection(previous_center, center, branch_color)

		var label := str(node.get("node_label", node.get("name", "Node")))
		var stack := int(node.get("stack", 1))
		if stack > 1:
			label += " x%d" % stack
		var card := _create_node_card(label, branch_color, NODE_SIZE, 13)
		card.position = node_position
		graph_canvas.add_child(card)
		previous_center = center


func _create_connection(start: Vector2, end: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(color.r, color.g, color.b, 0.8)
	line.add_point(start)
	line.add_point(end)
	graph_canvas.add_child(line)


func _create_node_card(text: String, color: Color, node_size: Vector2, font_size: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.size = node_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _create_node_style(color))

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	card.add_child(label)
	return card


func _create_node_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r * 0.22, color.g * 0.22, color.b * 0.22, 0.98)
	style.border_color = Color(color.r, color.g, color.b, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	return style


func _get_active_branch_count() -> int:
	var count := 0
	for nodes in _branch_nodes.values():
		if nodes is Array and not nodes.is_empty():
			count += 1
	return count
