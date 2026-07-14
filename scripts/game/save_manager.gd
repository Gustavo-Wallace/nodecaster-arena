extends Node

const SAVE_PATH := "user://nodecaster_arena_save.cfg"
const SKILL_TREE_VERSION := 3

const BASIC_CHARACTER_IDS := ["circle", "triangle", "square"]
const BASIC_SPELL_SHAPE_IDS := ["circle", "triangle", "square"]
const BASIC_ELEMENT_IDS := ["arcane", "fire", "ice", "electric"]
const BASIC_CAST_TYPE_IDS := ["simple_projectile", "chain_lightning", "area", "slash", "persistent_waves", "summon"]
const BASIC_UPGRADE_IDS := [
	"arcane_damage",
	"unstable_cadence",
	"light_core",
	"energy_shell",
	"swift_projectile",
	"initial_fragmentation",
	"ricochet",
	"arcane_explosion",
	"heavy_orb",
	"cutting_echo",
	"unstable_field",
]

var progress: Dictionary = {}

var unlock_definitions := {
	"character_diamond": {
		"id": "character_diamond",
		"kind": "character",
		"target_id": "diamond",
		"display_name": "Diamond Core",
		"description": "An unstable form specialized in arcane power.",
		"cost": 25,
	},
	"upgrade_piercing": {
		"id": "upgrade_piercing",
		"kind": "upgrade",
		"target_id": "piercing",
		"display_name": "Piercing",
		"description": "Projectiles pass through 1 additional enemy.",
		"cost": 20,
	},
}

