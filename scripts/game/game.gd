extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CIRCLE_CHASER_SCENE := preload("res://scenes/enemies/circle_chaser.tscn")
const TRIANGLE_DASHER_SCENE := preload("res://scenes/enemies/triangle_dasher.tscn")
const SQUARE_TANK_SCENE := preload("res://scenes/enemies/square_tank.tscn")
const DIAMOND_SHOOTER_SCENE := preload("res://scenes/enemies/diamond_shooter.tscn")
const STAR_BOMBER_SCENE := preload("res://scenes/enemies/star_bomber.tscn")
const LINE_SNIPER_SCENE := preload("res://scenes/enemies/line_sniper.tscn")
const BASIC_PROJECTILE_SCENE := preload("res://scenes/projectiles/basic_projectile.tscn")
const GAME_HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const UPGRADE_PANEL_SCENE := preload("res://scenes/ui/upgrade_panel.tscn")
const SPELL_GRAPH_OVERLAY_SCENE := preload("res://scenes/ui/spell_graph_overlay.tscn")
const SPELL_GRAPH_SCRIPT := preload("res://scripts/game/spell_graph.gd")
const SPELL_BLUEPRINT_SCRIPT := preload("res://scripts/spells/spell_blueprint.gd")
const FLOATING_TEXT_SCENE := preload("res://scenes/ui/floating_text.tscn")
const BURST_EFFECT_SCENE := preload("res://scenes/effects/burst_effect.tscn")
const GEOMETRIC_SHATTER_SCENE := preload("res://scenes/effects/geometric_shatter.tscn")
const IMPACT_RING_SCENE := preload("res://scenes/effects/impact_ring.tscn")
const CHAIN_LIGHTNING_EFFECT_SCENE := preload("res://scenes/effects/chain_lightning_effect.tscn")
const AREA_SPELL_SCENE := preload("res://scenes/spells/area_spell.tscn")
const PERSISTENT_WAVE_SCENE := preload("res://scenes/spells/persistent_wave.tscn")
const SLASH_EFFECT_SCENE := preload("res://scenes/effects/slash_effect.tscn")
const PENTAGON_MINIBOSS_SCENE := preload("res://scenes/enemies/pentagon_miniboss.tscn")
const HEXAGON_BOSS_SCENE := preload("res://scenes/enemies/hexagon_boss.tscn")
const RUN_RESULT_PANEL_SCENE := preload("res://scenes/ui/run_result_panel.tscn")
const UNSTABLE_FIELD_AURA_SCRIPT := preload("res://scripts/effects/unstable_field_aura.gd")

@export var arena_position: Vector2 = Vector2(96.0, 72.0)
@export var arena_size: Vector2 = Vector2(1088.0, 576.0)
@export var arena_padding: Vector2 = Vector2(22.0, 18.0)
@export var auto_fire_interval: float = 0.45
@export var min_auto_fire_interval: float = 0.16
@export var projectile_damage: int = 12
@export var projectile_speed: float = 520.0
@export var projectile_count: int = 1
@export var max_projectile_count: int = 5
@export var projectile_spread_degrees: float = 12.0
@export var projectile_pierce: int = 0
@export var projectile_bounce: int = 0
@export var projectile_size_multiplier: float = 1.0
@export var projectile_explosion_radius: float = 0.0
@export var projectile_explosion_damage_multiplier: float = 0.0
@export var chain_range: float = 410.0
@export var chain_jump_range: float = 185.0
# max_hits inclui o primeiro alvo: a cadeia base nunca atinge mais de tres inimigos.
@export var chain_max_hits: int = 3
@export var chain_max_hits_cap: int = 8
@export var chain_max_jump_range: float = 320.0
@export var chain_min_cast_interval: float = 0.55
@export var chain_cast_interval_multiplier: float = 1.45
@export var chain_damage_falloff: float = 0.65
@export var chain_base_damage_multiplier: float = 0.68
@export var chain_visual_duration: float = 0.18
@export var area_range: float = 420.0
@export var area_radius: float = 78.0
@export var area_duration: float = 2.5
@export var area_tick_interval: float = 0.5
@export var area_tick_damage_multiplier: float = 0.35
@export var area_cast_interval_multiplier: float = 1.6
@export var area_min_cast_interval: float = 0.8
@export var area_max_active: int = 4
@export var area_max_duration: float = 5.0
@export var area_min_tick_interval: float = 0.25
@export var area_max_size_multiplier: float = 2.5
@export var slash_range: float = 260.0
@export var slash_damage_multiplier: float = 1.15
@export var slash_cast_interval_multiplier: float = 1.45
@export var slash_size_multiplier: float = 1.0
@export var slash_width: float = 10.0
@export var slash_targets: int = 1
@export var slash_visual_duration: float = 0.16
@export var slash_min_cast_interval: float = 0.45
@export var slash_max_targets: int = 6
@export var slash_max_range: float = 520.0
@export var slash_max_size_multiplier: float = 2.5
@export var wave_range: float = 500.0
@export var wave_speed: float = 340.0
@export var wave_lifetime: float = 1.4
@export var wave_damage_multiplier: float = 0.75
@export var wave_cast_interval_multiplier: float = 1.45
@export var wave_width: float = 70.0
@export var wave_length: float = 28.0
@export var wave_hit_cooldown_per_enemy: float = 0.35
@export var max_active_waves: int = 3
@export var wave_min_cast_interval: float = 0.55
@export var wave_max_width: float = 180.0
@export var wave_max_lifetime: float = 3.0
@export var wave_max_active: int = 5
@export var wave_max_speed: float = 620.0
@export var wave_min_hit_cooldown_per_enemy: float = 0.18
@export var base_enemies_per_wave: int = 1
@export var enemies_added_per_wave: int = 2
@export var wave_interval: float = 2.0
@export var enemy_health_per_wave: int = 6
@export var enemy_speed_per_wave: float = 8.0
@export var fallback_enemy_score_value: int = 10
@export var spawn_edge_padding: float = 28.0
@export var min_spawn_distance_from_player: float = 180.0
@export var max_run_wave: int = 10
@export var miniboss_wave: int = 5
@export var boss_wave: int = 10

var player: Node2D
var hud: Control
var pause_menu: Control
var upgrade_panel: Control
var spell_graph_overlay: Control
var result_panel: Control
var enemies: Array[Node2D] = []
var arena_rect: Rect2
var current_wave: int = 0
var current_wave_type: String = "normal"
var current_wave_modifier: Dictionary = {}
var score: int = 0
var spell_graph
var run_time_seconds: float = 0.0
var run_stats: Dictionary = {}
var selected_character_data: Dictionary = {}
var spell_blueprint
var selected_spell_summary: Dictionary = {}
var _spell_attributes: Dictionary = {}
var upgrade_stacks: Dictionary = {}
var active_synergies: Array[String] = []
var wave_modifiers_seen: Array[String] = []
var camera: Camera2D
var _auto_fire_timer: Timer
var _is_restarting: bool = false
var _wave_in_progress: bool = false
var _reward_open: bool = false
var _run_finished: bool = false
var _camera_shake_time_left: float = 0.0
var _camera_shake_duration: float = 0.0
var _camera_shake_strength: float = 0.0
var _rng := RandomNumberGenerator.new()
var _available_upgrades: Array[Dictionary] = []
var _wave_enemy_counts: Dictionary = {}
var _shot_sequence: int = 0
var _cutting_echo_interval: int = 0
var _cutting_echo_damage_multiplier: float = 1.5
var _unstable_field_enabled := false
var _unstable_field_radius: float = 0.0
var _unstable_field_damage: int = 0
var _unstable_field_interval: float = 0.5
var _unstable_field_time_left: float = 0.0
var _unstable_field_aura: Node2D
var _rerolls_left: int = 0
var _has_shown_upgrade_panel: bool = false
var _opening_charge_time_left: float = 0.0
var _emergency_pulse_cooldown_left: float = 0.0
var _graph_open: bool = false
var _pause_open: bool = false
var _chain_range_bonus: float = 0.0
var _chain_jump_range_bonus: float = 0.0
var _chain_bonus_hits: int = 0
var _chain_falloff_bonus: float = 0.0
var _chain_range_multiplier: float = 1.0
var _active_area_spells: Array[Node2D] = []
var _area_range_bonus: float = 0.0
var _area_size_multiplier: float = 1.0
var _area_duration_multiplier: float = 1.0
var _area_damage_multiplier: float = 1.0
var _active_persistent_waves: Array[Node2D] = []
var _wave_speed_bonus: float = 0.0
var _wave_speed_multiplier: float = 1.0
var _wave_width_multiplier: float = 1.0
var _slash_range_bonus: float = 0.0
var _slash_size_multiplier: float = 1.0
var _slash_targets_bonus: int = 0
var _simple_projectile_echo_interval: int = 0
var _chain_memory_interval: int = 0
var _area_initial_pulse_multiplier: float = 0.0
var _slash_empowered_interval: int = 0
var _element_effect_duration_multiplier: float = 1.0
var _electric_empowered_interval: int = 0


func _ready() -> void:
	_rng.randomize()
	selected_character_data = _get_selected_character_data()
	spell_blueprint = _get_selected_spell_blueprint()
	selected_spell_summary = spell_blueprint.get_summary()
	_apply_selected_character_to_run()
	_apply_spell_blueprint_to_run()
	_available_upgrades = _filter_unlocked_upgrades(_create_upgrade_data())
	_wave_enemy_counts = _create_wave_enemy_counts()
	run_stats = _create_run_stats()
	spell_graph = SPELL_GRAPH_SCRIPT.new()
	spell_graph.reset()
	spell_graph.set_base_spell(selected_spell_summary)
	_configure_arena_to_viewport()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	_setup_camera()
	_spawn_player()
	_spawn_hud()
	_apply_meta_run_effects()
	_start_auto_fire()
	_start_wave(1)
	queue_redraw()


func _process(delta: float) -> void:
	if not _run_finished:
		run_time_seconds += delta
		_update_unstable_field(delta)
		var opening_charge_was_active := _opening_charge_time_left > 0.0
		_opening_charge_time_left = maxf(_opening_charge_time_left - delta, 0.0)
		_emergency_pulse_cooldown_left = maxf(_emergency_pulse_cooldown_left - delta, 0.0)
		if opening_charge_was_active:
			_update_meta_hud()
		if is_instance_valid(hud):
			hud.call("set_run_time", run_time_seconds)

	_update_camera_shake(delta)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
		if _graph_open:
			_close_spell_graph()
			get_viewport().set_input_as_handled()
			return
		if not _run_finished and not _reward_open:
			_open_pause_menu()
			get_viewport().set_input_as_handled()
			return

	if not _run_finished and not _graph_open and key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_G:
		_toggle_spell_graph()
		get_viewport().set_input_as_handled()
		return

	if not _run_finished:
		return

	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
		_restart_scene()


func _draw() -> void:
	draw_rect(arena_rect, Color(0.045, 0.055, 0.07), true)
	draw_rect(arena_rect, Color(0.26, 0.46, 0.62), false, 3.0)

	var inner_rect := arena_rect.grow(-8.0)
	draw_rect(inner_rect, Color(0.09, 0.13, 0.16), false, 1.0)


func _configure_arena_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	var safe_size := Vector2(
		maxf(viewport_size.x - arena_padding.x * 2.0, 320.0),
		maxf(viewport_size.y - arena_padding.y * 2.0, 240.0)
	)
	arena_position = arena_padding
	arena_size = safe_size
	arena_rect = Rect2(arena_position, arena_size)


func _on_viewport_size_changed() -> void:
	_configure_arena_to_viewport()
	if is_instance_valid(camera):
		camera.position = arena_rect.get_center()
	if is_instance_valid(player):
		player.call("set_arena_rect", arena_rect)

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_radius := float(enemy.get("radius"))
		enemy.global_position = Vector2(
			clampf(enemy.global_position.x, arena_rect.position.x + enemy_radius, arena_rect.end.x - enemy_radius),
			clampf(enemy.global_position.y, arena_rect.position.y + enemy_radius, arena_rect.end.y - enemy_radius)
		)

	queue_redraw()


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Node2D
	add_child(player)
	player.call("apply_character_data", selected_character_data)
	player.call(
		"apply_elemental_identity",
		_spell_attributes.get("fill_color", Color(0.18, 0.78, 1.0)),
		_spell_attributes.get("outline_color", Color(0.82, 0.98, 1.0))
	)
	player.set("incoming_damage_multiplier", _get_meta_incoming_damage_multiplier())
	player.global_position = arena_rect.get_center()
	player.call("set_arena_rect", arena_rect)
	player.connect("died", Callable(self, "_on_player_died"))
	player.connect("damage_taken", Callable(self, "_on_player_damage_taken"))
	if player.has_signal("shield_changed"):
		player.connect("shield_changed", Callable(self, "_on_player_shield_changed"))
	if player.has_signal("shield_absorbed"):
		player.connect("shield_absorbed", Callable(self, "_on_player_shield_absorbed"))


func _spawn_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HudLayer"
	add_child(hud_layer)

	hud = GAME_HUD_SCENE.instantiate() as Control
	hud_layer.add_child(hud)
	hud.call("bind_player", player)

	pause_menu = PAUSE_MENU_SCENE.instantiate() as Control
	hud_layer.add_child(pause_menu)
	pause_menu.connect("resume_requested", Callable(self, "_close_pause_menu"))
	pause_menu.connect("restart_requested", Callable(self, "_restart_scene"))
	pause_menu.connect("main_menu_requested", Callable(self, "_go_to_main_menu"))

	spell_graph_overlay = SPELL_GRAPH_OVERLAY_SCENE.instantiate() as Control
	hud_layer.add_child(spell_graph_overlay)
	spell_graph_overlay.connect("close_requested", Callable(self, "_close_spell_graph"))
	_refresh_spell_graph_panel()
	if hud.has_signal("graph_requested"):
		hud.connect("graph_requested", Callable(self, "_toggle_spell_graph"))

	upgrade_panel = UPGRADE_PANEL_SCENE.instantiate() as Control
	hud_layer.add_child(upgrade_panel)
	upgrade_panel.connect("upgrade_selected", Callable(self, "_on_upgrade_selected"))
	upgrade_panel.connect("reroll_requested", Callable(self, "_on_upgrade_reroll_requested"))

	result_panel = RUN_RESULT_PANEL_SCENE.instantiate() as Control
	hud_layer.add_child(result_panel)
	result_panel.connect("restart_requested", Callable(self, "_restart_scene"))
	result_panel.connect("main_menu_requested", Callable(self, "_go_to_main_menu"))


