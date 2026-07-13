class_name SpellDeliveryData
extends RefCounted

const DELIVERIES := {
	"simple_projectile": {
		"id": "simple_projectile",
		"display_name": "Simple Projectile",
		"description": "Fires automatically at the closest enemy.",
		"available": true,
		"tags": ["automatic", "single target"],
	},
	"chain_lightning": {
		"id": "chain_lightning",
		"display_name": "Chain Lightning",
		"description": "Hits up to 3 nearby targets; damage falls off per jump. Strong against groups.",
		"available": true,
		"tags": ["chain", "groups"],
	},
	"area": {
		"id": "area",
		"display_name": "Area Field",
		"description": "Creates a temporary field that deals periodic damage. Strong against slow groups.",
		"available": true,
		"tags": ["area", "control"],
	},
	"slash": {
		"id": "slash",
		"display_name": "Slash",
		"description": "Performs a fast cut on the closest enemy. Starts limited but scales with range, cadence, and multiple cuts.",
		"available": true,
		"tags": ["instant", "nearby target"],
	},
	"persistent_waves": {
		"id": "persistent_waves",
		"display_name": "Persistent Waves",
		"description": "Launches waves toward the target.",
		"available": false,
		"tags": ["future", "wave"],
	},
	"summon": {
		"id": "summon",
		"display_name": "Summon",
		"description": "Creates echoes or mini clones that attack on their own.",
		"available": false,
		"tags": ["future", "echo"],
	},
}


static func get_data(delivery_id: String) -> Dictionary:
	var resolved_id := delivery_id if DELIVERIES.has(delivery_id) else "simple_projectile"
	return DELIVERIES[resolved_id].duplicate(true)


static func get_all() -> Array[Dictionary]:
	var deliveries: Array[Dictionary] = []
	for delivery_id in ["simple_projectile", "chain_lightning", "area", "slash", "persistent_waves", "summon"]:
		deliveries.append(get_data(delivery_id))
	return deliveries