var skill_definitions := {
	"resonant_shell": {"id": "resonant_shell", "name": "Resonant Shell", "description": "At the start of each wave, gain 1 shield that absorbs the next hit.", "branch": "core", "cost": 14, "prerequisites": [], "effect_type": "wave_shield_charges", "effect_value": 1, "position": Vector2(910.0, 360.0)},
	"stable_window": {"id": "stable_window", "name": "Stable Window", "description": "After taking damage, become invulnerable for a brief moment.", "branch": "core", "cost": 20, "prerequisites": ["resonant_shell"], "effect_type": "post_hit_invulnerability_duration", "effect_value": 0.6, "position": Vector2(910.0, 245.0)},
	"emergency_pulse": {"id": "emergency_pulse", "name": "Emergency Pulse", "description": "Below 30% health, taking damage releases a defensive pulse.", "branch": "core", "cost": 32, "prerequisites": ["stable_window"], "effect_type": "emergency_pulse_radius", "effect_value": 138, "position": Vector2(720.0, 140.0)},
	"prepared_choice": {"id": "prepared_choice", "name": "Prepared Choice", "description": "Gain 1 reroll per run in the mutation panel.", "branch": "core", "cost": 18, "prerequisites": [], "effect_type": "upgrade_reroll_charges", "effect_value": 1, "position": Vector2(1210.0, 360.0)},
	"expanded_choices": {"id": "expanded_choices", "name": "Expanded Choices", "description": "Mutation panels show 4 options. You still choose only 1.", "branch": "core", "cost": 60, "prerequisites": ["prepared_choice"], "effect_type": "upgrade_option_bonus", "effect_value": 1, "position": Vector2(1400.0, 270.0)},
	"arcane_memory": {"id": "arcane_memory", "name": "Arcane Memory", "description": "Start each run with 1 random basic node already connected.", "branch": "core", "cost": 34, "prerequisites": ["prepared_choice"], "effect_type": "starting_random_mutation", "effect_value": 1, "position": Vector2(1400.0, 430.0)},
	"directed_tuning": {"id": "directed_tuning", "name": "Directed Tuning", "description": "The first mutation panel always includes an offensive option.", "branch": "core", "cost": 28, "prerequisites": ["expanded_choices"], "effect_type": "force_first_offensive_option", "effect_value": 1, "position": Vector2(1610.0, 350.0)},

	"unlock_matrix": {"id": "unlock_matrix", "name": "Unlock Matrix", "description": "Opens advanced branches for Spell Shapes, Elements, and Cast Types.", "branch": "unlocks", "cost": 20, "prerequisites": [], "position": Vector2(540.0, 655.0)},
	"unlock_diamond_shape": {"id": "unlock_diamond_shape", "name": "Diamond Shape", "description": "Unlocks Diamond Spell Shape: rapid casts with slightly lower damage.", "branch": "shape_unlocks", "cost": 28, "prerequisites": ["unlock_matrix"], "effect_type": "unlock_spell_shape", "target_id": "diamond", "position": Vector2(270.0, 530.0)},
	"unlock_star_shape": {"id": "unlock_star_shape", "name": "Star Shape", "description": "A future Spell Shape for multi-hit builds.", "branch": "shape_unlocks", "cost": 52, "prerequisites": ["unlock_diamond_shape"], "future": true, "position": Vector2(55.0, 430.0)},
	"unlock_shadow_element": {"id": "unlock_shadow_element", "name": "Shadow Element", "description": "Unlocks Shadow: a dark, high-impact element.", "branch": "element_unlocks", "cost": 30, "prerequisites": ["unlock_matrix"], "effect_type": "unlock_element", "target_id": "shadow", "position": Vector2(270.0, 705.0)},
	"unlock_light_element": {"id": "unlock_light_element", "name": "Light Element", "description": "A future healing and elite-focused element.", "branch": "element_unlocks", "cost": 56, "prerequisites": ["unlock_shadow_element"], "future": true, "position": Vector2(55.0, 805.0)},
	"unlock_persistent_waves": {"id": "unlock_persistent_waves", "name": "Persistent Waves", "description": "Implemented Cast Type. Available in the Arcane Workshop during development.", "branch": "cast_unlocks", "cost": 58, "prerequisites": ["unlock_matrix"], "implemented": true, "position": Vector2(480.0, 930.0)},
	"unlock_summoning": {"id": "unlock_summoning", "name": "Summoning", "description": "Implemented Cast Type for autonomous player Reflections.", "branch": "cast_unlocks", "cost": 78, "prerequisites": ["unlock_persistent_waves"], "implemented": true, "position": Vector2(650.0, 1040.0)},
	"unlock_orbitals": {"id": "unlock_orbitals", "name": "Orbitals", "description": "Future Cast Type. Coming soon.", "branch": "cast_unlocks", "cost": 70, "prerequisites": ["unlock_matrix"], "future": true, "position": Vector2(790.0, 910.0)},
	"unlock_dual_casting": {"id": "unlock_dual_casting", "name": "Dual Casting", "description": "Late-game Cast Type. Coming soon.", "branch": "cast_unlocks", "cost": 96, "prerequisites": ["unlock_orbitals"], "future": true, "position": Vector2(960.0, 860.0)},

	"projectile_calibration": {"id": "projectile_calibration", "name": "Projectile Calibration", "description": "Simple Projectile gains faster launch speed.", "branch": "cast_projectile", "cost": 18, "prerequisites": [], "scope": "cast_type", "scope_id": "simple_projectile", "bonus_type": "projectile_speed_multiplier", "effect_value": 0.16, "position": Vector2(1300.0, 650.0)},
	"opening_pierce": {"id": "opening_pierce", "name": "Opening Pierce", "description": "Simple Projectile gains +1 pierce during the first seconds of each wave.", "branch": "cast_projectile", "cost": 24, "prerequisites": ["projectile_calibration"], "scope": "cast_type", "scope_id": "simple_projectile", "bonus_type": "opening_pierce_duration", "effect_value": 4.5, "position": Vector2(1510.0, 560.0)},
	"stable_volley": {"id": "stable_volley", "name": "Stable Volley", "description": "Every 5th Simple Projectile cast fires a smaller extra shot.", "branch": "cast_projectile", "cost": 30, "prerequisites": ["projectile_calibration"], "scope": "cast_type", "scope_id": "simple_projectile", "bonus_type": "echo_interval", "effect_value": 5, "position": Vector2(1510.0, 700.0)},
	"conductive_path": {"id": "conductive_path", "name": "Conductive Path", "description": "Chain Lightning gains a longer jump range.", "branch": "cast_chain", "cost": 22, "prerequisites": [], "scope": "cast_type", "scope_id": "chain_lightning", "bonus_type": "jump_range_bonus", "effect_value": 34, "position": Vector2(1330.0, 810.0)},
	"static_memory": {"id": "static_memory", "name": "Static Memory", "description": "Every 5th Chain Lightning gains +1 maximum hit.", "branch": "cast_chain", "cost": 30, "prerequisites": ["conductive_path"], "scope": "cast_type", "scope_id": "chain_lightning", "bonus_type": "memory_interval", "effect_value": 5, "position": Vector2(1540.0, 810.0)},
	"reduced_falloff": {"id": "reduced_falloff", "name": "Reduced Falloff", "description": "Chain Lightning keeps more damage after each jump.", "branch": "cast_chain", "cost": 32, "prerequisites": ["static_memory"], "scope": "cast_type", "scope_id": "chain_lightning", "bonus_type": "falloff_bonus", "effect_value": 0.07, "position": Vector2(1750.0, 900.0)},
	"lingering_field": {"id": "lingering_field", "name": "Lingering Field", "description": "Area Field remains active longer.", "branch": "cast_area", "cost": 22, "prerequisites": [], "scope": "cast_type", "scope_id": "area", "bonus_type": "duration_multiplier", "effect_value": 0.24, "position": Vector2(1000.0, 1000.0)},
	"wider_field": {"id": "wider_field", "name": "Wider Field", "description": "Area Field covers a wider radius.", "branch": "cast_area", "cost": 28, "prerequisites": ["lingering_field"], "scope": "cast_type", "scope_id": "area", "bonus_type": "size_multiplier", "effect_value": 0.2, "position": Vector2(790.0, 1085.0)},
	"initial_pulse": {"id": "initial_pulse", "name": "Initial Pulse", "description": "Area Field releases a small impact pulse when created.", "branch": "cast_area", "cost": 30, "prerequisites": ["wider_field"], "scope": "cast_type", "scope_id": "area", "bonus_type": "initial_pulse_multiplier", "effect_value": 0.45, "position": Vector2(570.0, 1080.0)},
	"blade_rhythm": {"id": "blade_rhythm", "name": "Blade Rhythm", "description": "Every 5th Slash is empowered.", "branch": "cast_slash", "cost": 22, "prerequisites": [], "scope": "cast_type", "scope_id": "slash", "bonus_type": "empowered_interval", "effect_value": 5, "position": Vector2(1280.0, 1040.0)},
	"extended_edge": {"id": "extended_edge", "name": "Extended Edge", "description": "Slash gains additional reach.", "branch": "cast_slash", "cost": 26, "prerequisites": ["blade_rhythm"], "scope": "cast_type", "scope_id": "slash", "bonus_type": "range_bonus", "effect_value": 46, "position": Vector2(1500.0, 1040.0)},
	"second_cut": {"id": "second_cut", "name": "Second Cut", "description": "Slash can hit one additional nearby target.", "branch": "cast_slash", "cost": 34, "prerequisites": ["extended_edge"], "scope": "cast_type", "scope_id": "slash", "bonus_type": "target_bonus", "effect_value": 1, "position": Vector2(1710.0, 1130.0)},

	"arcane_focus": {"id": "arcane_focus", "name": "Arcane Focus", "description": "Arcane casts deal slightly more direct damage.", "branch": "element_arcane", "cost": 20, "prerequisites": [], "scope": "element", "scope_id": "arcane", "bonus_type": "damage_multiplier", "effect_value": 0.1, "position": Vector2(260.0, 1210.0)},
	"arcane_echo": {"id": "arcane_echo", "name": "Arcane Echo", "description": "Future arcane secondary pulse. Coming soon.", "branch": "element_arcane", "cost": 42, "prerequisites": ["arcane_focus"], "future": true, "position": Vector2(50.0, 1310.0)},
	"longer_burn": {"id": "longer_burn", "name": "Longer Burn", "description": "Fire burn lasts longer.", "branch": "element_fire", "cost": 20, "prerequisites": [], "scope": "element", "scope_id": "fire", "bonus_type": "effect_duration_multiplier", "effect_value": 0.35, "position": Vector2(810.0, 1290.0)},
	"hotter_burn": {"id": "hotter_burn", "name": "Hotter Burn", "description": "Fire burn deals more damage per tick.", "branch": "element_fire", "cost": 28, "prerequisites": ["longer_burn"], "scope": "element", "scope_id": "fire", "bonus_type": "effect_power_multiplier", "effect_value": 0.25, "position": Vector2(640.0, 1380.0)},
	"longer_chill": {"id": "longer_chill", "name": "Longer Chill", "description": "Ice slows enemies for longer.", "branch": "element_ice", "cost": 20, "prerequisites": [], "scope": "element", "scope_id": "ice", "bonus_type": "effect_duration_multiplier", "effect_value": 0.3, "position": Vector2(1050.0, 1290.0)},
	"deeper_chill": {"id": "deeper_chill", "name": "Deeper Chill", "description": "Ice applies a stronger slow.", "branch": "element_ice", "cost": 28, "prerequisites": ["longer_chill"], "scope": "element", "scope_id": "ice", "bonus_type": "slow_multiplier_bonus", "effect_value": 0.1, "position": Vector2(1050.0, 1380.0)},
	"higher_voltage": {"id": "higher_voltage", "name": "Higher Voltage", "description": "Electric casts deal slightly more damage.", "branch": "element_electric", "cost": 22, "prerequisites": [], "scope": "element", "scope_id": "electric", "bonus_type": "damage_multiplier", "effect_value": 0.1, "position": Vector2(1370.0, 1290.0)},
	"static_charge": {"id": "static_charge", "name": "Static Charge", "description": "Every 5th Electric cast is empowered.", "branch": "element_electric", "cost": 30, "prerequisites": ["higher_voltage"], "scope": "element", "scope_id": "electric", "bonus_type": "empowered_interval", "effect_value": 5, "position": Vector2(1580.0, 1370.0)},
}