func _start_wave(wave_number: int) -> void:
	if _is_restarting or _run_finished:
		return

	if wave_number > max_run_wave:
		_finish_run(true)
		return

	current_wave = wave_number
	current_wave_type = _get_wave_type(current_wave)
	current_wave_modifier = _choose_wave_modifier(current_wave, current_wave_type)
	if not current_wave_modifier.is_empty():
		var modifier_name := str(current_wave_modifier.get("name", "Modifier"))
		wave_modifiers_seen.append(modifier_name)
	run_stats["max_wave_reached"] = maxi(int(run_stats.get("max_wave_reached", 0)), current_wave)
	_wave_in_progress = true
	_reward_open = false
	enemies.clear()
	_activate_wave_meta_effects()

	if is_instance_valid(_auto_fire_timer):
		_auto_fire_timer.wait_time = auto_fire_interval
		_auto_fire_timer.start()

	if current_wave_type == "boss" or current_wave_type == "mini_boss":
		_play_audio("play_boss_spawn")
	else:
		_play_audio("play_wave_start")

	_spawn_wave_enemies()

	_update_hud()
	_update_meta_hud()
	hud.call("set_wave_message", _get_wave_message())


func _get_wave_type(wave_number: int) -> String:
	if wave_number == boss_wave:
		return "boss"
	if wave_number == miniboss_wave:
		return "mini_boss"

	return "normal"


func _create_wave_enemy_counts() -> Dictionary:
	return {
		1: 3,
		2: 4,
		3: 6,
		4: 7,
		6: 9,
		7: 10,
		8: 11,
		9: 12,
	}


func _create_run_stats() -> Dictionary:
	return {
		"character_id": str(selected_character_data.get("id", "circle")),
		"character_name": str(selected_character_data.get("display_name", "Circle")),
		"spell_blueprint": selected_spell_summary.duplicate(true),
		"run_time_seconds": 0.0,
		"max_wave_reached": 0,
		"final_score": 0,
		"total_enemies_defeated": 0,
		"enemy_kills": {
			"circle_chaser": 0,
			"triangle_dasher": 0,
			"square_tank": 0,
			"diamond_shooter": 0,
			"star_bomber": 0,
			"line_sniper": 0,
			"pentagon_miniboss": 0,
			"hexagon_boss": 0,
		},
		"miniboss_defeated": false,
		"boss_defeated": false,
		"upgrades_chosen": 0,
		"build_nodes": [],
		"spell_graph": {},
	}


func _get_selected_character_data() -> Dictionary:
	var run_config := get_node_or_null("/root/RunConfig")
	if run_config == null:
		return {
			"id": "circle",
			"display_name": "Circle",
			"max_health": 100,
			"move_speed": 320.0,
			"projectile_damage": 12,
			"projectile_speed": 520.0,
			"fire_interval": 0.45,
			"projectile_count": 1,
			"visual_shape": "circle",
			"fill_color": Color(0.18, 0.78, 1.0),
			"outline_color": Color(0.82, 0.98, 1.0),
		}

	return run_config.call("get_selected_character_data")


func _apply_selected_character_to_run() -> void:
	_apply_meta_skill_bonuses_to_selected_character()
	projectile_damage = int(selected_character_data.get("projectile_damage", projectile_damage))
	projectile_speed = float(selected_character_data.get("projectile_speed", projectile_speed))
	projectile_count = int(selected_character_data.get("projectile_count", projectile_count))
	auto_fire_interval = float(selected_character_data.get("fire_interval", auto_fire_interval))


func _get_selected_spell_blueprint():
	var run_config := get_node_or_null("/root/RunConfig")
	if run_config != null and run_config.has_method("get_spell_blueprint"):
		return run_config.call("get_spell_blueprint")
	return SPELL_BLUEPRINT_SCRIPT.new()


func _apply_spell_blueprint_to_run() -> void:
	if spell_blueprint == null:
		return

	_spell_attributes = spell_blueprint.get_initial_attributes()
	projectile_damage = maxi(1, int(round(float(projectile_damage) * float(_spell_attributes.get("damage_multiplier", 1.0)))))
	projectile_speed *= float(_spell_attributes.get("projectile_speed_multiplier", 1.0))
	auto_fire_interval = maxf(auto_fire_interval * float(_spell_attributes.get("fire_interval_multiplier", 1.0)), min_auto_fire_interval)
	if _is_chain_lightning_delivery():
		auto_fire_interval = maxf(auto_fire_interval * chain_cast_interval_multiplier, chain_min_cast_interval)
	elif _is_area_delivery():
		auto_fire_interval = maxf(auto_fire_interval * area_cast_interval_multiplier, area_min_cast_interval)
	elif _is_slash_delivery():
		auto_fire_interval = maxf(auto_fire_interval * slash_cast_interval_multiplier, slash_min_cast_interval)
	elif _is_persistent_waves_delivery():
		auto_fire_interval = maxf(auto_fire_interval * wave_cast_interval_multiplier, wave_min_cast_interval)
	projectile_size_multiplier *= float(_spell_attributes.get("size_multiplier", 1.0))
	projectile_pierce += int(_spell_attributes.get("pierce_bonus", 0))


func _apply_meta_skill_bonuses_to_selected_character() -> void:
	# Permanent skills now alter run behavior instead of character base stats.
	pass


func _apply_meta_run_effects() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return

	_rerolls_left = int(save_manager.call("get_skill_effect_value", "upgrade_reroll_charges"))
	if is_instance_valid(player) and player.has_method("set_post_hit_invulnerability"):
		var invulnerability := float(save_manager.call("get_skill_effect_value", "post_hit_invulnerability_duration"))
		player.call("set_post_hit_invulnerability", invulnerability)

	_apply_persistent_spell_masteries()
	_add_active_meta_nodes_to_graph()

	if _has_meta_skill("arcane_memory"):
		_apply_random_memory_upgrade()

	_update_meta_hud()


func _add_active_meta_nodes_to_graph() -> void:
	var meta_nodes := [
		{"skill": "resonant_shell", "id": "meta_resonant_shell", "name": "Resonant Shell", "label": "Shield", "branch": "core"},
		{"skill": "stable_window", "id": "meta_stable_window", "name": "Stable Window", "label": "Window", "branch": "core"},
		{"skill": "opening_pierce", "id": "meta_opening_pierce", "name": "Opening Pierce", "label": "Pierce", "branch": "rhythm"},
	]

	for meta_node in meta_nodes:
		if not _has_meta_skill(str(meta_node["skill"])):
			continue
		spell_graph.add_upgrade({
			"id": str(meta_node["id"]),
			"name": str(meta_node["name"]),
			"node_label": str(meta_node["label"]),
			"branch": str(meta_node["branch"]),
			"category": "rhythm" if str(meta_node["branch"]) == "rhythm" else "body",
		}, 1)

	_refresh_spell_graph_panel()


func _activate_wave_meta_effects() -> void:
	if is_instance_valid(player) and _has_meta_skill("resonant_shell") and player.has_method("set_shield_charges"):
		var charges := maxi(int(_get_meta_effect_value("wave_shield_charges")), 1)
		player.call("set_shield_charges", charges)
		_spawn_floating_text("SHIELD", player.global_position + Vector2(0.0, -34.0), Color(0.5, 0.94, 1.0), 0.58)

	_opening_charge_time_left = _get_cast_type_bonus("simple_projectile", "opening_pierce_duration") if _is_simple_projectile_cast_type() else 0.0
	if _opening_charge_time_left > 0.0 and is_instance_valid(player):
		_spawn_floating_text("CHARGE", player.global_position + Vector2(0.0, -52.0), Color(1.0, 0.84, 0.34), 0.5)


func _apply_starting_meta_upgrade(upgrade_id: String, message: String) -> void:
	var upgrade := _get_upgrade_by_id(upgrade_id)
	if upgrade.is_empty():
		return

	_add_spell_node_from_upgrade(upgrade)
	_apply_upgrade(upgrade)
	if is_instance_valid(player):
		_spawn_floating_text(message, player.global_position + Vector2(0.0, -46.0), Color(0.76, 0.96, 1.0), 0.7)


func _apply_random_memory_upgrade() -> void:
	var memory_pool := ["arcane_damage", "swift_projectile", "ricochet", "arcane_explosion", "energy_shell"]
	var candidates: Array[String] = []
	for upgrade_id in memory_pool:
		var upgrade := _get_upgrade_by_id(upgrade_id)
		if not upgrade.is_empty():
			candidates.append(upgrade_id)

	if candidates.is_empty():
		return

	_apply_starting_meta_upgrade(candidates[_rng.randi_range(0, candidates.size() - 1)], "ARCANE MEMORY")


func _get_upgrade_by_id(upgrade_id: String) -> Dictionary:
	for upgrade in _available_upgrades:
		if str(upgrade.get("id", "")) == upgrade_id and _is_upgrade_compatible_with_current_delivery(upgrade):
			return upgrade.duplicate(true)
	return {}


func _has_meta_skill(skill_id: String) -> bool:
	var save_manager := get_node_or_null("/root/SaveManager")
	return save_manager != null and bool(save_manager.call("is_skill_purchased", skill_id))


func _get_meta_effect_value(effect_type: String) -> float:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return 0.0
	return float(save_manager.call("get_skill_effect_value", effect_type))


func _get_cast_type_bonus(cast_type_id: String, bonus_type: String) -> float:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return 0.0
	return float(save_manager.call("get_cast_type_bonus", cast_type_id, bonus_type))


func _get_element_bonus(element_id: String, bonus_type: String) -> float:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return 0.0
	return float(save_manager.call("get_element_bonus", element_id, bonus_type))


func _apply_persistent_spell_masteries() -> void:
	var cast_type_id := str(selected_spell_summary.get("delivery_id", "simple_projectile"))
	match cast_type_id:
		"simple_projectile":
			projectile_speed *= 1.0 + _get_cast_type_bonus(cast_type_id, "projectile_speed_multiplier")
			_simple_projectile_echo_interval = int(_get_cast_type_bonus(cast_type_id, "echo_interval"))
		"chain_lightning":
			_chain_jump_range_bonus += _get_cast_type_bonus(cast_type_id, "jump_range_bonus")
			_chain_memory_interval = int(_get_cast_type_bonus(cast_type_id, "memory_interval"))
			_chain_falloff_bonus += _get_cast_type_bonus(cast_type_id, "falloff_bonus")
		"area":
			_area_duration_multiplier += _get_cast_type_bonus(cast_type_id, "duration_multiplier")
			_area_size_multiplier += _get_cast_type_bonus(cast_type_id, "size_multiplier")
			_area_initial_pulse_multiplier = _get_cast_type_bonus(cast_type_id, "initial_pulse_multiplier")
		"slash":
			_slash_range_bonus += _get_cast_type_bonus(cast_type_id, "range_bonus")
			_slash_empowered_interval = int(_get_cast_type_bonus(cast_type_id, "empowered_interval"))
			_slash_targets_bonus += int(_get_cast_type_bonus(cast_type_id, "target_bonus"))

	var element_id := str(selected_spell_summary.get("element_id", "arcane"))
	var damage_bonus := _get_element_bonus(element_id, "damage_multiplier")
	if damage_bonus > 0.0:
		projectile_damage = maxi(1, int(round(float(projectile_damage) * (1.0 + damage_bonus))))

	_element_effect_duration_multiplier += _get_element_bonus(element_id, "effect_duration_multiplier")
	if element_id == "fire":
		_spell_attributes["element_effect_power"] = float(_spell_attributes.get("element_effect_power", 0.0)) * (1.0 + _get_element_bonus(element_id, "effect_power_multiplier"))
	elif element_id == "ice":
		_spell_attributes["element_effect_power"] = maxf(0.35, float(_spell_attributes.get("element_effect_power", 0.72)) - _get_element_bonus(element_id, "slow_multiplier_bonus"))
	elif element_id == "lightning":
		_electric_empowered_interval = int(_get_element_bonus(element_id, "empowered_interval"))


func _spawn_wave_enemies() -> void:
	match current_wave_type:
		"mini_boss":
			_spawn_enemy(PENTAGON_MINIBOSS_SCENE, arena_rect.get_center() + Vector2(0.0, -120.0))
			for _index in range(2):
				_spawn_enemy(CIRCLE_CHASER_SCENE, _get_spawn_position_near_arena_edge())
		"boss":
			_spawn_enemy(HEXAGON_BOSS_SCENE, arena_rect.get_center() + Vector2(0.0, -110.0))
		_:
			var enemy_scenes := _build_enemy_scenes_for_wave(current_wave)
			for enemy_scene in enemy_scenes:
				_spawn_enemy(enemy_scene, _get_spawn_position_near_arena_edge())


func _get_enemy_count_for_wave(wave_number: int) -> int:
	if _wave_enemy_counts.has(wave_number):
		return int(_wave_enemy_counts[wave_number])

	return base_enemies_per_wave + wave_number * enemies_added_per_wave


