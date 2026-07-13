class_name SpellGraph
extends RefCounted

const BRANCH_ORDER: Array[String] = ["energy", "form", "rhythm", "core"]

const BRANCH_DATA := {
	"energy": {"name": "Energia", "color": Color(0.96, 0.46, 0.86)},
	"form": {"name": "Forma", "color": Color(1.0, 0.78, 0.28)},
	"rhythm": {"name": "Ritmo", "color": Color(0.68, 0.58, 1.0)},
	"core": {"name": "Nucleo", "color": Color(0.42, 0.94, 0.72)},
}

var _nodes_by_id: Dictionary = {}
var _synergies: Array[String] = []
var _base_spell: Dictionary = {}


func reset() -> void:
	_nodes_by_id.clear()
	_synergies.clear()
	_base_spell.clear()


func set_base_spell(base_spell: Dictionary) -> void:
	_base_spell = base_spell.duplicate(true)


func add_upgrade(upgrade: Dictionary, stack_count: int) -> Dictionary:
	var upgrade_id := str(upgrade.get("id", ""))
	if upgrade_id.is_empty():
		return {}

	var branch := str(upgrade.get("branch", _get_branch_for_category(str(upgrade.get("category", "")))))
	var branch_data: Dictionary = BRANCH_DATA.get(branch, BRANCH_DATA["energy"])
	var node := {
		"id": upgrade_id,
		"name": str(upgrade.get("name", "Mutacao")),
		"node_label": str(upgrade.get("node_label", upgrade.get("name", "No"))),
		"description": str(upgrade.get("description", "")),
		"category": str(upgrade.get("category", "projectile")),
		"branch": branch,
		"branch_name": str(branch_data.get("name", "Energia")),
		"color": branch_data.get("color", Color.WHITE),
		"effect_type": str(upgrade.get("effect_type", "")),
		"stack": maxi(stack_count, 1),
	}
	_nodes_by_id[upgrade_id] = node
	return node.duplicate(true)


func set_synergies(synergies: Array) -> void:
	_synergies.clear()
	for synergy in synergies:
		var label := str(synergy)
		if not label.is_empty() and not _synergies.has(label):
			_synergies.append(label)


func get_branch_nodes() -> Dictionary:
	var branches := {}
	for branch in BRANCH_ORDER:
		branches[branch] = []

	for node in _nodes_by_id.values():
		if not (node is Dictionary):
			continue
		var branch := str(node.get("branch", "energy"))
		if not branches.has(branch):
			branches[branch] = []
		branches[branch].append(node.duplicate(true))

	return branches


func get_ordered_nodes() -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	var branches := get_branch_nodes()
	for branch in BRANCH_ORDER:
		for node in branches.get(branch, []):
			nodes.append(node)
	return nodes


func get_synergies() -> Array[String]:
	return _synergies.duplicate()


func get_visual_profile(base_profile: Dictionary = {}) -> Dictionary:
	var primary: Color = base_profile.get("primary_color", Color(1.0, 0.9, 0.3))
	var secondary: Color = base_profile.get("secondary_color", Color(1.0, 0.98, 0.78))
	var impact_color: Color = base_profile.get("impact_color", primary)
	var aura_color: Color = base_profile.get("aura_color", Color(0.36, 0.95, 1.0))
	var glow := 0.0
	var trail_style := "standard"

	if has_node("arcane_damage"):
		secondary = secondary.lerp(Color(1.0, 0.78, 1.0), 0.54)
		glow += 0.35
	if has_node("arcane_explosion"):
		impact_color = Color(1.0, 0.48, 0.16)
		secondary = secondary.lerp(Color(1.0, 0.78, 0.26), 0.55)
		glow += 0.2
	if has_node("piercing"):
		secondary = secondary.lerp(Color(0.92, 1.0, 1.0), 0.68)
		trail_style = "piercing"
	if has_node("ricochet"):
		secondary = Color(0.42, 0.94, 1.0)
		if trail_style == "standard":
			trail_style = "spark"
	if has_node("heavy_orb"):
		glow += 0.45
	if has_node("cutting_echo"):
		trail_style = "cutting"
	if has_node("unstable_field"):
		aura_color = Color(0.46, 0.88, 1.0)
		if has_node("energy_shell"):
			aura_color = Color(0.5, 1.0, 0.76)

	return {
		"primary_color": primary,
		"secondary_color": secondary,
		"impact_color": impact_color,
		"bounce_color": Color(0.42, 0.94, 1.0),
		"aura_color": aura_color,
		"glow": glow,
		"trail_style": trail_style,
	}


func get_summary() -> Dictionary:
	var branches := {}
	for branch in BRANCH_ORDER:
		var labels: Array[String] = []
		for node in get_branch_nodes().get(branch, []):
			var label := str(node.get("name", "No"))
			var stack := int(node.get("stack", 1))
			if stack > 1:
				label += " x%d" % stack
			labels.append(label)
		branches[branch] = labels

	return {
		"branches": branches,
		"synergies": get_synergies(),
		"base_spell": _base_spell.duplicate(true),
	}


func get_ordered_labels() -> Array[String]:
	var base_label := str(_base_spell.get("delivery_name", "Projetil"))
	var labels: Array[String] = [base_label]
	for node in get_ordered_nodes():
		var label := str(node.get("node_label", node.get("name", "No")))
		var stack := int(node.get("stack", 1))
		if stack > 1:
			label += " x%d" % stack
		labels.append(label)
	return labels


func has_node(node_id: String) -> bool:
	return _nodes_by_id.has(node_id)


func _get_branch_for_category(category: String) -> String:
	match category:
		"power":
			return "energy"
		"rhythm":
			return "rhythm"
		"body", "area":
			return "core"
		_:
			return "form"