func _ready() -> void:
	progress = _create_default_progress()
	load_progress()


func load_progress() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		progress = _create_default_progress()
		save_progress()
		return

	progress = _create_default_progress()
	progress["ecos"] = int(config.get_value("meta", "ecos", progress["ecos"]))
	progress["best_wave"] = int(config.get_value("records", "best_wave", progress["best_wave"]))
	progress["best_score"] = int(config.get_value("records", "best_score", progress["best_score"]))
	progress["victories"] = int(config.get_value("records", "victories", progress["victories"]))
	progress["unlocked_characters"] = _merge_unique_string_arrays(
		BASIC_CHARACTER_IDS,
		config.get_value("unlocks", "characters", progress["unlocked_characters"])
	)
	progress["unlocked_upgrades"] = _merge_unique_string_arrays(
		BASIC_UPGRADE_IDS,
		config.get_value("unlocks", "upgrades", progress["unlocked_upgrades"])
	)
	progress["purchased_skills"] = _merge_unique_string_arrays(
		[],
		config.get_value("skills", "purchased", progress["purchased_skills"])
	)
	var stored_skill_tree_version := int(config.get_value("skills", "tree_version", 1))
	if stored_skill_tree_version < SKILL_TREE_VERSION:
		_migrate_legacy_skill_purchases()
	progress["skill_tree_version"] = SKILL_TREE_VERSION
	_apply_skill_unlocks_to_progress()
	save_progress()


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "ecos", int(progress.get("ecos", 0)))
	config.set_value("records", "best_wave", int(progress.get("best_wave", 0)))
	config.set_value("records", "best_score", int(progress.get("best_score", 0)))
	config.set_value("records", "victories", int(progress.get("victories", 0)))
	config.set_value("unlocks", "characters", progress.get("unlocked_characters", BASIC_CHARACTER_IDS))
	config.set_value("unlocks", "upgrades", progress.get("unlocked_upgrades", BASIC_UPGRADE_IDS))
	config.set_value("skills", "purchased", progress.get("purchased_skills", []))
	config.set_value("skills", "tree_version", int(progress.get("skill_tree_version", SKILL_TREE_VERSION)))
	config.save(SAVE_PATH)


