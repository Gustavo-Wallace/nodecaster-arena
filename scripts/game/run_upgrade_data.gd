class_name RunUpgradeData
extends RefCounted


static func get_upgrades(playable_delivery_ids: Array) -> Array[Dictionary]:
	return [
		{
			"id": "arcane_damage", "name": "Arcane Damage", "description": "+5 projectile damage.",
			"category": "power", "branch": "energy", "effect_type": "projectile_damage", "node_label": "Damage",
			"compatible_deliveries": playable_delivery_ids,
			"values": {"damage_bonus": 5},
			"delivery_effects": {
				"chain_lightning": {"description": "+5 base damage per Chain Lightning target.", "impact_text": "+5 damage per target"},
				"area": {"description": "+5 damage per Area Field pulse.", "impact_text": "+5 damage per pulse"},
				"slash": {"description": "+5 damage per cut.", "impact_text": "+5 damage per cut"},
				"persistent_waves": {"description": "+5 damage per Persistent Wave hit.", "impact_text": "+5 Wave damage"},
			},
		},
		{
			"id": "unstable_cadence", "name": "Unstable Cadence", "description": "Automatic casts are 16% faster.",
			"category": "rhythm", "branch": "rhythm", "effect_type": "fire_interval", "node_label": "Cadence",
			"compatible_deliveries": playable_delivery_ids,
			"values": {"interval_multiplier": 0.84},
			"delivery_effects": {
				"chain_lightning": {"description": "Chain Lightning casts are 16% faster, respecting the minimum interval.", "impact_text": "-16% Chain interval"},
				"area": {"description": "Area Fields cast 16% faster, respecting the minimum interval.", "impact_text": "-16% Area interval"},
				"slash": {"description": "Slashes execute 16% faster, respecting the minimum interval.", "impact_text": "-16% Slash interval"},
				"persistent_waves": {"description": "Persistent Waves cast 16% faster, respecting the minimum interval.", "impact_text": "-16% Wave interval"},
			},
		},
		{
			"id": "light_core", "name": "Light Core", "description": "+35 movement speed.",
			"category": "body", "branch": "core", "effect_type": "player_speed", "node_label": "Core",
			"compatible_deliveries": playable_delivery_ids, "values": {"speed_bonus": 35.0},
		},
		{
			"id": "energy_shell", "name": "Energy Shell", "description": "+22 maximum health and heal 16.",
			"category": "body", "branch": "core", "effect_type": "player_health", "node_label": "Shell",
			"compatible_deliveries": playable_delivery_ids, "values": {"max_health_bonus": 22, "heal_amount": 16},
		},
		{
			"id": "swift_projectile", "name": "Swift Projectile", "description": "+80 projectile speed.",
			"category": "projectile", "branch": "form", "effect_type": "projectile_speed", "node_label": "Speed",
			"compatible_deliveries": playable_delivery_ids, "values": {"projectile_speed_bonus": 80.0},
			"delivery_effects": {
				"chain_lightning": {"name": "Chain Reach", "description": "Increases Chain Lightning initial range and jump range.", "impact_text": "+52 range, +24 jump"},
				"area": {"name": "Field Reach", "description": "Lets you create Area Fields farther from the core.", "impact_text": "+56 Area range"},
				"slash": {"name": "Extended Cut", "description": "Increases Slash targeting range.", "impact_text": "+48 Slash range"},
				"persistent_waves": {"name": "Wave Speed", "description": "Increases Persistent Wave travel speed.", "impact_text": "+80 Wave speed"},
				"summon": {"name": "Reflection Agility", "description": "Reflections move faster and attack from farther away.", "impact_text": "+36 range, +10% speed"},
			},
		},
		{
			"id": "initial_fragmentation", "name": "Initial Fragmentation", "description": "+1 projectile per cast in a spread.",
			"category": "projectile", "branch": "form", "effect_type": "projectile_count", "node_label": "Fragment",
			"compatible_deliveries": playable_delivery_ids, "values": {"projectile_count_bonus": 1},
			"max_stacks_by_delivery": {"simple_projectile": 16, "chain_lightning": 6, "area": 8, "slash": 8, "persistent_waves": 8, "summon": 7},
			"delivery_effects": {
				"chain_lightning": {"name": "Extra Link", "description": "Hits +1 total target per chain. {max_stacks} stack limit.", "impact_text": "+1 maximum target"},
				"area": {"name": "Field Size", "description": "Increases Area Field size. {max_stacks} stack limit.", "impact_text": "+18% Area size"},
				"slash": {"name": "Fragmented Cuts", "description": "Hits +1 nearby target per Slash. {max_stacks} stack limit.", "impact_text": "+1 target per cut"},
				"persistent_waves": {"name": "Wider Wave", "description": "Increases Persistent Wave width. {max_stacks} stack limit.", "impact_text": "+18% Wave width"},
				"summon": {"name": "Extra Reflection", "description": "Raises the active Reflection limit by 1. {max_stacks} stack limit.", "impact_text": "+1 active Reflection"},
			},
		},
		{
			"id": "piercing", "name": "Piercing", "description": "Projectiles pass through +1 enemy.",
			"category": "projectile", "branch": "form", "effect_type": "projectile_pierce", "node_label": "Pierce", "unlock_id": "upgrade_piercing",
			"values": {"pierce_bonus": 1}, "max_stacks_by_delivery": {"simple_projectile": 18, "chain_lightning": 5},
			"compatible_deliveries": ["simple_projectile", "chain_lightning"],
			"delivery_effects": {
				"chain_lightning": {"name": "Reduced Falloff", "description": "Each jump retains more damage. {max_stacks} stack limit.", "impact_text": "+5% damage retained per jump"},
			},
		},
		{
			"id": "ricochet", "name": "Ricochet", "description": "Projectiles ricochet +1 time from arena edges.",
			"category": "projectile", "branch": "form", "effect_type": "projectile_bounce", "node_label": "Ricochet",
			"values": {"bounce_bonus": 1}, "max_stacks_by_delivery": {"simple_projectile": 14},
			"compatible_deliveries": ["simple_projectile"],
		},
		{
			"id": "arcane_explosion", "name": "Arcane Explosion", "description": "Impacts deal area damage.",
			"category": "power", "branch": "energy", "effect_type": "area_explosion", "node_label": "Explode",
			"compatible_deliveries": playable_delivery_ids,
			"values": {"radius_bonus": 60.0, "damage_multiplier_bonus": 0.5},
			"delivery_effects": {
				"chain_lightning": {"description": "Only the first Chain Lightning target creates an arcane explosion.", "impact_text": "Explosion on first target"},
				"area": {"description": "Creating an Area Field causes a reduced initial arcane impact.", "impact_text": "Initial Area impact"},
				"slash": {"description": "The first cut creates a reduced arcane explosion.", "impact_text": "Explosion on first cut"},
				"persistent_waves": {"description": "The first enemy hit by each wave creates a reduced arcane explosion.", "impact_text": "Explosion on first Wave hit"},
			},
		},
		{
			"id": "heavy_orb", "name": "Heavy Orb", "description": "+40% damage, -15% speed, larger projectile.",
			"category": "projectile", "branch": "form", "effect_type": "heavy_projectile", "node_label": "Orb",
			"compatible_deliveries": playable_delivery_ids,
			"values": {"damage_multiplier": 1.4, "speed_multiplier": 0.85, "size_bonus": 0.2},
			"max_stacks_by_delivery": {"chain_lightning": 8, "area": 8, "slash": 8, "persistent_waves": 8, "summon": 6},
			"delivery_effects": {
				"chain_lightning": {"name": "Heavy Discharge", "description": "+40% Chain Lightning damage with -12% initial range.", "impact_text": "+40% damage, -12% range"},
				"area": {"name": "Dense Field", "description": "+40% damage and a larger Area Field with slower cadence.", "impact_text": "+40% damage, +20% size"},
				"slash": {"name": "Heavy Cut", "description": "+40% damage and a larger cut with slower cadence.", "impact_text": "+40% damage, +20% size"},
				"persistent_waves": {"name": "Heavy Wave", "description": "+40% damage, wider Persistent Waves, slower travel and cadence.", "impact_text": "+40% damage, +20% width"},
				"summon": {"name": "Heavy Reflection", "description": "Reflections hit harder but attack more slowly.", "impact_text": "+40% Reflection damage"},
			},
		},
		{
			"id": "cutting_echo", "name": "Cutting Echo", "description": "Every 4 casts, launches an extra strong projectile.",
			"category": "rhythm", "branch": "rhythm", "effect_type": "special_projectile", "node_label": "Echo",
			"values": {"shot_interval": 4, "damage_multiplier_bonus": 0.25},
			"max_stacks_by_delivery": {"chain_lightning": 8, "area": 8, "slash": 8, "persistent_waves": 8, "summon": 6},
			"compatible_deliveries": playable_delivery_ids,
			"delivery_effects": {
				"chain_lightning": {"name": "Resonant Echo", "description": "Every 4 chains, the next gains extra damage and +1 target.", "impact_text": "Echo: extra damage and +1 target"},
				"area": {"name": "Resonant Field", "description": "Every 4 fields, the next Area Field lasts longer.", "impact_text": "Echo: longer Field"},
				"slash": {"name": "Cutting Echo", "description": "Every 4 Slashes, performs an extra strong cut on another nearby target.", "impact_text": "Echo: extra strong cut"},
				"persistent_waves": {"name": "Wave Echo", "description": "Every 4 casts, launches a smaller extra wave at a slight angle.", "impact_text": "Echo: extra Wave"},
				"summon": {"name": "Reflection Rhythm", "description": "Every 4 Reflection attacks is strengthened.", "impact_text": "Reflection: empowered attack"},
			},
		},
		{
			"id": "unstable_field", "name": "Unstable Field", "description": "A weak aura deals periodic damage to nearby enemies.",
			"category": "area", "branch": "core", "effect_type": "player_aura", "node_label": "Field",
			"compatible_deliveries": playable_delivery_ids,
			"values": {"radius_bonus": 60.0, "damage_bonus": 6, "pulse_interval": 0.5},
		},
	]
