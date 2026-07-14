class_name SpellDeliveryData
extends RefCounted

const DELIVERIES := {
	"simple_projectile": {
		"id": "simple_projectile",
		"display_name": "Simple Projectile",
		"description": "Fires automatically at the closest enemy.",
		"playstyle_summary": "Reliable direct fire for flexible builds.",
		"strengths": "Reliable, flexible, and compatible with most upgrades.",
		"weaknesses": "Needs scaling to clear dense groups efficiently.",
		"scaling_keywords": "count, pierce, ricochet, speed",
		"available": true,
		"tags": ["automatic", "single target"],
	},
	"chain_lightning": {
		"id": "chain_lightning",
		"display_name": "Chain Lightning",
		"description": "Links nearby enemies with falling damage per jump.",
		"playstyle_summary": "Cluster damage through fast chain links.",
		"strengths": "Excellent against clustered enemies and elemental setups.",
		"weaknesses": "Weaker against isolated targets; damage falls off per jump.",
		"scaling_keywords": "max hits, jump range, falloff, elements",
		"available": true,
		"tags": ["chain", "groups"],
	},
	"area": {
		"id": "area",
		"display_name": "Area Field",
		"description": "Places a temporary field that deals periodic damage.",
		"playstyle_summary": "Persistent zone control for slow or grouped enemies.",
		"strengths": "Controls space and pressures stationary groups.",
		"weaknesses": "Enemies can leave the field before repeated pulses land.",
		"scaling_keywords": "size, duration, tick rate, field count",
		"available": true,
		"tags": ["area", "control"],
	},
	"slash": {
		"id": "slash",
		"display_name": "Slash",
		"description": "Cuts the closest enemies in a fast, instant strike.",
		"playstyle_summary": "Close-range burst with aggressive multi-target scaling.",
		"strengths": "Satisfying burst against nearby targets.",
		"weaknesses": "Limited early reach and weak against spread-out enemies.",
		"scaling_keywords": "range, targets, cadence, empowered cuts",
		"available": true,
		"tags": ["instant", "nearby target"],
	},
	"persistent_waves": {
		"id": "persistent_waves",
		"display_name": "Persistent Waves",
		"description": "Launches a moving wave toward the nearest enemy.",
		"playstyle_summary": "Directional moving control against lined-up enemies.",
		"strengths": "Strong through chokepoints and aligned groups.",
		"weaknesses": "Can miss scattered enemies and depends on positioning.",
		"scaling_keywords": "width, speed, lifetime, extra waves",
		"available": true,
		"tags": ["directional", "wave", "groups"],
	},
	"summon": {
		"id": "summon",
		"display_name": "Summoning",
		"description": "Summons temporary echoes that attack nearby enemies.",
		"playstyle_summary": "Persistent autonomous echoes with elemental attacks.",
		"strengths": "Persistent damage, elemental effects, and strong duration scaling.",
		"weaknesses": "Slow setup, weaker burst, and limited early echo count.",
		"scaling_keywords": "echo count, lifetime, attack speed, damage",
		"available": true,
		"tags": ["summon", "persistent", "echo"],
	},
	"orbitals": {
		"id": "orbitals",
		"display_name": "Orbitals",
		"description": "Future Cast Type for persistent orbiting constructs.",
		"available": false,
		"tags": ["future", "orbitals"],
	},
	"dual_casting": {
		"id": "dual_casting",
		"display_name": "Dual Casting",
		"description": "Late-game Cast Type that combines two cast patterns.",
		"available": false,
		"tags": ["future", "late game"],
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