func apply_run_result(run_stats: Dictionary, victory: bool) -> Dictionary:
	var ecos_earned := calculate_run_ecos(run_stats)
	var final_score := int(run_stats.get("final_score", 0))
	var wave_reached := int(run_stats.get("max_wave_reached", 0))
	var previous_best_score := int(progress.get("best_score", 0))
	var previous_best_wave := int(progress.get("best_wave", 0))
	var new_best_score := final_score > previous_best_score
	var new_best_wave := wave_reached > previous_best_wave

	progress["ecos"] = int(progress.get("ecos", 0)) + ecos_earned
	progress["best_score"] = maxi(previous_best_score, final_score)
	progress["best_wave"] = maxi(previous_best_wave, wave_reached)
	if victory:
		progress["victories"] = int(progress.get("victories", 0)) + 1

	save_progress()

	return {
		"ecos_earned": ecos_earned,
		"total_ecos": int(progress.get("ecos", 0)),
		"new_best_score": new_best_score,
		"new_best_wave": new_best_wave,
		"victory_recorded": victory,
	}


func calculate_run_ecos(run_stats: Dictionary) -> int:
	var final_score := int(run_stats.get("final_score", 0))
	var wave_reached := int(run_stats.get("max_wave_reached", 0))
	var ecos := int(floor(float(final_score) / 100.0))

	if bool(run_stats.get("miniboss_defeated", false)):
		ecos += 5
	if bool(run_stats.get("boss_defeated", false)):
		ecos += 15
	if wave_reached > 2:
		ecos = maxi(ecos, 1)

	return ecos


