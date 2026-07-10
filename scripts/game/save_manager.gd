extends Node

const SAVE_PATH := "user://nodecaster_arena_save.cfg"

const BASIC_CHARACTER_IDS := ["circle", "triangle", "square"]
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
		"display_name": "Losango",
		"description": "Forma instavel especializada em poder arcano.",
		"cost": 25,
	},
	"upgrade_piercing": {
		"id": "upgrade_piercing",
		"kind": "upgrade",
		"target_id": "piercing",
		"display_name": "Perfuracao",
		"description": "Projeteis atravessam 1 inimigo adicional.",
		"cost": 20,
	},
}

var skill_definitions := {
	"core_health_1": {
		"id": "core_health_1",
		"name": "Nucleo I",
		"description": "+5 vida maxima inicial.",
		"branch": "core",
		"cost": 8,
		"prerequisites": [],
		"effect_type": "starting_max_health_bonus",
		"effect_value": 5,
		"position": Vector2(40.0, 60.0),
	},
	"core_health_2": {
		"id": "core_health_2",
		"name": "Nucleo II",
		"description": "+5 vida maxima inicial.",
		"branch": "core",
		"cost": 15,
		"prerequisites": ["core_health_1"],
		"effect_type": "starting_max_health_bonus",
		"effect_value": 5,
		"position": Vector2(210.0, 60.0),
	},
	"core_repair_miniboss": {
		"id": "core_repair_miniboss",
		"name": "Reparo Inicial",
		"description": "Recupera 10 de vida ao derrotar o mini-boss.",
		"branch": "core",
		"cost": 24,
		"prerequisites": ["core_health_2"],
		"effect_type": "miniboss_heal_bonus",
		"effect_value": 10,
		"position": Vector2(380.0, 60.0),
	},
	"core_stability_1": {
		"id": "core_stability_1",
		"name": "Estabilidade",
		"description": "Reduz em 6% o dano recebido.",
		"branch": "core",
		"cost": 20,
		"prerequisites": ["core_health_1"],
		"effect_type": "incoming_damage_reduction",
		"effect_value": 0.06,
		"position": Vector2(210.0, 140.0),
	},
	"projectile_damage_1": {
		"id": "projectile_damage_1",
		"name": "Faisca I",
		"description": "+1 dano inicial dos projeteis.",
		"branch": "projectile",
		"cost": 8,
		"prerequisites": [],
		"effect_type": "starting_projectile_damage_bonus",
		"effect_value": 1,
		"position": Vector2(40.0, 250.0),
	},
	"projectile_damage_2": {
		"id": "projectile_damage_2",
		"name": "Faisca II",
		"description": "+1 dano inicial dos projeteis.",
		"branch": "projectile",
		"cost": 16,
		"prerequisites": ["projectile_damage_1"],
		"effect_type": "starting_projectile_damage_bonus",
		"effect_value": 1,
		"position": Vector2(210.0, 250.0),
	},
	"projectile_speed_1": {
		"id": "projectile_speed_1",
		"name": "Impulso Arcano",
		"description": "+10% velocidade inicial dos projeteis.",
		"branch": "projectile",
		"cost": 22,
		"prerequisites": ["projectile_damage_2"],
		"effect_type": "starting_projectile_speed_bonus_multiplier",
		"effect_value": 0.1,
		"position": Vector2(380.0, 250.0),
	},
	"initial_rhythm": {
		"id": "initial_rhythm",
		"name": "Ritmo Inicial",
		"description": "Reduz em 7% o intervalo inicial de disparo.",
		"branch": "projectile",
		"cost": 28,
		"prerequisites": ["projectile_speed_1"],
		"effect_type": "starting_fire_interval_reduction_multiplier",
		"effect_value": 0.07,
		"position": Vector2(550.0, 250.0),
	},
	"unlock_piercing": {
		"id": "unlock_piercing",
		"name": "Perfuracao",
		"description": "Libera o no Perfuracao nas runs.",
		"branch": "arcane",
		"cost": 20,
		"prerequisites": [],
		"effect_type": "unlock_upgrade",
		"target_id": "piercing",
		"effect_value": 1,
		"position": Vector2(40.0, 430.0),
	},
	"expanded_options": {
		"id": "expanded_options",
		"name": "Opcoes Ampliadas",
		"description": "Mostra 4 mutacoes entre ondas. Voce ainda escolhe 1.",
		"branch": "arcane",
		"cost": 60,
		"prerequisites": ["unlock_piercing", "projectile_damage_2"],
		"effect_type": "upgrade_option_bonus",
		"effect_value": 1,
		"position": Vector2(380.0, 430.0),
	},
	"unlock_diamond": {
		"id": "unlock_diamond",
		"name": "Losango",
		"description": "Libera a forma Losango na selecao de personagem.",
		"branch": "forms",
		"cost": 25,
		"prerequisites": [],
		"effect_type": "unlock_character",
		"target_id": "diamond",
		"effect_value": 1,
		"position": Vector2(40.0, 570.0),
	},
	"future_star": {
		"id": "future_star",
		"name": "Estrela",
		"description": "Forma futura preparada para uma proxima etapa.",
		"branch": "forms",
		"cost": 0,
		"prerequisites": ["unlock_diamond"],
		"effect_type": "future",
		"effect_value": 0,
		"position": Vector2(220.0, 570.0),
		"future": true,
	},
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
	_migrate_legacy_unlocks_to_skills()
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
		"core_health_1",
		"core_health_2",
		"core_repair_miniboss",
		"core_stability_1",
		"projectile_damage_1",
		"projectile_damage_2",
		"projectile_speed_1",
		"initial_rhythm",
		"unlock_piercing",
		"expanded_options",
		"unlock_diamond",
		"future_star",
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
			"locked_reason": "Skill desconhecida.",
		}

	var skill: Dictionary = skill_definitions.get(skill_id, {})
	var purchased := is_skill_purchased(skill_id)
	var future := bool(skill.get("future", false))
	var prerequisites_met := _are_skill_prerequisites_met(skill)
	var affordable := int(progress.get("ecos", 0)) >= int(skill.get("cost", 0))
	var locked_reason := ""

	if future:
		locked_reason = "Em breve."
	elif purchased:
		locked_reason = "Comprada."
	elif not prerequisites_met:
		locked_reason = "Requisitos pendentes."
	elif not affordable:
		locked_reason = "Ecos insuficientes."

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


func _migrate_legacy_unlocks_to_skills() -> void:
	if _string_array_has(progress.get("unlocked_characters", []), "diamond") or _string_array_has(progress.get("unlocked_characters", []), "character_diamond"):
		_add_unlocked_id("purchased_skills", "unlock_diamond")

	if _string_array_has(progress.get("unlocked_upgrades", []), "piercing") or _string_array_has(progress.get("unlocked_upgrades", []), "upgrade_piercing"):
		_add_unlocked_id("purchased_skills", "unlock_piercing")


func _get_skill_id_for_legacy_unlock(unlock_id: String) -> String:
	match unlock_id:
		"character_diamond":
			return "unlock_diamond"
		"upgrade_piercing":
			return "unlock_piercing"
		_:
			return ""
