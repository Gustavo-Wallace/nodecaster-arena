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


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "ecos", int(progress.get("ecos", 0)))
	config.set_value("records", "best_wave", int(progress.get("best_wave", 0)))
	config.set_value("records", "best_score", int(progress.get("best_score", 0)))
	config.set_value("records", "victories", int(progress.get("victories", 0)))
	config.set_value("unlocks", "characters", progress.get("unlocked_characters", BASIC_CHARACTER_IDS))
	config.set_value("unlocks", "upgrades", progress.get("unlocked_upgrades", BASIC_UPGRADE_IDS))
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
	if not can_unlock(unlock_id):
		return false

	var unlock_data: Dictionary = unlock_definitions[unlock_id]
	progress["ecos"] = int(progress.get("ecos", 0)) - int(unlock_data.get("cost", 0))

	match str(unlock_data.get("kind", "")):
		"character":
			_add_unlocked_id("unlocked_characters", str(unlock_data.get("target_id", "")))
		"upgrade":
			_add_unlocked_id("unlocked_upgrades", str(unlock_data.get("target_id", "")))

	save_progress()
	return true


func is_unlocked(unlock_id: String) -> bool:
	if not unlock_definitions.has(unlock_id):
		return false

	var unlock_data: Dictionary = unlock_definitions[unlock_id]
	match str(unlock_data.get("kind", "")):
		"character":
			return is_character_unlocked(str(unlock_data.get("target_id", "")))
		"upgrade":
			return is_upgrade_unlocked(str(unlock_data.get("target_id", "")))

	return false


func is_character_unlocked(character_id: String) -> bool:
	return _string_array_has(progress.get("unlocked_characters", []), character_id)


func is_upgrade_unlocked(upgrade_id: String) -> bool:
	return _string_array_has(progress.get("unlocked_upgrades", []), upgrade_id)


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
	}


func reset_progress() -> void:
	progress = _create_default_progress()
	save_progress()


func _create_default_progress() -> Dictionary:
	return {
		"ecos": 0,
		"unlocked_characters": BASIC_CHARACTER_IDS.duplicate(),
		"unlocked_upgrades": BASIC_UPGRADE_IDS.duplicate(),
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

	if loaded_values is Array:
		for value in loaded_values:
			var loaded_text := str(value)
			if not loaded_text.is_empty() and not merged.has(loaded_text):
				merged.append(loaded_text)

	return merged


func _string_array_has(values, needle: String) -> bool:
	if not (values is Array):
		return false

	for value in values:
		if str(value) == needle:
			return true

	return false