func can_unlock(unlock_id: String) -> bool:
	if is_unlocked(unlock_id) or not unlock_definitions.has(unlock_id):
		return false

	var unlock_data: Dictionary = unlock_definitions[unlock_id]
	return int(progress.get("ecos", 0)) >= int(unlock_data.get("cost", 0))


func unlock(unlock_id: String) -> bool:
	var mapped_skill_id := _get_skill_id_for_legacy_unlock(unlock_id)
	if not mapped_skill_id.is_empty():
		return purchase_skill(mapped_skill_id)

	if not can_unlock(unlock_id):
		return false

	var unlock_data: Dictionary = unlock_definitions[unlock_id]
	progress["ecos"] = int(progress.get("ecos", 0)) - int(unlock_data.get("cost", 0))

	match str(unlock_data.get("kind", "")):
		"character":
			_add_unlocked_id("unlocked_characters", str(unlock_data.get("target_id", "")))
		"upgrade":
			_add_unlocked_id("unlocked_upgrades", str(unlock_data.get("target_id", "")))
			_add_unlocked_id("unlocked_upgrades", unlock_id)

	save_progress()
	return true


func get_skill_definitions() -> Array[Dictionary]:
	var skills: Array[Dictionary] = []
	for skill_id in _get_ordered_skill_ids():
		var skill_data: Dictionary = skill_definitions.get(skill_id, {})
		var skill: Dictionary = skill_data.duplicate(true)
		_apply_skill_state(skill)
		skills.append(skill)

	return skills


func can_purchase_skill(skill_id: String) -> bool:
	return bool(_get_skill_purchase_status(skill_id).get("can_purchase", false))


func purchase_skill(skill_id: String) -> bool:
	if not can_purchase_skill(skill_id):
		return false

	var skill: Dictionary = skill_definitions.get(skill_id, {})
	progress["ecos"] = int(progress.get("ecos", 0)) - int(skill.get("cost", 0))
	_add_unlocked_id("purchased_skills", skill_id)
	_apply_skill_unlocks_to_progress()
	save_progress()
	return true


func is_skill_purchased(skill_id: String) -> bool:
	return _string_array_has(progress.get("purchased_skills", []), skill_id)


func has_skill(skill_id: String) -> bool:
	return is_skill_purchased(skill_id)


func is_spell_shape_unlocked(shape_id: String) -> bool:
	if shape_id in BASIC_SPELL_SHAPE_IDS:
		return true
	return _is_scope_target_unlocked("unlock_spell_shape", shape_id)


func is_element_unlocked(element_id: String) -> bool:
	var resolved_id := _resolve_element_id(element_id)
	if resolved_id in BASIC_ELEMENT_IDS:
		return true
	return _is_scope_target_unlocked("unlock_element", resolved_id)


func is_cast_type_unlocked(cast_type_id: String) -> bool:
	if cast_type_id in BASIC_CAST_TYPE_IDS:
		return true
	return _is_scope_target_unlocked("unlock_cast_type", cast_type_id)


func get_cast_type_bonus(cast_type_id: String, bonus_type: String) -> float:
	return _get_scoped_bonus("cast_type", cast_type_id, bonus_type)


func get_element_bonus(element_id: String, bonus_type: String) -> float:
	return _get_scoped_bonus("element", _resolve_element_id(element_id), bonus_type)


func get_skill_effect_value(effect_type: String) -> float:
	var total := 0.0
	for skill_id in progress.get("purchased_skills", []):
		if not skill_definitions.has(str(skill_id)):
			continue
		var skill: Dictionary = skill_definitions.get(str(skill_id), {})
		if str(skill.get("effect_type", "")) == effect_type:
			total += float(skill.get("effect_value", 0.0))

	return total


func get_upgrade_option_count() -> int:
	return 3 + int(get_skill_effect_value("upgrade_option_bonus"))