func _build_enemy_scenes_for_wave(wave_number: int) -> Array[PackedScene]:
	var spawn_config := _get_spawn_config_for_wave(wave_number)
	var enemy_count := int(spawn_config.get("enemy_count", _get_enemy_count_for_wave(wave_number)))
	var enemy_pool := _get_enemy_pool_for_wave(wave_number, int(spawn_config.get("special_weight_bonus", 0)))
	var enemy_scenes: Array[PackedScene] = []

	for _index in range(enemy_count):
		enemy_scenes.append(_choose_enemy_scene_from_pool(enemy_pool))

	_shuffle_enemy_scenes(enemy_scenes)
	return enemy_scenes


func _get_spawn_config_for_wave(wave_number: int) -> Dictionary:
	var enemy_count := _get_enemy_count_for_wave(wave_number)
	var config := {
		"enemy_count": enemy_count,
		"health_multiplier": 1.0,
		"speed_multiplier": 1.0,
		"score_multiplier": 1.0,
		"special_weight_bonus": 0,
	}

	if current_wave_modifier.is_empty():
		return config

	config["enemy_count"] = maxi(1, int(round(float(enemy_count) * float(current_wave_modifier.get("count_multiplier", 1.0)))))
	config["health_multiplier"] = float(current_wave_modifier.get("health_multiplier", 1.0))
	config["speed_multiplier"] = float(current_wave_modifier.get("speed_multiplier", 1.0))
	config["score_multiplier"] = float(current_wave_modifier.get("score_multiplier", 1.0))
	config["special_weight_bonus"] = int(current_wave_modifier.get("special_weight_bonus", 0))
	return config


func _get_enemy_pool_for_wave(wave_number: int, special_weight_bonus: int = 0) -> Array[Dictionary]:
	var pool: Array[Dictionary] = [
		{"scene": CIRCLE_CHASER_SCENE, "weight": 100, "special": false},
	]

	if wave_number >= 2:
		pool = [
			{"scene": CIRCLE_CHASER_SCENE, "weight": 74, "special": false},
			{"scene": TRIANGLE_DASHER_SCENE, "weight": 26, "special": false},
		]
	if wave_number >= 3:
		pool = [
			{"scene": CIRCLE_CHASER_SCENE, "weight": 52, "special": false},
			{"scene": TRIANGLE_DASHER_SCENE, "weight": 25, "special": false},
			{"scene": SQUARE_TANK_SCENE, "weight": 23, "special": false},
		]
	if wave_number >= 4:
		pool = [
			{"scene": CIRCLE_CHASER_SCENE, "weight": 44, "special": false},
			{"scene": TRIANGLE_DASHER_SCENE, "weight": 22, "special": false},
			{"scene": SQUARE_TANK_SCENE, "weight": 20, "special": false},
			{"scene": DIAMOND_SHOOTER_SCENE, "weight": 14 + special_weight_bonus, "special": true},
		]
	if wave_number >= 6:
		pool.append({"scene": STAR_BOMBER_SCENE, "weight": 12 + special_weight_bonus, "special": true})
	if wave_number >= 8:
		pool.append({"scene": LINE_SNIPER_SCENE, "weight": 9 + special_weight_bonus, "special": true})

	return pool


func _choose_enemy_scene_from_pool(enemy_pool: Array[Dictionary]) -> PackedScene:
	var total_weight := 0
	for entry in enemy_pool:
		total_weight += int(entry.get("weight", 0))

	var roll := _rng.randi_range(1, maxi(total_weight, 1))
	var cursor := 0
	for entry in enemy_pool:
		cursor += int(entry.get("weight", 0))
		if roll <= cursor:
			var chosen_scene := entry.get("scene", CIRCLE_CHASER_SCENE) as PackedScene
			if chosen_scene != null:
				return chosen_scene

	return CIRCLE_CHASER_SCENE


