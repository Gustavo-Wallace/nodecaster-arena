extends Control

const NODE_SIZE := Vector2(88.0, 28.0)
const ROOT_SIZE := Vector2(102.0, 32.0)
const ROOT_CENTER := Vector2(590.0, 64.0)

const BRANCH_LAYOUT := {
	"energy": {"start": Vector2(488.0, 22.0), "step": Vector2(-96.0, 0.0), "label_position": Vector2(296.0, 2.0)},
	"form": {"start": Vector2(650.0, 46.0), "step": Vector2(96.0, 0.0), "label_position": Vector2(650.0, 16.0)},
	"rhythm": {"start": Vector2(650.0, 96.0), "step": Vector2(96.0, 0.0), "label_position": Vector2(650.0, 126.0)},
	"core": {"start": Vector2(488.0, 96.0), "step": Vector2(-96.0, 0.0), "label_position": Vector2(296.0, 126.0)},
}

const BRANCH_COLORS := {
	"energy": Color(0.96, 0.46, 0.86),
	"form": Color(1.0, 0.78, 0.28),
	"rhythm": Color(0.68, 0.58, 1.0),
	"core": Color(0.42, 0.94, 0.72),
}

@onready var title_label: Label = $Panel/TitleLabel
@onready var synergy_label: Label = $Panel/SynergyLabel
@onready var graph_canvas: Control = $Panel/GraphCanvas

var _branch_nodes: Dictionary = {}
var _synergies: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
	synergy_label.add_theme_font_size_override("font_size", 14)
	synergy_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.48))
	set_graph_data({}, [])


func set_graph_data(branch_nodes: Dictionary, synergies: Array) -> void:
	_branch_nodes = branch_nodes.duplicate(true)
	_synergies.clear()
	for synergy in synergies:
		_synergies.append(str(synergy))
	_rebuild_graph()


func _rebuild_graph() -> void:
	for child in graph_canvas.get_children():
		graph_canvas.remove_child(child)
		child.queue_free()

	for branch in BRANCH_LAYOUT.keys():
		_create_branch_label(str(branch))

	for branch in ["energy", "form", "rhythm", "core"]:
		_create_branch_nodes(branch)
	_create_root_node()

	synergy_label.text = "Synergies: " + (", ".join(_synergies) if not _synergies.is_empty() else "none")


func _create_root_node() -> void:
	var root := _create_node_card("Projectile", Color(0.18, 0.42, 0.58), ROOT_SIZE)
	root.position = ROOT_CENTER - ROOT_SIZE * 0.5
	graph_canvas.add_child(root)


func _create_branch_label(branch: String) -> void:
	var layout: Dictionary = BRANCH_LAYOUT[branch]
	var label := Label.new()
	label.text = branch.to_upper()
	label.position = layout["label_position"]
	label.size = Vector2(150.0, 18.0)
	label.add_theme_font_size_override("font_size", 12)
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
		var card := _create_node_card(label, branch_color, NODE_SIZE)
		card.position = node_position
		graph_canvas.add_child(card)
		previous_center = center


func _create_connection(start: Vector2, end: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(color.r, color.g, color.b, 0.72)
	line.add_point(start)
	line.add_point(end)
	graph_canvas.add_child(line)


func _create_node_card(text: String, color: Color, node_size: Vector2) -> PanelContainer:
	var card := PanelContainer.new()
	card.size = node_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _create_node_style(color))

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	card.add_child(label)
	return card


func _create_node_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r * 0.24, color.g * 0.24, color.b * 0.24, 0.96)
	style.border_color = Color(color.r, color.g, color.b, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.set_content_margin(SIDE_LEFT, 5.0)
	style.set_content_margin(SIDE_RIGHT, 5.0)
	return style