func is_unlocked(unlock_id: String) -> bool:
	if not unlock_definitions.has(unlock_id):
		return is_upgrade_unlocked(unlock_id) or is_character_unlocked(unlock_id)

	var unlock_data: Dictionary = unlock_definitions[unlock_id]
	match str(unlock_data.get("kind", "")):
		"character":
			return is_character_unlocked(str(unlock_data.get("target_id", ""))) or is_character_unlocked(unlock_id)
		"upgrade":
			return is_upgrade_unlocked(str(unlock_data.get("target_id", ""))) or is_upgrade_unlocked(unlock_id)

	return false


func is_character_unlocked(character_id: String) -> bool:
	if _string_array_has(progress.get("unlocked_characters", []), character_id):
		return true

	for unlock_id in unlock_definitions.keys():
		var unlock_data: Dictionary = unlock_definitions[unlock_id]
		if str(unlock_data.get("kind", "")) != "character":
			continue
		if str(unlock_data.get("target_id", "")) == character_id:
			return _string_array_has(progress.get("unlocked_characters", []), str(unlock_id))

	return false


func is_upgrade_unlocked(upgrade_id: String) -> bool:
	if _string_array_has(progress.get("unlocked_upgrades", []), upgrade_id):
		return true

	for unlock_id in unlock_definitions.keys():
		var unlock_data: Dictionary = unlock_definitions[unlock_id]
		if str(unlock_data.get("kind", "")) != "upgrade":
			continue
		if str(unlock_data.get("target_id", "")) == upgrade_id:
			return _string_array_has(progress.get("unlocked_upgrades", []), str(unlock_id))

	return false


func get_unlock_definitions() -> Array[Dictionary]:
	var unlocks: Array[Dictionary] = []
	for unlock_id in ["character_diamond", "upgrade_piercing"]:
		var unlock_data: Dictionary = unlock_definitions[unlock_id].duplicate(true)
		unlock_data["unlocked"] = is_unlocked(unlock_id)
		unlock_data["can_unlock"] = can_unlock(unlock_id)
		unlocks.append(unlock_data)

	return unlocks


func get_summary() -> Dictionary:
	return {
		"ecos": int(progress.get("ecos", 0)),
		"best_wave": int(progress.get("best_wave", 0)),
		"best_score": int(progress.get("best_score", 0)),
		"victories": int(progress.get("victories", 0)),
		"purchased_skills": _merge_unique_string_arrays([], progress.get("purchased_skills", [])),
	}


func reset_progress() -> void:
	progress = _create_default_progress()
	save_progress()


func _create_default_progress() -> Dictionary:
	return {
		"ecos": 0,
		"unlocked_characters": BASIC_CHARACTER_IDS.duplicate(),
		"unlocked_upgrades": BASIC_UPGRADE_IDS.duplicate(),
		"purchased_skills": [],
		"skill_tree_version": SKILL_TREE_VERSION,
		"best_wave": 0,
		"best_score": 0,
		"victories": 0,
	}


func _add_unlocked_id(key: String, value: String) -> void:
	if value.is_empty():
		return

	var current := _merge_unique_string_arrays([], progress.get(key, []))
	if not current.has(value):
		current.append(value)
	progress[key] = current


func _merge_unique_string_arrays(required_values: Array, loaded_values) -> Array[String]:
	var merged: Array[String] = []

	for value in required_values:
		var text := str(value)
		if not merged.has(text):
			merged.append(text)

	if loaded_values is Array or loaded_values is PackedStringArray:
		for value in loaded_values:
			var loaded_text := str(value)
			if not loaded_text.is_empty() and not merged.has(loaded_text):
				merged.append(loaded_text)

	return merged


func _string_array_has(values, needle: String) -> bool:
	if not (values is Array or values is PackedStringArray):
		return false

	for value in values:
		if str(value) == needle:
			return true

	return false


func _get_ordered_skill_ids() -> Array[String]:
	return [
		"resonant_shell",
		"stable_window",
		"emergency_pulse",
		"prepared_choice",
		"expanded_choices",
		"arcane_memory",
		"directed_tuning",
		"unlock_matrix",
		"unlock_diamond_shape",
		"unlock_star_shape",
		"unlock_shadow_element",
		"unlock_light_element",
		"unlock_persistent_waves",
		"unlock_summoning",
		"unlock_orbitals",
		"unlock_dual_casting",
		"projectile_calibration",
		"opening_pierce",
		"stable_volley",
		"conductive_path",
		"static_memory",
		"reduced_falloff",
		"lingering_field",
		"wider_field",
		"initial_pulse",
		"blade_rhythm",
		"extended_edge",
		"second_cut",
		"arcane_focus",
		"arcane_echo",
		"longer_burn",
		"hotter_burn",
		"longer_chill",
		"deeper_chill",
		"higher_voltage",
		"static_charge",
	]