func _shuffle_enemy_scenes(enemy_scenes: Array[PackedScene]) -> void:
	if enemy_scenes.size() < 2:
		return

	for index in range(enemy_scenes.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var stored_scene := enemy_scenes[index]
		enemy_scenes[index] = enemy_scenes[swap_index]
		enemy_scenes[swap_index] = stored_scene


func _spawn_enemy(enemy_scene: PackedScene, spawn_position: Vector2) -> void:
	var enemy := enemy_scene.instantiate() as Node2D
	_apply_wave_scaling_to_enemy(enemy)
	add_child(enemy)
	enemy.global_position = spawn_position
	enemy.call("setup", player)
	enemy.connect("died", Callable(self, "_on_enemy_died"))
	enemy.connect("damage_taken", Callable(self, "_on_enemy_damage_taken"))
	if enemy.has_signal("summon_requested"):
		enemy.connect("summon_requested", Callable(self, "_on_boss_summon_requested"))
	if enemy.has_signal("exploded"):
		enemy.connect("exploded", Callable(self, "_on_star_bomber_exploded"))
	if enemy.has_signal("laser_fired"):
		enemy.connect("laser_fired", Callable(self, "_on_line_sniper_laser_fired"))
	enemies.append(enemy)


func _apply_wave_scaling_to_enemy(enemy: Node) -> void:
	if current_wave_type != "normal":
		return

	var wave_bonus := maxi(current_wave - 1, 0)
	var base_health = enemy.get("max_health")
	var base_speed = enemy.get("speed")

	if base_health != null:
		var scaled_health := int(base_health) + wave_bonus * enemy_health_per_wave
		scaled_health = maxi(1, int(round(float(scaled_health) * float(current_wave_modifier.get("health_multiplier", 1.0)))))
		enemy.set("max_health", scaled_health)
	if base_speed != null:
		var scaled_speed := float(base_speed) + float(wave_bonus) * enemy_speed_per_wave
		scaled_speed *= float(current_wave_modifier.get("speed_multiplier", 1.0))
		enemy.set("speed", scaled_speed)

	var base_score = enemy.get("score_value")
	if base_score != null:
		enemy.set("score_value", int(round(float(base_score) * float(current_wave_modifier.get("score_multiplier", 1.0)))))


func _get_spawn_position_near_arena_edge() -> Vector2:
	var best_position := arena_rect.get_center()
	var best_distance := -1.0

	for _attempt in range(24):
		var candidate := _get_random_edge_position()
		var distance_to_player := INF

		if is_instance_valid(player):
			distance_to_player = candidate.distance_to(player.global_position)

		if distance_to_player >= min_spawn_distance_from_player:
			return candidate

		if distance_to_player > best_distance:
			best_distance = distance_to_player
			best_position = candidate

	return best_position


func _get_random_edge_position() -> Vector2:
	var left := arena_rect.position.x + spawn_edge_padding
	var right := arena_rect.end.x - spawn_edge_padding
	var top := arena_rect.position.y + spawn_edge_padding
	var bottom := arena_rect.end.y - spawn_edge_padding

	match _rng.randi_range(0, 3):
		0:
			return Vector2(_rng.randf_range(left, right), top)
		1:
			return Vector2(right, _rng.randf_range(top, bottom))
		2:
			return Vector2(_rng.randf_range(left, right), bottom)
		_:
			return Vector2(left, _rng.randf_range(top, bottom))


func _start_auto_fire() -> void:
	_auto_fire_timer = Timer.new()
	_auto_fire_timer.name = "AutoFireTimer"
	_auto_fire_timer.wait_time = auto_fire_interval
	_auto_fire_timer.autostart = true
	_auto_fire_timer.timeout.connect(_fire_at_nearest_enemy)
	add_child(_auto_fire_timer)


func _fire_at_nearest_enemy() -> void:
	if _is_restarting or _run_finished or _reward_open or not is_instance_valid(player):
		return

	if _is_chain_lightning_delivery():
		_cast_chain_lightning_spell()
		return
	if _is_area_delivery():
		_cast_area_spell()
		return
	if _is_slash_delivery():
		_cast_slash_spell()
		return
	if _is_persistent_waves_delivery():
		_cast_persistent_wave_spell()
		return

	_cast_projectile_spell()


func _cast_projectile_spell() -> void:
	var target := _get_nearest_enemy()
	if target == null:
		return

	var base_direction := player.global_position.direction_to(target.global_position)
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	var count := maxi(projectile_count, 1)
	var total_spread := deg_to_rad(projectile_spread_degrees) * float(count - 1)
	var start_angle := -total_spread * 0.5
	_shot_sequence += 1
	var catalyzed := _has_meta_skill("catalyzed_shot") and _shot_sequence % maxi(int(_get_meta_effect_value("catalyzed_shot_interval")), 1) == 0
	var projectile_overrides: Dictionary = {}
	var empowered_multiplier := _get_elemental_empowerment_multiplier()
	if catalyzed:
		projectile_overrides = {
			"damage": int(round(float(projectile_damage) * 1.8)),
			"size_multiplier": projectile_size_multiplier * 1.45,
			"visual_shape": "diamond",
			"fill_color": Color(1.0, 0.48, 0.9),
			"outline_color": Color(1.0, 0.94, 0.68),
		}
		_spawn_floating_text("CATALYZED", player.global_position + Vector2(0.0, -42.0), Color(1.0, 0.66, 0.94), 0.46)
	if empowered_multiplier > 1.0:
		projectile_overrides["damage"] = int(round(float(projectile_damage) * empowered_multiplier))
		_spawn_floating_text("STATIC", player.global_position + Vector2(0.0, -58.0), Color(1.0, 0.94, 0.42), 0.42)

	for index in range(count):
		var angle_offset := 0.0
		if count > 1:
			angle_offset = start_angle + deg_to_rad(projectile_spread_degrees) * float(index)

		var direction := base_direction.rotated(angle_offset)
		_spawn_projectile(player.global_position + direction * 30.0, direction, projectile_overrides)

	_play_audio("play_shoot")
	if _simple_projectile_echo_interval > 0 and _shot_sequence % _simple_projectile_echo_interval == 0:
		_spawn_projectile(player.global_position + base_direction * 26.0, base_direction.rotated(0.11), {"damage": int(round(float(projectile_damage) * 0.62)), "size_multiplier": projectile_size_multiplier * 0.7})
	if _cutting_echo_interval > 0 and _shot_sequence % _cutting_echo_interval == 0:
		_spawn_projectile(
			player.global_position + base_direction * 34.0,
			base_direction,
			{
				"damage": int(round(float(projectile_damage) * _cutting_echo_damage_multiplier)),
				"speed": projectile_speed * 1.08,
				"size_multiplier": projectile_size_multiplier * 0.92,
				"visual_shape": "diamond",
				"fill_color": Color(0.72, 1.0, 0.94),
				"outline_color": Color(1.0, 1.0, 1.0),
			}
		)


func _cast_chain_lightning_spell() -> void:
	var parameters := _get_chain_parameters()
	var visited: Array[Node2D] = []
	var first_target := _get_nearest_enemy_in_range(player.global_position, float(parameters["range"]), visited)
	if first_target == null:
		return

	_shot_sequence += 1
	var catalyzed := _has_meta_skill("catalyzed_shot") and _shot_sequence % maxi(int(_get_meta_effect_value("catalyzed_shot_interval")), 1) == 0
	var echo_cast := _cutting_echo_interval > 0 and _shot_sequence % _cutting_echo_interval == 0
	var empowered_multiplier := _get_elemental_empowerment_multiplier()
	var base_damage := maxi(1, int(round(float(projectile_damage) * float(parameters["damage_multiplier"]) * (1.8 if catalyzed else 1.0) * empowered_multiplier)))
	var memory_hit_bonus := 1 if _chain_memory_interval > 0 and _shot_sequence % _chain_memory_interval == 0 else 0
	var max_hits := mini(int(parameters["max_hits"]) + (1 if echo_cast else 0) + memory_hit_bonus, chain_max_hits_cap)
	if echo_cast:
		base_damage = maxi(1, int(round(float(base_damage) * _cutting_echo_damage_multiplier)))
	if catalyzed:
		_spawn_floating_text("CATALYZED", player.global_position + Vector2(0.0, -42.0), Color(1.0, 0.66, 0.94), 0.46)
	if echo_cast:
		_spawn_floating_text("ECHO", player.global_position + Vector2(0.0, -64.0), Color(0.72, 1.0, 0.94), 0.42)
	if empowered_multiplier > 1.0:
		_spawn_floating_text("STATIC", player.global_position + Vector2(0.0, -58.0), Color(1.0, 0.94, 0.42), 0.42)

	var chain_points: Array[Vector2] = [player.global_position]
	var current_target := first_target
	for hit_index in range(max_hits):
		if not is_instance_valid(current_target):
			break

		var target_position := current_target.global_position
		var hit_damage := maxi(1, int(round(float(base_damage) * pow(float(parameters["falloff"]), float(hit_index)))))
		chain_points.append(target_position)
		visited.append(current_target)
		_apply_chain_hit(current_target, hit_damage)

		if hit_index == 0 and projectile_explosion_radius > 0.0 and projectile_explosion_damage_multiplier > 0.0:
			_on_projectile_explosion_requested(target_position, projectile_explosion_radius, int(round(float(hit_damage) * projectile_explosion_damage_multiplier)))

		current_target = _get_nearest_enemy_in_range(target_position, float(parameters["jump_range"]), visited)

	_spawn_chain_lightning_effect(chain_points, float(parameters["visual_width"]))
	_play_chain_audio(chain_points.size() - 1)


func _is_chain_lightning_delivery() -> bool:
	return str(selected_spell_summary.get("delivery_id", "simple_projectile")) == "chain_lightning"


func _is_area_delivery() -> bool:
	return str(selected_spell_summary.get("delivery_id", "simple_projectile")) == "area"


func _is_slash_delivery() -> bool:
	return str(selected_spell_summary.get("delivery_id", "simple_projectile")) == "slash"


func _is_persistent_waves_delivery() -> bool:
	return str(selected_spell_summary.get("delivery_id", "simple_projectile")) == "persistent_waves"


func _is_simple_projectile_cast_type() -> bool:
	return str(selected_spell_summary.get("delivery_id", "simple_projectile")) == "simple_projectile"


func _get_elemental_empowerment_multiplier() -> float:
	if _electric_empowered_interval > 0 and _shot_sequence % _electric_empowered_interval == 0:
		return 1.25
	return 1.0


func _cast_slash_spell() -> void:
	var parameters: Dictionary = _get_slash_parameters()
	var target_count := int(parameters["targets"])
	var targets: Array[Node2D] = _get_closest_enemies_in_range(player.global_position, float(parameters["range"]), target_count)
	if targets.is_empty():
		return

	_shot_sequence += 1
	var catalyzed := _has_meta_skill("catalyzed_shot") and _shot_sequence % maxi(int(_get_meta_effect_value("catalyzed_shot_interval")), 1) == 0
	var echo_cast := _cutting_echo_interval > 0 and _shot_sequence % _cutting_echo_interval == 0
	var empowered_multiplier := _get_elemental_empowerment_multiplier()
	var rhythm_multiplier := 1.4 if _slash_empowered_interval > 0 and _shot_sequence % _slash_empowered_interval == 0 else 1.0
	var damage_multiplier := float(parameters["damage_multiplier"]) * (1.8 if catalyzed else 1.0) * empowered_multiplier * rhythm_multiplier
	var hit_damage := maxi(1, int(round(float(projectile_damage) * damage_multiplier)))
	var first_target_position: Vector2 = targets[0].global_position

	if catalyzed:
		_spawn_floating_text("CATALYZED", player.global_position + Vector2(0.0, -42.0), Color(1.0, 0.66, 0.94), 0.46)
	if empowered_multiplier > 1.0:
		_spawn_floating_text("STATIC", player.global_position + Vector2(0.0, -58.0), Color(1.0, 0.94, 0.42), 0.42)

	for target in targets:
		_apply_slash_hit(target, hit_damage, parameters, false)

	if projectile_explosion_radius > 0.0 and projectile_explosion_damage_multiplier > 0.0:
		_on_projectile_explosion_requested(
			first_target_position,
			projectile_explosion_radius * 0.78,
			maxi(1, int(round(float(hit_damage) * projectile_explosion_damage_multiplier * 0.7)))
		)

	if echo_cast:
		var echo_targets: Array[Node2D] = _get_closest_enemies_in_range(player.global_position, float(parameters["range"]), 1, targets)
		if not echo_targets.is_empty():
			_apply_slash_hit(echo_targets[0], maxi(1, int(round(float(hit_damage) * _cutting_echo_damage_multiplier))), parameters, true)
			_spawn_floating_text("ECHO", player.global_position + Vector2(0.0, -64.0), Color(0.72, 1.0, 0.94), 0.42)

	_play_audio("play_slash_cast")


func _get_slash_parameters() -> Dictionary:
	var size_multiplier := slash_size_multiplier * float(_spell_attributes.get("slash_size_multiplier", 1.0)) * _slash_size_multiplier
	return {
		"range": minf(slash_range * float(_spell_attributes.get("slash_range_multiplier", 1.0)) + _slash_range_bonus, slash_max_range),
		"damage_multiplier": slash_damage_multiplier * float(_spell_attributes.get("slash_damage_multiplier", 1.0)),
		"size_multiplier": clampf(size_multiplier, 0.5, slash_max_size_multiplier),
		"width": slash_width * float(_spell_attributes.get("slash_width_multiplier", 1.0)) * clampf(size_multiplier, 0.5, slash_max_size_multiplier),
		"targets": clampi(slash_targets + _slash_targets_bonus, 1, slash_max_targets),
		"arc_multiplier": float(_spell_attributes.get("slash_arc_multiplier", 1.0)),
	}


func _get_closest_enemies_in_range(origin: Vector2, max_range: float, count: int, excluded: Array[Node2D] = []) -> Array[Node2D]:
	var targets: Array[Node2D] = []
	var ignored: Array[Node2D] = []
	ignored.append_array(excluded)
	for _target_index in range(maxi(count, 0)):
		var target: Node2D = _get_nearest_enemy_in_range(origin, max_range, ignored)
		if target == null:
			break
		targets.append(target)
		ignored.append(target)

	return targets


func _apply_slash_hit(target: Node2D, damage: int, parameters: Dictionary, is_echo: bool) -> void:
	if not is_instance_valid(target):
		return

	var target_position: Vector2 = target.global_position
	if target.has_method("take_damage"):
		target.call("take_damage", damage)
	if target.has_method("apply_elemental_effect"):
		target.call(
			"apply_elemental_effect",
			str(_spell_attributes.get("element_effect_id", "direct")),
			float(_spell_attributes.get("element_effect_power", 0.0)),
			damage,
			_element_effect_duration_multiplier
		)

	_spawn_slash_effect(target_position, parameters, is_echo)
	var visual_profile: Dictionary = _get_spell_visual_profile()
	var impact_color: Color = visual_profile.get("impact_color", Color(0.74, 0.36, 1.0))
	_spawn_burst(target_position, impact_color, 9 if is_echo else 6)


func _spawn_slash_effect(target_position: Vector2, parameters: Dictionary, is_echo: bool) -> void:
	var visual_profile: Dictionary = _get_spell_visual_profile()
	var primary_color: Color = visual_profile.get("primary_color", Color(0.74, 0.36, 1.0))
	var secondary_color: Color = visual_profile.get("secondary_color", Color(1.0, 0.78, 1.0))
	if is_echo:
		secondary_color = secondary_color.lerp(Color.WHITE, 0.34)

	var effect := SLASH_EFFECT_SCENE.instantiate() as Node2D
	effect.call(
		"setup",
		player.global_position,
		target_position,
		72.0 * float(parameters["size_multiplier"]),
		float(parameters["width"]),
		str(_spell_attributes.get("visual_shape", "circle")),
		primary_color,
		secondary_color,
		slash_visual_duration,
		float(parameters["arc_multiplier"])
	)
	add_child(effect)


func _get_chain_parameters() -> Dictionary:
	var range_multiplier := float(_spell_attributes.get("chain_range_multiplier", 1.0)) * _chain_range_multiplier
	var jump_range_multiplier := float(_spell_attributes.get("chain_jump_range_multiplier", 1.0))
	var falloff_multiplier := float(_spell_attributes.get("chain_falloff_multiplier", 1.0))
	return {
		"range": minf((chain_range * range_multiplier) + _chain_range_bonus, 520.0),
		"jump_range": minf((chain_jump_range * jump_range_multiplier) + _chain_jump_range_bonus, chain_max_jump_range),
		"max_hits": mini(chain_max_hits + _chain_bonus_hits + int(_spell_attributes.get("chain_bonus_jumps", 0)), chain_max_hits_cap),
		"falloff": clampf(chain_damage_falloff * falloff_multiplier + _chain_falloff_bonus, 0.55, 0.9),
		"damage_multiplier": chain_base_damage_multiplier,
		"visual_width": 4.0 * float(_spell_attributes.get("chain_visual_width_multiplier", 1.0)),
	}


func _get_nearest_enemy_in_range(origin: Vector2, max_range: float, excluded: Array[Node2D]) -> Node2D:
	var nearest_enemy: Node2D = null
	var nearest_distance := max_range * max_range

	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or excluded.has(enemy):
			continue

		var distance := origin.distance_squared_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	return nearest_enemy


func _cast_persistent_wave_spell() -> void:
	var parameters: Dictionary = _get_persistent_wave_parameters()
	var target := _get_nearest_enemy_in_range(player.global_position, float(parameters["range"]), [])
	if target == null:
		return

	var direction := player.global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	_shot_sequence += 1
	var catalyzed := _has_meta_skill("catalyzed_shot") and _shot_sequence % maxi(int(_get_meta_effect_value("catalyzed_shot_interval")), 1) == 0
	var echo_cast := _cutting_echo_interval > 0 and _shot_sequence % _cutting_echo_interval == 0
	var empowered_multiplier := _get_elemental_empowerment_multiplier()
	var hit_damage := maxi(1, int(round(float(projectile_damage) * float(parameters["damage_multiplier"]) * (1.8 if catalyzed else 1.0) * empowered_multiplier)))
	if catalyzed:
		_spawn_floating_text("CATALYZED", player.global_position + Vector2(0.0, -42.0), Color(1.0, 0.66, 0.94), 0.46)
	if empowered_multiplier > 1.0:
		_spawn_floating_text("STATIC", player.global_position + Vector2(0.0, -58.0), Color(1.0, 0.94, 0.42), 0.42)

	_spawn_persistent_wave(player.global_position + direction * 32.0, direction, parameters, hit_damage)
	if echo_cast:
		var echo_parameters: Dictionary = parameters.duplicate(true)
		echo_parameters["width"] = float(echo_parameters["width"]) * 0.72
		echo_parameters["speed"] = float(echo_parameters["speed"]) * 0.9
		_spawn_persistent_wave(
			player.global_position + direction.rotated(0.14) * 28.0,
			direction.rotated(0.14),
			echo_parameters,
			maxi(1, int(round(float(hit_damage) * _cutting_echo_damage_multiplier)))
		)
		_spawn_floating_text("ECHO", player.global_position + Vector2(0.0, -64.0), Color(0.72, 1.0, 0.94), 0.42)

	_play_audio("play_wave_cast")


func _get_persistent_wave_parameters() -> Dictionary:
	var visual_profile: Dictionary = _get_spell_visual_profile()
	var shape_speed_multiplier := float(_spell_attributes.get("wave_speed_multiplier", 1.0))
	var shape_width_multiplier := float(_spell_attributes.get("wave_width_multiplier", 1.0))
	var shape_damage_multiplier := float(_spell_attributes.get("wave_damage_multiplier", 1.0))
	var shape_lifetime_multiplier := float(_spell_attributes.get("wave_lifetime_multiplier", 1.0))
	return {
		"range": wave_range,
		"speed": clampf((wave_speed + _wave_speed_bonus) * shape_speed_multiplier * _wave_speed_multiplier, 120.0, wave_max_speed),
		"lifetime": clampf(wave_lifetime * shape_lifetime_multiplier, 0.35, wave_max_lifetime),
		"damage_multiplier": wave_damage_multiplier * shape_damage_multiplier,
		"width": clampf(wave_width * shape_width_multiplier * _wave_width_multiplier, 26.0, wave_max_width),
		"length": clampf(wave_length * float(_spell_attributes.get("size_multiplier", 1.0)), 16.0, 68.0),
		"hit_cooldown": maxf(wave_hit_cooldown_per_enemy, wave_min_hit_cooldown_per_enemy),
		"visual_shape": str(_spell_attributes.get("visual_shape", "circle")),
		"fill_color": visual_profile.get("primary_color", Color(0.77, 0.36, 1.0)),
		"outline_color": visual_profile.get("secondary_color", Color(1.0, 0.78, 1.0)),
		"element_effect_id": str(_spell_attributes.get("element_effect_id", "direct")),
		"element_effect_power": float(_spell_attributes.get("element_effect_power", 0.0)),
	}


func _spawn_persistent_wave(spawn_position: Vector2, direction: Vector2, parameters: Dictionary, hit_damage: int) -> void:
	_remove_invalid_persistent_waves()
	var active_limit := clampi(max_active_waves, 1, wave_max_active)
	if _active_persistent_waves.size() >= active_limit:
		var oldest_wave: Node2D = _active_persistent_waves[0]
		_active_persistent_waves.remove_at(0)
		if is_instance_valid(oldest_wave):
			oldest_wave.queue_free()

	var wave := PERSISTENT_WAVE_SCENE.instantiate() as Node2D
	var wave_parameters: Dictionary = parameters.duplicate(true)
	wave_parameters["damage"] = hit_damage
	wave.connect("hit_requested", Callable(self, "_on_persistent_wave_hit"))
	add_child(wave)
	wave.call("setup", spawn_position, direction, wave_parameters)
	_active_persistent_waves.append(wave)


func _remove_invalid_persistent_waves() -> void:
	for index in range(_active_persistent_waves.size() - 1, -1, -1):
		if not is_instance_valid(_active_persistent_waves[index]):
			_active_persistent_waves.remove_at(index)


func _on_persistent_wave_hit(enemy: Node2D, damage: int, effect_id: String, effect_power: float, first_impact: bool) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy.has_method("take_damage"):
		enemy.call("take_damage", damage)
	if enemy.has_method("apply_elemental_effect") and effect_id != "direct":
		enemy.call("apply_elemental_effect", effect_id, effect_power, damage, _element_effect_duration_multiplier)

	var visual_profile: Dictionary = _get_spell_visual_profile()
	var impact_color: Color = visual_profile.get("impact_color", Color(0.96, 0.48, 1.0))
	_spawn_impact_ring(enemy.global_position, Color(impact_color.r, impact_color.g, impact_color.b, 0.58), 4.0, 22.0, 0.18, 1.6)
	if first_impact and projectile_explosion_radius > 0.0 and projectile_explosion_damage_multiplier > 0.0:
		_on_projectile_explosion_requested(
			enemy.global_position,
			projectile_explosion_radius * 0.58,
			maxi(1, int(round(float(damage) * projectile_explosion_damage_multiplier * 0.52)))
		)


func _cast_area_spell() -> void:
	var parameters := _get_area_parameters()
	var target := _get_nearest_enemy_in_range(player.global_position, float(parameters["range"]), [])
	if target == null:
		return

	_shot_sequence += 1
	var catalyzed := _has_meta_skill("catalyzed_shot") and _shot_sequence % maxi(int(_get_meta_effect_value("catalyzed_shot_interval")), 1) == 0
	var empowered_multiplier := _get_elemental_empowerment_multiplier()
	var tick_damage := maxi(1, int(round(float(projectile_damage) * float(parameters["damage_multiplier"]) * (1.8 if catalyzed else 1.0) * empowered_multiplier)))
	if catalyzed:
		_spawn_floating_text("CATALYZED", player.global_position + Vector2(0.0, -42.0), Color(1.0, 0.66, 0.94), 0.46)
	if empowered_multiplier > 1.0:
		_spawn_floating_text("STATIC", player.global_position + Vector2(0.0, -58.0), Color(1.0, 0.94, 0.42), 0.42)

	_remove_invalid_area_spells()
	if _active_area_spells.size() >= area_max_active:
		var oldest_area: Node2D = _active_area_spells[0]
		_active_area_spells.remove_at(0)
		if is_instance_valid(oldest_area):
			oldest_area.queue_free()

	var area_spell := AREA_SPELL_SCENE.instantiate() as Node2D
	add_child(area_spell)
	area_spell.connect("pulse_requested", Callable(self, "_on_area_spell_pulse"))
	area_spell.call(
		"setup",
		target.global_position,
		float(parameters["radius"]),
		float(parameters["duration"]),
		float(parameters["tick_interval"]),
		tick_damage,
		str(_spell_attributes.get("visual_shape", "circle")),
		_spell_attributes.get("fill_color", Color(0.74, 0.36, 1.0)),
		_spell_attributes.get("outline_color", Color(1.0, 0.78, 1.0)),
		str(_spell_attributes.get("element_effect_id", "direct")),
		float(_spell_attributes.get("element_effect_power", 0.0))
	)
	_active_area_spells.append(area_spell)
	_play_audio("play_area_cast")
	if _area_initial_pulse_multiplier > 0.0:
		_on_area_spell_pulse(target.global_position, float(parameters["radius"]) * 0.58, maxi(1, int(round(float(tick_damage) * _area_initial_pulse_multiplier))), str(_spell_attributes.get("element_effect_id", "direct")), float(_spell_attributes.get("element_effect_power", 0.0)))

	if projectile_explosion_radius > 0.0 and projectile_explosion_damage_multiplier > 0.0:
		_on_area_spell_pulse(
			target.global_position,
			float(parameters["radius"]) * 0.52,
			maxi(1, int(round(float(tick_damage) * 0.65))),
			str(_spell_attributes.get("element_effect_id", "direct")),
			float(_spell_attributes.get("element_effect_power", 0.0))
		)


func _get_area_parameters() -> Dictionary:
	var size_multiplier := float(_spell_attributes.get("area_size_multiplier", 1.0)) * _area_size_multiplier
	return {
		"range": minf(area_range + _area_range_bonus, 540.0),
		"radius": area_radius * clampf(size_multiplier, 0.5, area_max_size_multiplier),
		"duration": minf(area_duration * float(_spell_attributes.get("area_duration_multiplier", 1.0)) * _area_duration_multiplier, area_max_duration),
		"tick_interval": maxf(area_tick_interval * float(_spell_attributes.get("area_tick_interval_multiplier", 1.0)), area_min_tick_interval),
		"damage_multiplier": area_tick_damage_multiplier * float(_spell_attributes.get("area_damage_multiplier", 1.0)) * _area_damage_multiplier,
	}


func _on_area_spell_pulse(world_position: Vector2, pulse_radius: float, damage: int, effect_id: String, effect_power: float) -> void:
	var enemies_hit := 0
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or enemy.global_position.distance_to(world_position) > pulse_radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.call("take_damage", damage)
		if enemy.has_method("apply_elemental_effect") and effect_id != "direct":
			enemy.call("apply_elemental_effect", effect_id, effect_power, damage, _element_effect_duration_multiplier)
		enemies_hit += 1

	if enemies_hit > 0:
		var visual_profile := _get_spell_visual_profile()
		var impact_color: Color = visual_profile.get("impact_color", Color(0.74, 0.36, 1.0))
		_spawn_impact_ring(world_position, Color(impact_color.r, impact_color.g, impact_color.b, 0.35), pulse_radius * 0.28, pulse_radius * 0.52, 0.24, 1.6)


func _remove_invalid_area_spells() -> void:
	for index in range(_active_area_spells.size() - 1, -1, -1):
		if not is_instance_valid(_active_area_spells[index]):
			_active_area_spells.remove_at(index)


func _apply_chain_hit(enemy: Node2D, damage: int) -> void:
	if enemy.has_method("take_damage"):
		enemy.call("take_damage", damage)
	if enemy.has_method("apply_elemental_effect"):
		enemy.call(
			"apply_elemental_effect",
			str(_spell_attributes.get("element_effect_id", "direct")),
			float(_spell_attributes.get("element_effect_power", 0.0)),
			damage,
			_element_effect_duration_multiplier
		)


func _spawn_chain_lightning_effect(chain_points: Array[Vector2], visual_width: float) -> void:
	if chain_points.size() < 2:
		return

	var visual_profile := _get_spell_visual_profile()
	var effect := CHAIN_LIGHTNING_EFFECT_SCENE.instantiate() as Node2D
	add_child(effect)
	effect.call(
		"setup",
		chain_points,
		visual_profile.get("primary_color", Color(0.4, 0.9, 1.0)),
		visual_profile.get("secondary_color", Color(0.9, 0.98, 1.0)),
		visual_width,
		chain_visual_duration
	)


func _play_chain_audio(hit_count: int) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_chain_cast"):
		audio_manager.call("play_chain_cast", hit_count)


func _spawn_projectile(spawn_position: Vector2, direction: Vector2, overrides: Dictionary = {}) -> void:
	var projectile := BASIC_PROJECTILE_SCENE.instantiate() as Area2D
	var actual_damage := int(overrides.get("damage", projectile_damage))
	projectile.set("damage", actual_damage)
	projectile.set("speed", float(overrides.get("speed", projectile_speed)))
	var opening_pierce := 1 if _opening_charge_time_left > 0.0 else 0
	projectile.set("pierce_left", projectile_pierce + opening_pierce)
	projectile.set("bounce_left", projectile_bounce)
	projectile.set("arena_rect", arena_rect)
	projectile.set("explosion_radius", projectile_explosion_radius)
	projectile.set("explosion_damage", int(round(float(actual_damage) * projectile_explosion_damage_multiplier)))
	projectile.set("size_multiplier", float(overrides.get("size_multiplier", projectile_size_multiplier)))
	projectile.set("lifetime", float(projectile.get("lifetime")) * float(_spell_attributes.get("duration_multiplier", 1.0)))
	projectile.set("visual_shape", str(overrides.get("visual_shape", _spell_attributes.get("visual_shape", "circle"))))
	projectile.set("element_effect_id", str(_spell_attributes.get("element_effect_id", "direct")))
	projectile.set("element_effect_power", float(_spell_attributes.get("element_effect_power", 0.0)))
	projectile.set("element_effect_duration_multiplier", _element_effect_duration_multiplier)
	var visual_profile := _get_spell_visual_profile()
	projectile.set("trail_style", str(visual_profile.get("trail_style", "standard")))
	projectile.set("glow_strength", float(visual_profile.get("glow", 0.0)))
	var projectile_colors := _get_projectile_visual_colors(overrides, opening_pierce > 0)
	projectile.set("fill_color", projectile_colors["fill_color"])
	projectile.set("outline_color", projectile_colors["outline_color"])
	projectile.connect("explosion_requested", Callable(self, "_on_projectile_explosion_requested"))
	projectile.connect("bounce_requested", Callable(self, "_on_projectile_bounce_requested"))
	add_child(projectile)
	projectile.call("setup", spawn_position, spawn_position + direction * 100.0)


func _get_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D = null
	var nearest_distance := INF

	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue

		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	return nearest_enemy


func _on_enemy_died(enemy: Node) -> void:
	var death_position := Vector2.ZERO
	if enemy is Node2D:
		var enemy_node := enemy as Node2D
		death_position = enemy_node.global_position

	_spawn_enemy_death_effect(enemy, death_position)
	_play_audio("play_enemy_death")
	enemies.erase(enemy)
	_record_enemy_defeated(enemy)
	score += _get_score_value_for_enemy(enemy)
	_update_hud()

	if current_wave_type == "boss" and _get_enemy_id(enemy) == "hexagon_boss":
		_finish_run(true, 1.15)
		return

	if _wave_in_progress and enemies.is_empty() and not _is_restarting and not _run_finished:
		_complete_wave()


func _get_score_value_for_enemy(enemy: Node) -> int:
	var enemy_score = enemy.get("score_value")
	if enemy_score == null:
		return fallback_enemy_score_value

	return int(enemy_score)


func _complete_wave() -> void:
	_wave_in_progress = false

	if current_wave_type == "boss":
		_finish_run(true)
		return

	_reward_open = true
	_clear_projectiles()
	_clear_area_spells()

	if is_instance_valid(_auto_fire_timer):
		_auto_fire_timer.stop()

	if current_wave_type == "mini_boss":
		_apply_miniboss_repair_bonus()
		hud.call("set_wave_message", "Mini-Boss defeated")
	else:
		hud.call("set_wave_message", "Wave complete")

	_play_audio("play_wave_complete")
	_show_upgrade_reward()


func _start_next_wave() -> void:
	_start_wave(current_wave + 1)


func _show_upgrade_reward() -> void:
	if not is_instance_valid(upgrade_panel):
		_start_next_wave()
		return

	upgrade_panel.call("show_upgrades", _pick_upgrade_options(_get_upgrade_option_count()), _rerolls_left)
	_has_shown_upgrade_panel = true


func _pick_upgrade_options(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = _filter_delivery_compatible_upgrades(_available_upgrades)
	var picked: Array[Dictionary] = []

	_pick_directed_affinity_option(pool, picked, count)
	_pick_priority_meta_upgrades(pool, picked, count)
	_pick_synergy_option(pool, picked, count)

	while picked.size() < count and not pool.is_empty():
		var index := _rng.randi_range(0, pool.size() - 1)
		var upgrade: Dictionary = pool[index].duplicate(true)
		_prepare_upgrade_option(upgrade)
		picked.append(upgrade)
		pool.remove_at(index)

	return picked


func _pick_directed_affinity_option(pool: Array[Dictionary], picked: Array[Dictionary], count: int) -> void:
	if _has_shown_upgrade_panel or not _has_meta_skill("directed_tuning") or picked.size() >= count:
		return

	for index in range(pool.size()):
		var candidate: Dictionary = pool[index]
		var category := str(candidate.get("category", ""))
		if category not in ["power", "projectile"]:
			continue
		var upgrade: Dictionary = candidate.duplicate(true)
		_prepare_upgrade_option(upgrade)
		picked.append(upgrade)
		pool.remove_at(index)
		return


func _pick_synergy_option(pool: Array[Dictionary], picked: Array[Dictionary], count: int) -> void:
	if not _has_meta_skill("synergy_resonance") or picked.size() >= count or _rng.randf() > 0.7:
		return

	var complementary_upgrade := ""
	if _has_upgrade("initial_fragmentation") and not _has_upgrade("arcane_explosion"):
		complementary_upgrade = "arcane_explosion"
	elif _has_upgrade("ricochet") and not _has_upgrade("piercing"):
		complementary_upgrade = "piercing"
	elif _has_upgrade("unstable_field") and not _has_upgrade("energy_shell"):
		complementary_upgrade = "energy_shell"

	if complementary_upgrade.is_empty():
		return

	for index in range(pool.size()):
		var candidate: Dictionary = pool[index]
		if str(candidate.get("id", "")) != complementary_upgrade:
			continue
		var upgrade: Dictionary = candidate.duplicate(true)
		_prepare_upgrade_option(upgrade)
		picked.append(upgrade)
		pool.remove_at(index)
		return


func _pick_priority_meta_upgrades(pool: Array[Dictionary], picked: Array[Dictionary], count: int) -> void:
	var priority_indices: Array[int] = []

	for index in range(pool.size()):
		var candidate: Dictionary = pool[index]
		var upgrade_id := str(candidate.get("id", ""))
		var unlock_id := str(candidate.get("unlock_id", ""))
		if unlock_id.is_empty() or int(upgrade_stacks.get(upgrade_id, 0)) > 0:
			continue

		var upgrade: Dictionary = candidate.duplicate(true)
		_prepare_upgrade_option(upgrade)
		picked.append(upgrade)
		priority_indices.append(index)
		if picked.size() >= count:
			break

	for index in range(priority_indices.size() - 1, -1, -1):
		pool.remove_at(priority_indices[index])


func _prepare_upgrade_option(upgrade: Dictionary) -> void:
	var upgrade_id := str(upgrade.get("id", ""))
	upgrade["current_stack"] = int(upgrade_stacks.get(upgrade_id, 0))
	var delivery_effects = upgrade.get("delivery_effects", {})
	if delivery_effects is Dictionary and delivery_effects.has(str(selected_spell_summary.get("delivery_id", "simple_projectile"))):
		var effect_data = delivery_effects[str(selected_spell_summary.get("delivery_id", "simple_projectile"))]
		if effect_data is Dictionary:
			for key in ["name", "description", "impact_text"]:
				if effect_data.has(key):
					upgrade[key] = effect_data[key]


func _on_upgrade_selected(upgrade: Dictionary) -> void:
	_add_spell_node_from_upgrade(upgrade)
	_apply_upgrade(upgrade)
	run_stats["upgrades_chosen"] = int(run_stats.get("upgrades_chosen", 0)) + 1
	_spawn_floating_text("NODE +1", arena_rect.position + Vector2(arena_rect.size.x * 0.5, arena_rect.size.y - 92.0), Color(0.72, 0.96, 1.0), 0.8)
	_reward_open = false
	hud.call("set_wave_message", "Next wave...")
	get_tree().create_timer(wave_interval).timeout.connect(_start_next_wave)


func _on_upgrade_reroll_requested() -> void:
	if not _reward_open or _rerolls_left <= 0:
		return

	_rerolls_left -= 1
	_update_meta_hud()
	upgrade_panel.call("show_upgrades", _pick_upgrade_options(_get_upgrade_option_count()), _rerolls_left)


func _apply_upgrade(upgrade: Dictionary) -> void:
	var upgrade_id := str(upgrade.get("id", ""))
	var values = upgrade.get("values", {})

	match upgrade_id:
		"arcane_damage":
			projectile_damage += int(values.get("damage_bonus", 4))
		"unstable_cadence":
			var minimum_interval := min_auto_fire_interval
			if _is_chain_lightning_delivery():
				minimum_interval = chain_min_cast_interval
			elif _is_area_delivery():
				minimum_interval = area_min_cast_interval
			elif _is_slash_delivery():
				minimum_interval = slash_min_cast_interval
			elif _is_persistent_waves_delivery():
				minimum_interval = wave_min_cast_interval
			auto_fire_interval = maxf(auto_fire_interval * float(values.get("interval_multiplier", 0.88)), minimum_interval)
			if is_instance_valid(_auto_fire_timer):
				_auto_fire_timer.wait_time = auto_fire_interval
		"light_core":
			if is_instance_valid(player):
				var current_speed = player.get("speed")
				if current_speed != null:
					player.set("speed", float(current_speed) + float(values.get("speed_bonus", 35.0)))
		"energy_shell":
			if is_instance_valid(player) and player.has_method("increase_max_health"):
				player.call("increase_max_health", int(values.get("max_health_bonus", 20)), int(values.get("heal_amount", 12)))
		"swift_projectile":
			projectile_speed += float(values.get("projectile_speed_bonus", 80.0))
			if _is_chain_lightning_delivery():
				_chain_range_bonus += 52.0
				_chain_jump_range_bonus += 24.0
			elif _is_area_delivery():
				_area_range_bonus += 56.0
			elif _is_slash_delivery():
				_slash_range_bonus = minf(_slash_range_bonus + 48.0, slash_max_range - slash_range * 0.5)
			elif _is_persistent_waves_delivery():
				_wave_speed_bonus += float(values.get("projectile_speed_bonus", 80.0))
		"initial_fragmentation":
			if _is_chain_lightning_delivery():
				_chain_bonus_hits = mini(_chain_bonus_hits + int(values.get("projectile_count_bonus", 1)), chain_max_hits_cap - chain_max_hits)
			elif _is_area_delivery():
				_area_size_multiplier = minf(_area_size_multiplier * 1.18, area_max_size_multiplier)
			elif _is_slash_delivery():
				var slash_target_bonus_cap := maxi(slash_max_targets - slash_targets, 0)
				_slash_targets_bonus = mini(_slash_targets_bonus + int(values.get("projectile_count_bonus", 1)), slash_target_bonus_cap)
			elif _is_persistent_waves_delivery():
				_wave_width_multiplier *= 1.18
			else:
				projectile_count = mini(projectile_count + int(values.get("projectile_count_bonus", 1)), max_projectile_count)
		"piercing":
			if _is_chain_lightning_delivery():
				_chain_falloff_bonus = minf(_chain_falloff_bonus + 0.05 * float(values.get("pierce_bonus", 1)), 0.25)
			else:
				projectile_pierce += int(values.get("pierce_bonus", 1))
		"ricochet":
			projectile_bounce += int(values.get("bounce_bonus", 1))
		"arcane_explosion":
			projectile_explosion_radius += float(values.get("radius_bonus", 60.0))
			projectile_explosion_damage_multiplier += float(values.get("damage_multiplier_bonus", 0.5))
		"heavy_orb":
			projectile_damage = int(round(float(projectile_damage) * float(values.get("damage_multiplier", 1.4))))
			projectile_speed *= float(values.get("speed_multiplier", 0.85))
			projectile_size_multiplier += float(values.get("size_bonus", 0.2))
			if _is_chain_lightning_delivery():
				_chain_range_multiplier *= 0.88
			elif _is_area_delivery():
				_area_size_multiplier = minf(_area_size_multiplier * 1.2, area_max_size_multiplier)
				_area_duration_multiplier = maxf(_area_duration_multiplier * 0.9, 0.55)
			elif _is_slash_delivery():
				_slash_size_multiplier = minf(_slash_size_multiplier * 1.2, slash_max_size_multiplier)
				auto_fire_interval *= 1.1
				if is_instance_valid(_auto_fire_timer):
					_auto_fire_timer.wait_time = auto_fire_interval
			elif _is_persistent_waves_delivery():
				_wave_width_multiplier *= 1.2
				_wave_speed_multiplier *= float(values.get("speed_multiplier", 0.85))
				auto_fire_interval *= 1.1
				if is_instance_valid(_auto_fire_timer):
					_auto_fire_timer.wait_time = auto_fire_interval
		"cutting_echo":
			_cutting_echo_interval = int(values.get("shot_interval", 4))
			_cutting_echo_damage_multiplier += float(values.get("damage_multiplier_bonus", 0.25))
		"unstable_field":
			_unstable_field_enabled = true
			_unstable_field_radius += float(values.get("radius_bonus", 60.0))
			_unstable_field_damage += int(values.get("damage_bonus", 6))
			_unstable_field_interval = float(values.get("pulse_interval", 0.5))
			_ensure_unstable_field_aura()

	_update_active_synergies()


func _add_spell_node_from_upgrade(upgrade: Dictionary) -> void:
	var upgrade_id := str(upgrade.get("id", ""))
	upgrade_stacks[upgrade_id] = int(upgrade_stacks.get(upgrade_id, 0)) + 1
	if spell_graph != null:
		spell_graph.add_upgrade(upgrade, int(upgrade_stacks.get(upgrade_id, 1)))
		_refresh_spell_graph_panel()


func _refresh_spell_graph_panel() -> void:
	if spell_graph == null:
		return

	var branch_nodes: Dictionary = spell_graph.get_branch_nodes()
	var synergies: Array = spell_graph.get_synergies()
	if is_instance_valid(spell_graph_overlay):
		spell_graph_overlay.call("set_graph_data", branch_nodes, synergies, selected_spell_summary)
	if is_instance_valid(hud):
		var node_count: int = spell_graph.get_ordered_nodes().size()
		hud.call("set_build_summary", node_count, synergies.size())


func _toggle_spell_graph() -> void:
	if _graph_open:
		_close_spell_graph()
		return

	if _run_finished or _reward_open or not is_instance_valid(spell_graph_overlay) or spell_graph == null:
		return

	_graph_open = true
	spell_graph_overlay.call("open_graph", spell_graph.get_branch_nodes(), spell_graph.get_synergies(), selected_spell_summary)
	get_tree().paused = true


func _close_spell_graph() -> void:
	if not _graph_open:
		return

	_graph_open = false
	if is_instance_valid(spell_graph_overlay):
		spell_graph_overlay.call("close_graph")
	get_tree().paused = false


func _open_pause_menu() -> void:
	if _pause_open or _run_finished or _reward_open or not is_instance_valid(pause_menu):
		return

	_pause_open = true
	pause_menu.call("open_menu")
	get_tree().paused = true


func _close_pause_menu() -> void:
	if not _pause_open:
		return

	_pause_open = false
	get_tree().paused = false
	if is_instance_valid(pause_menu):
		pause_menu.call("close_menu")


func _create_upgrade_data() -> Array[Dictionary]:
	return [
		{
			"id": "arcane_damage",
			"name": "Arcane Damage",
			"description": "+5 projectile damage.",
			"category": "power",
			"branch": "energy",
			"effect_type": "projectile_damage",
			"node_label": "Damage",
			"values": {
				"damage_bonus": 5,
			},
			"delivery_effects": {
				"chain_lightning": {
					"description": "+5 base damage per Chain Lightning target.",
					"impact_text": "+5 damage per target",
				},
				"area": {
					"description": "+5 damage per Area Field pulse.",
					"impact_text": "+5 damage per pulse",
				},
				"slash": {
					"description": "+5 damage per cut.",
					"impact_text": "+5 damage per cut",
				},
				"persistent_waves": {
					"description": "+5 damage per Persistent Wave hit.",
					"impact_text": "+5 Wave damage",
				},
			},
		},
		{
			"id": "unstable_cadence",
			"name": "Unstable Cadence",
			"description": "Automatic casts are 16% faster.",
			"category": "rhythm",
			"branch": "rhythm",
			"effect_type": "fire_interval",
			"node_label": "Cadence",
			"values": {
				"interval_multiplier": 0.84,
			},
			"delivery_effects": {
				"chain_lightning": {
					"description": "Chain Lightning casts are 16% faster, respecting the minimum interval.",
					"impact_text": "-16% Chain interval",
				},
				"area": {
					"description": "Area Fields cast 16% faster, respecting the minimum interval.",
					"impact_text": "-16% Area interval",
				},
				"slash": {
					"description": "Slashes execute 16% faster, respecting the minimum interval.",
					"impact_text": "-16% Slash interval",
				},
				"persistent_waves": {
					"description": "Persistent Waves cast 16% faster, respecting the minimum interval.",
					"impact_text": "-16% Wave interval",
				},
			},
		},
		{
			"id": "light_core",
			"name": "Light Core",
			"description": "+35 movement speed.",
			"category": "body",
			"branch": "core",
			"effect_type": "player_speed",
			"node_label": "Core",
			"values": {
				"speed_bonus": 35.0,
			},
		},
		{
			"id": "energy_shell",
			"name": "Energy Shell",
			"description": "+22 maximum health and heal 16.",
			"category": "body",
			"branch": "core",
			"effect_type": "player_health",
			"node_label": "Shell",
			"values": {
				"max_health_bonus": 22,
				"heal_amount": 16,
			},
		},
		{
			"id": "swift_projectile",
			"name": "Swift Projectile",
			"description": "+80 projectile speed.",
			"category": "projectile",
			"branch": "form",
			"effect_type": "projectile_speed",
			"node_label": "Speed",
			"values": {
				"projectile_speed_bonus": 80.0,
			},
			"delivery_effects": {
				"chain_lightning": {
					"name": "Swift Conductor",
					"description": "Increases Chain Lightning initial range and jump range.",
					"impact_text": "+52 range, +24 jump",
				},
				"area": {
					"name": "Expanded Range",
					"description": "Lets you create Area Fields farther from the core.",
					"impact_text": "+56 Area range",
				},
				"slash": {
					"name": "Extended Cut",
					"description": "Increases Slash targeting range.",
					"impact_text": "+48 Slash range",
				},
				"persistent_waves": {
					"name": "Swift Wave",
					"description": "Increases Persistent Wave travel speed.",
					"impact_text": "+80 Wave speed",
				},
			},
		},
		{
			"id": "initial_fragmentation",
			"name": "Initial Fragmentation",
			"description": "+1 projectile per cast in a spread.",
			"category": "projectile",
			"branch": "form",
			"effect_type": "projectile_count",
			"node_label": "Fragment",
			"values": {
				"projectile_count_bonus": 1,
			},
			"max_stacks_by_delivery": {"chain_lightning": 2, "area": 3, "slash": 3, "persistent_waves": 3},
			"delivery_effects": {
				"chain_lightning": {
					"name": "Chain Fragmentation",
					"description": "Hits +1 total target per chain. 2 stack limit.",
					"impact_text": "+1 maximum target",
				},
				"area": {
					"name": "Fragmented Field",
					"description": "Increases Area Field size. 3 stack limit.",
					"impact_text": "+18% Area size",
				},
				"slash": {
					"name": "Fragmented Cuts",
					"description": "Hits +1 nearby target per Slash. 3 stack limit.",
					"impact_text": "+1 target per cut",
				},
				"persistent_waves": {
					"name": "Expanded Crest",
					"description": "Increases Persistent Wave width. 3 stack limit.",
					"impact_text": "+18% Wave width",
				},
			},
		},
		{
			"id": "piercing",
			"name": "Piercing",
			"description": "Projectiles pass through +1 enemy.",
			"category": "projectile",
			"branch": "form",
			"effect_type": "projectile_pierce",
			"node_label": "Pierce",
			"unlock_id": "upgrade_piercing",
			"values": {
				"pierce_bonus": 1,
			},
			"max_stacks_by_delivery": {"chain_lightning": 3},
			"compatible_deliveries": ["simple_projectile", "chain_lightning"],
			"delivery_effects": {
				"chain_lightning": {
					"name": "Piercing Conductor",
					"description": "Each jump retains more damage. 3 stack limit.",
					"impact_text": "+5% damage retained per jump",
				},
			},
		},
		{
			"id": "ricochet",
			"name": "Ricochet",
			"description": "Projectiles ricochet +1 time from arena edges.",
			"category": "projectile",
			"branch": "form",
			"effect_type": "projectile_bounce",
			"node_label": "Ricochet",
			"values": {
				"bounce_bonus": 1,
			},
			"compatible_deliveries": ["simple_projectile"],
		},
		{
			"id": "arcane_explosion",
			"name": "Arcane Explosion",
			"description": "Impacts deal area damage.",
			"category": "power",
			"branch": "energy",
			"effect_type": "area_explosion",
			"node_label": "Explode",
			"values": {
				"radius_bonus": 60.0,
				"damage_multiplier_bonus": 0.5,
			},
			"delivery_effects": {
				"chain_lightning": {
					"description": "Only the first Chain Lightning target creates an arcane explosion.",
					"impact_text": "Explosion on first target",
				},
				"area": {
					"description": "Creating an Area Field causes a reduced initial arcane impact.",
					"impact_text": "Initial Area impact",
				},
				"slash": {
					"description": "The first cut creates a reduced arcane explosion.",
					"impact_text": "Explosion on first cut",
				},
				"persistent_waves": {
					"description": "The first enemy hit by each wave creates a reduced arcane explosion.",
					"impact_text": "Explosion on first Wave hit",
				},
			},
		},
		{
			"id": "heavy_orb",
			"name": "Heavy Orb",
			"description": "+40% damage, -15% speed, larger projectile.",
			"category": "projectile",
			"branch": "form",
			"effect_type": "heavy_projectile",
			"node_label": "Orb",
			"values": {
				"damage_multiplier": 1.4,
				"speed_multiplier": 0.85,
				"size_bonus": 0.2,
			},
			"max_stacks_by_delivery": {"chain_lightning": 2, "area": 2, "slash": 2, "persistent_waves": 2},
			"delivery_effects": {
				"chain_lightning": {
					"name": "Heavy Discharge",
					"description": "+40% Chain Lightning damage with -12% initial range.",
					"impact_text": "+40% damage, -12% range",
				},
				"area": {
					"name": "Dense Field",
					"description": "+40% damage, larger Area Field, and slightly shorter duration.",
					"impact_text": "+40% damage, +20% size",
				},
				"slash": {
					"name": "Heavy Cut",
					"description": "+40% damage and a larger cut with slower cadence.",
					"impact_text": "+40% damage, +20% size",
				},
				"persistent_waves": {
					"name": "Heavy Wave",
					"description": "+40% damage, wider Persistent Waves, slower travel and cadence.",
					"impact_text": "+40% damage, +20% width",
				},
			},
		},
		{
			"id": "cutting_echo",
			"name": "Cutting Echo",
			"description": "Every 4 casts, launches an extra strong projectile.",
			"category": "rhythm",
			"branch": "rhythm",
			"effect_type": "special_projectile",
			"node_label": "Echo",
			"values": {
				"shot_interval": 4,
				"damage_multiplier_bonus": 0.25,
			},
			"max_stacks_by_delivery": {"chain_lightning": 2, "slash": 2, "persistent_waves": 2},
			"compatible_deliveries": ["simple_projectile", "chain_lightning", "slash", "persistent_waves"],
			"delivery_effects": {
				"chain_lightning": {
					"name": "Resonant Echo",
					"description": "Every 4 chains, the next gains extra damage and +1 target.",
					"impact_text": "Echo: extra damage and +1 target",
				},
				"slash": {
					"name": "Cutting Echo",
					"description": "Every 4 Slashes, performs an extra strong cut on another nearby target.",
					"impact_text": "Echo: extra strong cut",
				},
				"persistent_waves": {
					"name": "Wave Echo",
					"description": "Every 4 casts, launches a smaller extra wave at a slight angle.",
					"impact_text": "Echo: extra Wave",
				},
			},
		},
		{
			"id": "unstable_field",
			"name": "Unstable Field",
			"description": "A weak aura deals periodic damage to nearby enemies.",
			"category": "area",
			"branch": "core",
			"effect_type": "player_aura",
			"node_label": "Field",
			"values": {
				"radius_bonus": 60.0,
				"damage_bonus": 6,
				"pulse_interval": 0.5,
			},
		},
	]


func _filter_unlocked_upgrades(upgrades: Array[Dictionary]) -> Array[Dictionary]:
	var save_manager := get_node_or_null("/root/SaveManager")
	var filtered: Array[Dictionary] = []

	for upgrade in upgrades:
		var upgrade_id := str(upgrade.get("id", ""))
		var unlock_id := str(upgrade.get("unlock_id", ""))
		if unlock_id.is_empty():
			filtered.append(upgrade)
		elif save_manager != null and (
			bool(save_manager.call("is_unlocked", unlock_id))
			or bool(save_manager.call("is_upgrade_unlocked", upgrade_id))
		):
			filtered.append(upgrade)

	return filtered


func _filter_delivery_compatible_upgrades(upgrades: Array[Dictionary]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []

	for upgrade in upgrades:
		if _is_upgrade_compatible_with_current_delivery(upgrade):
			filtered.append(upgrade.duplicate(true))

	return filtered


func _is_upgrade_compatible_with_current_delivery(upgrade: Dictionary) -> bool:
	var delivery_id := str(selected_spell_summary.get("delivery_id", "simple_projectile"))
	var compatible_deliveries = upgrade.get("compatible_deliveries", [])
	if compatible_deliveries is Array and not compatible_deliveries.is_empty() and not compatible_deliveries.has(delivery_id):
		return false

	var upgrade_id := str(upgrade.get("id", ""))
	var stack_caps = upgrade.get("max_stacks_by_delivery", {})
	if stack_caps is Dictionary and stack_caps.has(delivery_id):
		return int(upgrade_stacks.get(upgrade_id, 0)) < int(stack_caps[delivery_id])

	return true


func _on_projectile_explosion_requested(world_position: Vector2, radius: float, damage: int) -> void:
	if radius <= 0.0 or damage <= 0:
		return

	_play_audio("play_explosion")
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(world_position) > radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.call("take_damage", damage)

	var visual_profile := _get_spell_visual_profile()
	var impact_color: Color = visual_profile.get("impact_color", Color(1.0, 0.58, 0.22))
	_spawn_burst(world_position, impact_color, 18)
	_spawn_impact_ring(world_position, Color(impact_color.r, impact_color.g, impact_color.b, 0.88), radius * 0.22, radius, 0.42, 3.6)
	_spawn_floating_text("BOOM", world_position + Vector2(0.0, -18.0), Color(1.0, 0.78, 1.0), 0.55)


func _on_projectile_bounce_requested(world_position: Vector2) -> void:
	var visual_profile := _get_spell_visual_profile()
	var bounce_color: Color = visual_profile.get("bounce_color", Color(0.58, 0.9, 1.0))
	_spawn_burst(world_position, bounce_color, 7 if _has_upgrade("piercing") else 5)
	_spawn_impact_ring(world_position, Color(bounce_color.r, bounce_color.g, bounce_color.b, 0.72), 5.0, 32.0 if _has_upgrade("piercing") else 26.0, 0.22, 2.0)


func _update_unstable_field(delta: float) -> void:
	if not _unstable_field_enabled or not is_instance_valid(player):
		return

	_unstable_field_time_left = maxf(_unstable_field_time_left - delta, 0.0)
	if _unstable_field_time_left > 0.0:
		return

	_unstable_field_time_left = _unstable_field_interval
	var pulse_radius := _get_effective_unstable_field_radius()
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(player.global_position) > pulse_radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.call("take_damage", _unstable_field_damage)

	var visual_profile := _get_spell_visual_profile()
	var aura_color: Color = visual_profile.get("aura_color", Color(0.36, 0.95, 1.0))
	_spawn_burst(player.global_position, aura_color, 8)
	_spawn_impact_ring(player.global_position, Color(aura_color.r, aura_color.g, aura_color.b, 0.42), pulse_radius * 0.35, pulse_radius, 0.36, 2.0)


func _ensure_unstable_field_aura() -> void:
	if not is_instance_valid(player):
		return

	if not is_instance_valid(_unstable_field_aura):
		_unstable_field_aura = Node2D.new()
		_unstable_field_aura.name = "UnstableFieldAura"
		_unstable_field_aura.set_script(UNSTABLE_FIELD_AURA_SCRIPT)
		player.add_child(_unstable_field_aura)

	_unstable_field_aura.set("radius", _get_effective_unstable_field_radius())
	var visual_profile := _get_spell_visual_profile()
	var aura_color: Color = visual_profile.get("aura_color", Color(0.42, 0.95, 1.0))
	_unstable_field_aura.set("color", Color(aura_color.r, aura_color.g, aura_color.b, 0.28))


func _get_effective_unstable_field_radius() -> float:
	var radius := _unstable_field_radius
	if _has_upgrade("unstable_field") and _has_upgrade("energy_shell"):
		radius += 18.0
	return radius


func _update_active_synergies() -> void:
	active_synergies.clear()

	if _has_upgrade("initial_fragmentation") and _has_upgrade("arcane_explosion"):
		active_synergies.append("Explosive Fragmentation")
	if _has_upgrade("ricochet") and _has_upgrade("piercing"):
		active_synergies.append("Bouncing Pierce")
	if _has_upgrade("unstable_field") and _has_upgrade("energy_shell"):
		active_synergies.append("Shielded Field")
		_ensure_unstable_field_aura()

	if spell_graph != null:
		spell_graph.set_synergies(active_synergies)
		_refresh_spell_graph_panel()


func _has_upgrade(upgrade_id: String) -> bool:
	return int(upgrade_stacks.get(upgrade_id, 0)) > 0


func _update_hud() -> void:
	if is_instance_valid(hud):
		hud.call("set_wave_info", current_wave, _get_alive_enemy_count(), score, max_run_wave, _get_wave_hud_title())


func _update_meta_hud() -> void:
	if not is_instance_valid(hud):
		return

	var details: Array[String] = []
	if is_instance_valid(player):
		var shield_charges := int(player.get("shield_charges"))
		if shield_charges > 0:
			details.append("SHIELD %d" % shield_charges)
	if _rerolls_left > 0:
		details.append("REROLL %d" % _rerolls_left)
	if _opening_charge_time_left > 0.0:
		details.append("CHARGE %.1fs" % _opening_charge_time_left)

	hud.call("set_meta_info", " | ".join(details))


func _record_enemy_defeated(enemy: Node) -> void:
	var enemy_id := _get_enemy_id(enemy)

	run_stats["total_enemies_defeated"] = int(run_stats.get("total_enemies_defeated", 0)) + 1

	var enemy_kills = run_stats.get("enemy_kills", {})
	enemy_kills[enemy_id] = int(enemy_kills.get(enemy_id, 0)) + 1
	run_stats["enemy_kills"] = enemy_kills

	if enemy_id == "pentagon_miniboss":
		run_stats["miniboss_defeated"] = true
	elif enemy_id == "hexagon_boss":
		run_stats["boss_defeated"] = true


func _get_enemy_id(enemy: Node) -> String:
	var raw_enemy_id = enemy.get("enemy_id")
	if raw_enemy_id == null:
		return "unknown"

	var enemy_id := str(raw_enemy_id)
	if enemy_id.is_empty():
		return "unknown"

	return enemy_id


func _get_wave_title(wave_type: String) -> String:
	match wave_type:
		"mini_boss":
			return "Mini-Boss"
		"boss":
			return "Final Boss"
		_:
			return ""


func _get_wave_hud_title() -> String:
	var title := _get_wave_title(current_wave_type)
	if title.is_empty():
		title = "Normal"
	if current_wave_modifier.is_empty():
		return title

	var modifier_name := str(current_wave_modifier.get("name", "Modifier"))
	return "%s - %s" % [title, modifier_name]


func _get_wave_message() -> String:
	if not current_wave_modifier.is_empty():
		return "Modifier: %s" % str(current_wave_modifier.get("name", "Modifier"))

	return _get_wave_title(current_wave_type)


func _choose_wave_modifier(wave_number: int, wave_type: String) -> Dictionary:
	if wave_type != "normal" or wave_number < 3:
		return {}
	if _rng.randf() > 0.4:
		return {}

	var modifiers: Array[Dictionary] = [
		{
			"id": "swarm",
			"name": "Swarm",
			"count_multiplier": 1.35,
			"health_multiplier": 0.82,
		},
		{
			"id": "reinforced_shapes",
			"name": "Reinforced Forms",
			"count_multiplier": 0.78,
			"health_multiplier": 1.38,
		},
		{
			"id": "unstable_field",
			"name": "Unstable Field",
			"speed_multiplier": 1.12,
		},
		{
			"id": "arcane_chaos",
			"name": "Arcane Chaos",
			"count_multiplier": 1.1,
			"score_multiplier": 1.2,
			"special_weight_bonus": 8,
		},
	]

	return modifiers[_rng.randi_range(0, modifiers.size() - 1)].duplicate(true)


func _on_enemy_damage_taken(_enemy: Node, amount: int, world_position: Vector2) -> void:
	_play_audio("play_enemy_hit")
	_spawn_floating_text("-%d" % amount, world_position + Vector2(0.0, -24.0), Color(1.0, 0.78, 0.32), 0.62)
	_spawn_burst(world_position, Color(1.0, 0.72, 0.28), 6)


func _on_player_damage_taken(amount: int, world_position: Vector2) -> void:
	_play_audio("play_player_hit")
	_spawn_floating_text("-%d" % amount, world_position + Vector2(0.0, -30.0), Color(1.0, 0.34, 0.34), 0.72)
	_start_camera_shake(0.18, 8.0)
	_try_trigger_emergency_pulse()


func _on_player_shield_changed(_charges: int) -> void:
	_update_meta_hud()


func _on_player_shield_absorbed(world_position: Vector2) -> void:
	_play_audio("play_player_hit")
	_spawn_floating_text("BLOCK", world_position + Vector2(0.0, -32.0), Color(0.5, 0.94, 1.0), 0.6)
	_spawn_impact_ring(world_position, Color(0.48, 0.92, 1.0, 0.76), 14.0, 48.0, 0.3, 2.5)
	_start_camera_shake(0.1, 3.0)


func _try_trigger_emergency_pulse() -> void:
	if not _has_meta_skill("emergency_pulse") or _emergency_pulse_cooldown_left > 0.0 or not is_instance_valid(player):
		return

	var max_health := int(player.get("max_health"))
	var current_health := int(player.get("current_health"))
	if max_health <= 0 or float(current_health) / float(max_health) > 0.3:
		return

	var pulse_radius := _get_meta_effect_value("emergency_pulse_radius")
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or enemy.global_position.distance_to(player.global_position) > pulse_radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.call("take_damage", 14)

	_emergency_pulse_cooldown_left = 7.0
	_play_audio("play_explosion")
	_spawn_floating_text("PULSO", player.global_position + Vector2(0.0, -48.0), Color(0.64, 0.84, 1.0), 0.68)
	_spawn_burst(player.global_position, Color(0.48, 0.82, 1.0), 16)
	_spawn_impact_ring(player.global_position, Color(0.5, 0.84, 1.0, 0.78), 22.0, pulse_radius, 0.5, 3.6)
	_start_camera_shake(0.16, 5.0)


func _on_star_bomber_exploded(enemy: Node, world_position: Vector2, radius: float, damage: int) -> void:
	_play_audio("play_explosion")
	_spawn_burst(world_position, Color(1.0, 0.24, 0.12), 24)
	_spawn_shatter(world_position, Color(1.0, 0.42, 0.12), "star", 1.45, 16, 2)
	_spawn_impact_ring(world_position, Color(1.0, 0.25, 0.12, 0.86), radius * 0.18, radius, 0.5, 4.0)
	_spawn_floating_text("EXPLOSION", world_position + Vector2(0.0, -28.0), Color(1.0, 0.48, 0.24), 0.7)
	_start_camera_shake(0.16, 6.0)

	if is_instance_valid(player) and player.global_position.distance_to(world_position) <= radius:
		if player.has_method("take_damage"):
			player.call("take_damage", damage)

	for other_enemy in enemies.duplicate():
		if not is_instance_valid(other_enemy) or other_enemy == enemy:
			continue
		if other_enemy.global_position.distance_to(world_position) > radius:
			continue
		if other_enemy.has_method("take_damage"):
			other_enemy.call("take_damage", int(round(float(damage) * 0.65)))


func _on_line_sniper_laser_fired(_enemy: Node, origin: Vector2, direction: Vector2, laser_range: float, width: float, damage: int) -> void:
	_play_audio("play_laser")
	var normalized_direction := direction.normalized()
	if normalized_direction == Vector2.ZERO:
		normalized_direction = Vector2.RIGHT

	var end_position := origin + normalized_direction * laser_range
	_spawn_burst(origin, Color(1.0, 0.2, 0.24), 8)
	_spawn_impact_ring(origin, Color(1.0, 0.22, 0.28, 0.6), 4.0, 34.0, 0.26, 2.5)
	_spawn_floating_text("LASER", origin + normalized_direction * 38.0 + Vector2(0.0, -20.0), Color(1.0, 0.36, 0.36), 0.5)

	if not is_instance_valid(player):
		return

	var distance := _distance_point_to_segment(player.global_position, origin, end_position)
	if distance <= width and player.has_method("take_damage"):
		player.call("take_damage", damage)


func _distance_point_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()
	if segment_length_squared <= 0.001:
		return point.distance_to(segment_start)

	var t := clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest := segment_start + segment * t
	return point.distance_to(closest)


func _spawn_floating_text(text: String, world_position: Vector2, color: Color, duration: float = 0.72) -> void:
	var floating_text := FLOATING_TEXT_SCENE.instantiate() as Node2D
	add_child(floating_text)
	floating_text.call("setup", text, world_position, color, duration)


func _spawn_burst(world_position: Vector2, color: Color, particle_count: int = 10) -> void:
	var burst := BURST_EFFECT_SCENE.instantiate() as Node2D
	add_child(burst)
	burst.call("setup", world_position, color, particle_count)


func _get_upgrade_option_count() -> int:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("get_upgrade_option_count"):
		return 3

	return maxi(int(save_manager.call("get_upgrade_option_count")), 3)


func _get_meta_incoming_damage_multiplier() -> float:
	return 1.0


func _apply_miniboss_repair_bonus() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not is_instance_valid(player):
		return

	var heal_amount := int(save_manager.call("get_skill_effect_value", "miniboss_heal_bonus"))
	if heal_amount <= 0 or not player.has_method("heal"):
		return

	player.call("heal", heal_amount)
	_spawn_floating_text("+%d" % heal_amount, player.global_position + Vector2(0.0, -34.0), Color(0.54, 1.0, 0.72), 0.7)
	_spawn_impact_ring(player.global_position, Color(0.54, 1.0, 0.72, 0.62), 12.0, 54.0, 0.35, 2.2)


func _spawn_shatter(world_position: Vector2, color: Color, shape_type: String, intensity: float, fragment_count: int, ring_count: int = 1) -> void:
	var shatter := GEOMETRIC_SHATTER_SCENE.instantiate() as Node2D
	add_child(shatter)
	shatter.call("setup", world_position, color, shape_type, intensity, fragment_count, ring_count)


func _spawn_impact_ring(world_position: Vector2, color: Color, start_radius: float, end_radius: float, duration: float = 0.48, width: float = 3.0) -> void:
	var ring := IMPACT_RING_SCENE.instantiate() as Node2D
	add_child(ring)
	ring.call("setup", world_position, color, start_radius, end_radius, duration, width)


func _spawn_enemy_death_effect(enemy: Node, world_position: Vector2) -> void:
	var profile := _get_enemy_shatter_profile(enemy)
	var shatter_color: Color = profile.get("color", Color(1.0, 0.45, 0.26))
	_spawn_shatter(
		world_position,
		shatter_color,
		str(profile["shape_type"]),
		float(profile["intensity"]),
		int(profile["fragments"]),
		int(profile["rings"])
	)

	var shake_strength := float(profile.get("shake_strength", 0.0))
	if shake_strength > 0.0:
		_start_camera_shake(float(profile.get("shake_duration", 0.14)), shake_strength)


func _get_enemy_shatter_profile(enemy: Node) -> Dictionary:
	var enemy_id := _get_enemy_id(enemy)
	var fallback_color := _get_enemy_color(enemy)
	var profiles: Dictionary = {
		"circle_chaser": {"shape_type": "circle", "color": fallback_color, "intensity": 0.85, "fragments": 7, "rings": 1},
		"triangle_dasher": {"shape_type": "triangle", "color": fallback_color, "intensity": 1.05, "fragments": 8, "rings": 1},
		"square_tank": {"shape_type": "square", "color": fallback_color, "intensity": 1.18, "fragments": 12, "rings": 1, "shake_strength": 3.5, "shake_duration": 0.12},
		"diamond_shooter": {"shape_type": "diamond", "color": fallback_color, "intensity": 1.12, "fragments": 10, "rings": 1, "shake_strength": 2.5, "shake_duration": 0.1},
		"star_bomber": {"shape_type": "star", "color": fallback_color, "intensity": 1.35, "fragments": 14, "rings": 2, "shake_strength": 5.0, "shake_duration": 0.16},
		"line_sniper": {"shape_type": "line", "color": fallback_color, "intensity": 1.05, "fragments": 10, "rings": 1, "shake_strength": 2.0, "shake_duration": 0.1},
		"pentagon_miniboss": {"shape_type": "boss", "color": fallback_color, "intensity": 1.8, "fragments": 24, "rings": 2, "shake_strength": 8.0, "shake_duration": 0.24},
		"hexagon_boss": {"shape_type": "boss", "color": fallback_color, "intensity": 2.45, "fragments": 52, "rings": 3, "shake_strength": 13.0, "shake_duration": 0.36},
	}

	var default_profile: Dictionary = {"shape_type": "circle", "color": fallback_color, "intensity": 0.9, "fragments": 7, "rings": 1}
	var profile: Dictionary = profiles.get(enemy_id, default_profile)
	return profile


func _get_enemy_color(enemy: Node) -> Color:
	var color_value = enemy.get("fill_color")
	if color_value is Color:
		return color_value

	match _get_enemy_id(enemy):
		"triangle_dasher":
			return Color(0.92, 0.42, 1.0)
		"square_tank":
			return Color(0.36, 0.88, 0.54)
		"diamond_shooter":
			return Color(0.38, 0.82, 1.0)
		"star_bomber":
			return Color(1.0, 0.58, 0.16)
		"line_sniper":
			return Color(0.72, 0.8, 1.0)
		"pentagon_miniboss":
			return Color(0.92, 0.54, 0.18)
		"hexagon_boss":
			return Color(0.36, 0.62, 1.0)
		_:
			return Color(1.0, 0.28, 0.34)


func _get_spell_visual_profile() -> Dictionary:
	var base_profile := {
		"primary_color": _spell_attributes.get("fill_color", Color(1.0, 0.92, 0.28)),
		"secondary_color": _spell_attributes.get("outline_color", Color(1.0, 1.0, 0.82)),
		"impact_color": _spell_attributes.get("impact_color", Color(1.0, 0.58, 0.22)),
		"aura_color": _spell_attributes.get("outline_color", Color(0.36, 0.95, 1.0)),
	}
	if spell_graph == null:
		return base_profile
	return spell_graph.get_visual_profile(base_profile)


func _get_projectile_visual_colors(overrides: Dictionary, opening_charged: bool = false) -> Dictionary:
	var visual_profile := _get_spell_visual_profile()
	var primary: Color = visual_profile.get("primary_color", Color(1.0, 0.92, 0.28))
	var secondary: Color = visual_profile.get("secondary_color", Color(1.0, 1.0, 0.82))
	if overrides.has("fill_color") or overrides.has("outline_color"):
		return {
			"fill_color": primary.lerp(overrides.get("fill_color", primary), 0.28),
			"outline_color": secondary.lerp(overrides.get("outline_color", secondary), 0.58),
		}

	if opening_charged:
		return {
			"fill_color": primary.lerp(Color(1.0, 0.72, 0.24), 0.24),
			"outline_color": secondary.lerp(Color(1.0, 0.98, 0.72), 0.58),
		}

	return {
		"fill_color": primary,
		"outline_color": secondary,
	}


func _on_boss_summon_requested(count: int, world_position: Vector2) -> void:
	if _run_finished:
		return

	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1))
		var spawn_position := world_position + Vector2.RIGHT.rotated(angle) * 96.0
		spawn_position.x = clampf(spawn_position.x, arena_rect.position.x + spawn_edge_padding, arena_rect.end.x - spawn_edge_padding)
		spawn_position.y = clampf(spawn_position.y, arena_rect.position.y + spawn_edge_padding, arena_rect.end.y - spawn_edge_padding)
		_spawn_enemy(CIRCLE_CHASER_SCENE, spawn_position)

	_update_hud()


func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "GameCamera"
	camera.position = arena_rect.get_center()
	camera.enabled = true
	add_child(camera)
	camera.make_current()


func _start_camera_shake(duration: float, strength: float) -> void:
	_camera_shake_duration = duration
	_camera_shake_time_left = duration
	_camera_shake_strength = strength


func _update_camera_shake(delta: float) -> void:
	if not is_instance_valid(camera):
		return

	if _camera_shake_time_left <= 0.0:
		camera.offset = Vector2.ZERO
		return

	_camera_shake_time_left = maxf(_camera_shake_time_left - delta, 0.0)
	var fade := _camera_shake_time_left / maxf(_camera_shake_duration, 0.001)
	camera.offset = Vector2(
		_rng.randf_range(-_camera_shake_strength, _camera_shake_strength),
		_rng.randf_range(-_camera_shake_strength, _camera_shake_strength)
	) * fade


func _get_alive_enemy_count() -> int:
	var alive_count := 0

	for enemy in enemies:
		if is_instance_valid(enemy):
			alive_count += 1

	return alive_count


func _on_player_died() -> void:
	if _is_restarting or _run_finished:
		return

	_spawn_player_death_effect()
	_finish_run(false, 1.0)


func _finish_run(victory: bool, result_delay: float = 0.0) -> void:
	if _run_finished:
		return

	if _graph_open:
		_close_spell_graph()
	if _pause_open:
		_close_pause_menu()
	_run_finished = true
	_wave_in_progress = false
	_reward_open = false
	_finalize_run_stats()
	_apply_meta_progress(victory)

	if is_instance_valid(_auto_fire_timer):
		_auto_fire_timer.stop()
	if is_instance_valid(upgrade_panel):
		upgrade_panel.hide()
	if is_instance_valid(hud):
		hud.call("set_wave_message", "Run complete" if victory else "Run ended")

	if victory:
		_play_audio("play_victory")
		_spawn_impact_ring(arena_rect.get_center(), Color(0.54, 1.0, 0.72, 0.8), 38.0, 220.0, 0.82, 4.0)
		_start_camera_shake(0.34, 12.0)
	else:
		_play_audio("play_defeat")
		_start_camera_shake(0.24, 9.0)

	_clear_active_threats()

	if result_delay > 0.0:
		await get_tree().create_timer(result_delay).timeout

	if is_instance_valid(result_panel):
		result_panel.call("show_result", victory, run_stats, max_run_wave)


func _spawn_player_death_effect() -> void:
	if not is_instance_valid(player):
		return

	var player_color := Color(0.18, 0.78, 1.0)
	var player_color_value = player.get("fill_color")
	if player_color_value is Color:
		player_color = player_color_value

	var shape_type := str(player.get("visual_shape"))
	_spawn_shatter(player.global_position, player_color, shape_type, 1.9, 30, 2)
	_spawn_impact_ring(player.global_position, Color(player_color.r, player_color.g, player_color.b, 0.82), 16.0, 132.0, 0.7, 4.0)
	player.hide()


func _finalize_run_stats() -> void:
	run_stats["run_time_seconds"] = run_time_seconds
	run_stats["max_wave_reached"] = maxi(int(run_stats.get("max_wave_reached", 0)), current_wave)
	run_stats["final_score"] = score
	run_stats["build_nodes"] = _get_spell_chain_labels()
	run_stats["spell_graph"] = spell_graph.get_summary() if spell_graph != null else {}
	run_stats["spell_blueprint"] = selected_spell_summary.duplicate(true)
	run_stats["victory"] = bool(run_stats.get("boss_defeated", false))
	run_stats["active_synergies"] = active_synergies.duplicate()
	run_stats["wave_modifiers"] = wave_modifiers_seen.duplicate()
	run_stats["modifier_wave_count"] = wave_modifiers_seen.size()


func _apply_meta_progress(victory: bool) -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	run_stats["victory"] = victory
	if save_manager == null:
		return

	var meta_result: Dictionary = save_manager.call("apply_run_result", run_stats, victory)
	for key in meta_result.keys():
		run_stats[key] = meta_result[key]


func _get_spell_chain_labels() -> Array[String]:
	if spell_graph == null:
		return ["Projectile"]
	return spell_graph.get_ordered_labels()


func _clear_active_threats() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

	_clear_projectiles()
	_clear_area_spells()


func _clear_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(projectile):
			projectile.queue_free()
	for projectile in get_tree().get_nodes_in_group("player_projectiles"):
		if is_instance_valid(projectile):
			projectile.queue_free()


func _clear_area_spells() -> void:
	for area_spell in _active_area_spells:
		if is_instance_valid(area_spell):
			area_spell.queue_free()
	_active_area_spells.clear()


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)


func _restart_scene() -> void:
	_is_restarting = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func _go_to_main_menu() -> void:
	_is_restarting = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