func _apply_skill_state(skill: Dictionary) -> void:
	var status := _get_skill_purchase_status(str(skill.get("id", "")))
	for key in status.keys():
		skill[key] = status[key]


func _get_skill_purchase_status(skill_id: String) -> Dictionary:
	if not skill_definitions.has(skill_id):
		return {
			"purchased": false,
			"available": false,
			"affordable": false,
			"can_purchase": false,
			"locked_reason": "Unknown skill.",
		}

	var skill: Dictionary = skill_definitions.get(skill_id, {})
	var purchased := is_skill_purchased(skill_id)
	var future := bool(skill.get("future", false))
	var prerequisites_met := _are_skill_prerequisites_met(skill)
	var affordable := int(progress.get("ecos", 0)) >= int(skill.get("cost", 0))
	var locked_reason := ""

	if future:
		locked_reason = "Coming soon."
	elif purchased:
		locked_reason = "Purchased."
	elif not prerequisites_met:
		locked_reason = "Requirements not met."
	elif not affordable:
		locked_reason = "Not enough Echoes."

	return {
		"purchased": purchased,
		"available": prerequisites_met and not future,
		"affordable": affordable,
		"can_purchase": not purchased and not future and prerequisites_met and affordable,
		"locked_reason": locked_reason,
	}


func _are_skill_prerequisites_met(skill: Dictionary) -> bool:
	var prerequisites = skill.get("prerequisites", [])
	if not (prerequisites is Array or prerequisites is PackedStringArray):
		return true

	for prerequisite in prerequisites:
		if not is_skill_purchased(str(prerequisite)):
			return false

	return true


func _apply_skill_unlocks_to_progress() -> void:
	for skill_id in progress.get("purchased_skills", []):
		if not skill_definitions.has(str(skill_id)):
			continue

		var skill: Dictionary = skill_definitions.get(str(skill_id), {})
		match str(skill.get("effect_type", "")):
			"unlock_character":
				_add_unlocked_id("unlocked_characters", str(skill.get("target_id", "")))
			"unlock_upgrade":
				var upgrade_id := str(skill.get("target_id", ""))
				_add_unlocked_id("unlocked_upgrades", upgrade_id)
				if upgrade_id == "piercing":
					_add_unlocked_id("unlocked_upgrades", "upgrade_piercing")


func _is_scope_target_unlocked(effect_type: String, target_id: String) -> bool:
	for skill_id in progress.get("purchased_skills", []):
		var skill: Dictionary = skill_definitions.get(str(skill_id), {})
		if str(skill.get("effect_type", "")) == effect_type and str(skill.get("target_id", "")) == target_id:
			return true
	return false


func _get_scoped_bonus(scope: String, scope_id: String, bonus_type: String) -> float:
	var total: float = 0.0
	for skill_id in progress.get("purchased_skills", []):
		var skill: Dictionary = skill_definitions.get(str(skill_id), {})
		if str(skill.get("scope", "")) != scope:
			continue
		if str(skill.get("scope_id", "")) != scope_id:
			continue
		if str(skill.get("bonus_type", "")) == bonus_type:
			total += float(skill.get("effect_value", 0.0))
	return total


func _resolve_element_id(element_id: String) -> String:
	return "electric" if element_id == "lightning" else element_id


func _migrate_legacy_skill_purchases() -> void:
	var legacy_mapping := {
		"catalyzed_shot": "projectile_calibration",
		"opening_charge": "opening_pierce",
		"initial_fragment": "arcane_memory",
		"unlock_piercing": "opening_pierce",
		"expanded_options": "expanded_choices",
		"directed_affinity": "directed_tuning",
		"synergy_resonance": "directed_tuning",
		"field_repair": "emergency_pulse",
	}
	var migrated: Array[String] = []
	for skill_id in progress.get("purchased_skills", []):
		var source_id := str(skill_id)
		var target_id := str(legacy_mapping.get(source_id, source_id))
		if skill_definitions.has(target_id) and not migrated.has(target_id):
			migrated.append(target_id)
	progress["purchased_skills"] = migrated


func _get_skill_id_for_legacy_unlock(_unlock_id: String) -> String:
	return ""
