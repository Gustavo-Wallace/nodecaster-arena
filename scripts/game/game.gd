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
const UPGRADE_PANEL_SCENE := preload("res://scenes/ui/upgrade_panel.tscn")
const SPELL_CHAIN_PANEL_SCENE := preload("res://scenes/ui/spell_chain_panel.tscn")
const FLOATING_TEXT_SCENE := preload("res://scenes/ui/floating_text.tscn")
const BURST_EFFECT_SCENE := preload("res://scenes/effects/burst_effect.tscn")
const PENTAGON_MINIBOSS_SCENE := preload("res://scenes/enemies/pentagon_miniboss.tscn")
const HEXAGON_BOSS_SCENE := preload("res://scenes/enemies/hexagon_boss.tscn")
const RUN_RESULT_PANEL_SCENE := preload("res://scenes/ui/run_result_panel.tscn")
const UNSTABLE_FIELD_AURA_SCRIPT := preload("res://scripts/effects/unstable_field_aura.gd")

@export var arena_position: Vector2 = Vector2(96.0, 72.0)
@export var arena_size: Vector2 = Vector2(1088.0, 576.0)
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
var upgrade_panel: Control
var spell_chain_panel: Control
var result_panel: Control
var enemies: Array[Node2D] = []
var arena_rect: Rect2
var current_wave: int = 0
var current_wave_type: String = "normal"
var current_wave_modifier: Dictionary = {}
var score: int = 0
var spell_chain_nodes: Array[Dictionary] = []
var run_time_seconds: float = 0.0
var run_stats: Dictionary = {}
var selected_character_data: Dictionary = {}
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


func _ready() -> void:
	_rng.randomize()
	selected_character_data = _get_selected_character_data()
	_apply_selected_character_to_run()
	_available_upgrades = _filter_unlocked_upgrades(_create_upgrade_data())
	_wave_enemy_counts = _create_wave_enemy_counts()
	run_stats = _create_run_stats()
	spell_chain_nodes = [_create_base_spell_node()]
	arena_rect = Rect2(arena_position, arena_size)

	_setup_camera()
	_spawn_player()
	_spawn_hud()
	_start_auto_fire()
	_start_wave(1)
	queue_redraw()


func _process(delta: float) -> void:
	if not _run_finished:
		run_time_seconds += delta
		_update_unstable_field(delta)
		if is_instance_valid(hud):
			hud.call("set_run_time", run_time_seconds)

	_update_camera_shake(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _run_finished:
		return

	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
		_restart_scene()


func _draw() -> void:
	draw_rect(arena_rect, Color(0.045, 0.055, 0.07), true)
	draw_rect(arena_rect, Color(0.26, 0.46, 0.62), false, 3.0)

	var inner_rect := arena_rect.grow(-8.0)
	draw_rect(inner_rect, Color(0.09, 0.13, 0.16), false, 1.0)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Node2D
	add_child(player)
	player.call("apply_character_data", selected_character_data)
	player.global_position = arena_rect.get_center()
	player.call("set_arena_rect", arena_rect)
	player.connect("died", Callable(self, "_on_player_died"))
	player.connect("damage_taken", Callable(self, "_on_player_damage_taken"))


func _spawn_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HudLayer"
	add_child(hud_layer)

	hud = GAME_HUD_SCENE.instantiate() as Control
	hud_layer.add_child(hud)
	hud.call("bind_player", player)

	spell_chain_panel = SPELL_CHAIN_PANEL_SCENE.instantiate() as Control
	hud_layer.add_child(spell_chain_panel)
	spell_chain_panel.call("set_chain_nodes", spell_chain_nodes)
	spell_chain_panel.call("set_synergies", active_synergies)

	upgrade_panel = UPGRADE_PANEL_SCENE.instantiate() as Control
	hud_layer.add_child(upgrade_panel)
	upgrade_panel.connect("upgrade_selected", Callable(self, "_on_upgrade_selected"))

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
		var modifier_name := str(current_wave_modifier.get("name", "Modificador"))
		wave_modifiers_seen.append(modifier_name)
	run_stats["max_wave_reached"] = maxi(int(run_stats.get("max_wave_reached", 0)), current_wave)
	_wave_in_progress = true
	_reward_open = false
	enemies.clear()

	if is_instance_valid(_auto_fire_timer):
		_auto_fire_timer.wait_time = auto_fire_interval
		_auto_fire_timer.start()

	_spawn_wave_enemies()

	_update_hud()
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
		"character_name": str(selected_character_data.get("display_name", "Circulo")),
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
	}


func _get_selected_character_data() -> Dictionary:
	var run_config := get_node_or_null("/root/RunConfig")
	if run_config == null:
		return {
			"id": "circle",
			"display_name": "Circulo",
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
	projectile_damage = int(selected_character_data.get("projectile_damage", projectile_damage))
	projectile_speed = float(selected_character_data.get("projectile_speed", projectile_speed))
	projectile_count = int(selected_character_data.get("projectile_count", projectile_count))
	auto_fire_interval = float(selected_character_data.get("fire_interval", auto_fire_interval))


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

	var target := _get_nearest_enemy()
	if target == null:
		return

	var base_direction := player.global_position.direction_to(target.global_position)
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	var count := maxi(projectile_count, 1)
	var total_spread := deg_to_rad(projectile_spread_degrees) * float(count - 1)
	var start_angle := -total_spread * 0.5

	for index in range(count):
		var angle_offset := 0.0
		if count > 1:
			angle_offset = start_angle + deg_to_rad(projectile_spread_degrees) * float(index)

		var direction := base_direction.rotated(angle_offset)
		_spawn_projectile(player.global_position + direction * 30.0, direction)

	_shot_sequence += 1
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


func _spawn_projectile(spawn_position: Vector2, direction: Vector2, overrides: Dictionary = {}) -> void:
	var projectile := BASIC_PROJECTILE_SCENE.instantiate() as Area2D
	var actual_damage := int(overrides.get("damage", projectile_damage))
	projectile.set("damage", actual_damage)
	projectile.set("speed", float(overrides.get("speed", projectile_speed)))
	projectile.set("pierce_left", projectile_pierce)
	projectile.set("bounce_left", projectile_bounce)
	projectile.set("arena_rect", arena_rect)
	projectile.set("explosion_radius", projectile_explosion_radius)
	projectile.set("explosion_damage", int(round(float(actual_damage) * projectile_explosion_damage_multiplier)))
	projectile.set("size_multiplier", float(overrides.get("size_multiplier", projectile_size_multiplier)))
	projectile.set("visual_shape", str(overrides.get("visual_shape", "circle")))
	projectile.set("fill_color", overrides.get("fill_color", Color(1.0, 0.92, 0.28)))
	projectile.set("outline_color", overrides.get("outline_color", Color(1.0, 1.0, 0.82)))
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

	_spawn_burst(death_position, Color(1.0, 0.45, 0.26), 14)
	enemies.erase(enemy)
	_record_enemy_defeated(enemy)
	score += _get_score_value_for_enemy(enemy)
	_update_hud()

	if current_wave_type == "boss" and _get_enemy_id(enemy) == "hexagon_boss":
		_finish_run(true)
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

	if is_instance_valid(_auto_fire_timer):
		_auto_fire_timer.stop()

	if current_wave_type == "mini_boss":
		hud.call("set_wave_message", "Mini-Boss derrotado")
	else:
		hud.call("set_wave_message", "Onda concluida")

	_show_upgrade_reward()


func _start_next_wave() -> void:
	_start_wave(current_wave + 1)


func _show_upgrade_reward() -> void:
	if not is_instance_valid(upgrade_panel):
		_start_next_wave()
		return

	upgrade_panel.call("show_upgrades", _pick_upgrade_options(3))


func _pick_upgrade_options(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = _available_upgrades.duplicate()
	var picked: Array[Dictionary] = []

	_pick_priority_meta_upgrades(pool, picked, count)

	while picked.size() < count and not pool.is_empty():
		var index := _rng.randi_range(0, pool.size() - 1)
		var upgrade: Dictionary = pool[index].duplicate(true)
		_prepare_upgrade_option(upgrade)
		picked.append(upgrade)
		pool.remove_at(index)

	return picked


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


func _on_upgrade_selected(upgrade: Dictionary) -> void:
	_add_spell_node_from_upgrade(upgrade)
	_apply_upgrade(upgrade)
	run_stats["upgrades_chosen"] = int(run_stats.get("upgrades_chosen", 0)) + 1
	_spawn_floating_text("NO +1", arena_rect.position + Vector2(arena_rect.size.x * 0.5, arena_rect.size.y - 92.0), Color(0.72, 0.96, 1.0), 0.8)
	_reward_open = false
	hud.call("set_wave_message", "Proxima onda...")
	get_tree().create_timer(wave_interval).timeout.connect(_start_next_wave)


func _apply_upgrade(upgrade: Dictionary) -> void:
	var upgrade_id := str(upgrade.get("id", ""))
	var values = upgrade.get("values", {})

	match upgrade_id:
		"arcane_damage":
			projectile_damage += int(values.get("damage_bonus", 4))
		"unstable_cadence":
			auto_fire_interval = maxf(auto_fire_interval * float(values.get("interval_multiplier", 0.88)), min_auto_fire_interval)
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
		"initial_fragmentation":
			projectile_count = mini(projectile_count + int(values.get("projectile_count_bonus", 1)), max_projectile_count)
		"piercing":
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
	var spell_node := {
		"id": upgrade_id,
		"name": str(upgrade.get("name", "Upgrade")),
		"category": str(upgrade.get("category", "projectile")),
		"node_label": str(upgrade.get("node_label", upgrade.get("name", "Upgrade"))),
		"effect_type": str(upgrade.get("effect_type", "")),
		"stack": int(upgrade_stacks.get(upgrade_id, 1)),
	}

	spell_chain_nodes.append(spell_node)

	if is_instance_valid(spell_chain_panel):
		spell_chain_panel.call("add_node", spell_node)


func _create_base_spell_node() -> Dictionary:
	return {
		"id": "base_projectile",
		"name": "Projetil",
		"category": "base",
		"node_label": "Projetil",
		"effect_type": "base_projectile",
	}


func _create_upgrade_data() -> Array[Dictionary]:
	return [
		{
			"id": "arcane_damage",
			"name": "Dano Arcano",
			"description": "+5 de dano nos projeteis.",
			"category": "power",
			"effect_type": "projectile_damage",
			"node_label": "Dano",
			"values": {
				"damage_bonus": 5,
			},
		},
		{
			"id": "unstable_cadence",
			"name": "Cadencia Instavel",
			"description": "Disparos automaticos 16% mais rapidos.",
			"category": "rhythm",
			"effect_type": "fire_interval",
			"node_label": "Cadencia",
			"values": {
				"interval_multiplier": 0.84,
			},
		},
		{
			"id": "light_core",
			"name": "Nucleo Leve",
			"description": "+35 de velocidade de movimento.",
			"category": "body",
			"effect_type": "player_speed",
			"node_label": "Nucleo",
			"values": {
				"speed_bonus": 35.0,
			},
		},
		{
			"id": "energy_shell",
			"name": "Casca Energetica",
			"description": "+22 de vida maxima e cura 16.",
			"category": "body",
			"effect_type": "player_health",
			"node_label": "Casca",
			"values": {
				"max_health_bonus": 22,
				"heal_amount": 16,
			},
		},
		{
			"id": "swift_projectile",
			"name": "Projetil Veloz",
			"description": "+80 de velocidade dos projeteis.",
			"category": "projectile",
			"effect_type": "projectile_speed",
			"node_label": "Velocidade",
			"values": {
				"projectile_speed_bonus": 80.0,
			},
		},
		{
			"id": "initial_fragmentation",
			"name": "Fragmentacao Inicial",
			"description": "+1 projetil por disparo, em leque.",
			"category": "projectile",
			"effect_type": "projectile_count",
			"node_label": "Fragmenta",
			"values": {
				"projectile_count_bonus": 1,
			},
		},
		{
			"id": "piercing",
			"name": "Perfuracao",
			"description": "Projeteis atravessam +1 inimigo.",
			"category": "projectile",
			"effect_type": "projectile_pierce",
			"node_label": "Perfura",
			"unlock_id": "upgrade_piercing",
			"values": {
				"pierce_bonus": 1,
			},
		},
		{
			"id": "ricochet",
			"name": "Ricochete",
			"description": "Projeteis ricocheteiam +1 vez nas bordas.",
			"category": "projectile",
			"effect_type": "projectile_bounce",
			"node_label": "Ricochete",
			"values": {
				"bounce_bonus": 1,
			},
		},
		{
			"id": "arcane_explosion",
			"name": "Explosao Arcana",
			"description": "Impactos causam dano em area.",
			"category": "power",
			"effect_type": "area_explosion",
			"node_label": "Explode",
			"values": {
				"radius_bonus": 60.0,
				"damage_multiplier_bonus": 0.5,
			},
		},
		{
			"id": "heavy_orb",
			"name": "Orbe Pesado",
			"description": "+40% dano, -15% velocidade, projetil maior.",
			"category": "projectile",
			"effect_type": "heavy_projectile",
			"node_label": "Orbe",
			"values": {
				"damage_multiplier": 1.4,
				"speed_multiplier": 0.85,
				"size_bonus": 0.2,
			},
		},
		{
			"id": "cutting_echo",
			"name": "Eco Cortante",
			"description": "A cada 4 disparos, lanca um projetil extra forte.",
			"category": "rhythm",
			"effect_type": "special_projectile",
			"node_label": "Eco",
			"values": {
				"shot_interval": 4,
				"damage_multiplier_bonus": 0.25,
			},
		},
		{
			"id": "unstable_field",
			"name": "Campo Instavel",
			"description": "Aura fraca causa dano periodico em inimigos proximos.",
			"category": "area",
			"effect_type": "player_aura",
			"node_label": "Campo",
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


func _on_projectile_explosion_requested(world_position: Vector2, radius: float, damage: int) -> void:
	if radius <= 0.0 or damage <= 0:
		return

	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(world_position) > radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.call("take_damage", damage)

	_spawn_burst(world_position, Color(0.92, 0.48, 1.0), 18)
	_spawn_floating_text("BOOM", world_position + Vector2(0.0, -18.0), Color(1.0, 0.78, 1.0), 0.55)


func _on_projectile_bounce_requested(world_position: Vector2) -> void:
	_spawn_burst(world_position, Color(0.58, 0.9, 1.0), 5)


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

	_spawn_burst(player.global_position, Color(0.36, 0.95, 1.0), 8)


func _ensure_unstable_field_aura() -> void:
	if not is_instance_valid(player):
		return

	if not is_instance_valid(_unstable_field_aura):
		_unstable_field_aura = Node2D.new()
		_unstable_field_aura.name = "UnstableFieldAura"
		_unstable_field_aura.set_script(UNSTABLE_FIELD_AURA_SCRIPT)
		player.add_child(_unstable_field_aura)

	_unstable_field_aura.set("radius", _get_effective_unstable_field_radius())


func _get_effective_unstable_field_radius() -> float:
	var radius := _unstable_field_radius
	if _has_upgrade("unstable_field") and _has_upgrade("energy_shell"):
		radius += 18.0
	return radius


func _update_active_synergies() -> void:
	active_synergies.clear()

	if _has_upgrade("initial_fragmentation") and _has_upgrade("arcane_explosion"):
		active_synergies.append("Fragmentacao Explosiva")
	if _has_upgrade("ricochet") and _has_upgrade("piercing"):
		active_synergies.append("Perfuracao Saltante")
	if _has_upgrade("unstable_field") and _has_upgrade("energy_shell"):
		active_synergies.append("Campo Blindado")
		_ensure_unstable_field_aura()

	if is_instance_valid(spell_chain_panel):
		spell_chain_panel.call("set_synergies", active_synergies)


func _has_upgrade(upgrade_id: String) -> bool:
	return int(upgrade_stacks.get(upgrade_id, 0)) > 0


func _update_hud() -> void:
	if is_instance_valid(hud):
		hud.call("set_wave_info", current_wave, _get_alive_enemy_count(), score, max_run_wave, _get_wave_hud_title())


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
			return "Boss Final"
		_:
			return ""


func _get_wave_hud_title() -> String:
	var title := _get_wave_title(current_wave_type)
	if title.is_empty():
		title = "Normal"
	if current_wave_modifier.is_empty():
		return title

	var modifier_name := str(current_wave_modifier.get("name", "Modificador"))
	return "%s - %s" % [title, modifier_name]


func _get_wave_message() -> String:
	if not current_wave_modifier.is_empty():
		return "Modificador: %s" % str(current_wave_modifier.get("name", "Modificador"))

	return _get_wave_title(current_wave_type)


func _choose_wave_modifier(wave_number: int, wave_type: String) -> Dictionary:
	if wave_type != "normal" or wave_number < 3:
		return {}
	if _rng.randf() > 0.4:
		return {}

	var modifiers: Array[Dictionary] = [
		{
			"id": "swarm",
			"name": "Enxame",
			"count_multiplier": 1.35,
			"health_multiplier": 0.82,
		},
		{
			"id": "reinforced_shapes",
			"name": "Formas Reforcadas",
			"count_multiplier": 0.78,
			"health_multiplier": 1.38,
		},
		{
			"id": "unstable_field",
			"name": "Campo Instavel",
			"speed_multiplier": 1.12,
		},
		{
			"id": "arcane_chaos",
			"name": "Caos Arcano",
			"count_multiplier": 1.1,
			"score_multiplier": 1.2,
			"special_weight_bonus": 8,
		},
	]

	return modifiers[_rng.randi_range(0, modifiers.size() - 1)].duplicate(true)


func _on_enemy_damage_taken(_enemy: Node, amount: int, world_position: Vector2) -> void:
	_spawn_floating_text("-%d" % amount, world_position + Vector2(0.0, -24.0), Color(1.0, 0.78, 0.32), 0.62)
	_spawn_burst(world_position, Color(1.0, 0.72, 0.28), 6)


func _on_player_damage_taken(amount: int, world_position: Vector2) -> void:
	_spawn_floating_text("-%d" % amount, world_position + Vector2(0.0, -30.0), Color(1.0, 0.34, 0.34), 0.72)
	_start_camera_shake(0.18, 8.0)


func _on_star_bomber_exploded(enemy: Node, world_position: Vector2, radius: float, damage: int) -> void:
	_spawn_burst(world_position, Color(1.0, 0.24, 0.12), 24)
	_spawn_floating_text("EXPLOSAO", world_position + Vector2(0.0, -28.0), Color(1.0, 0.48, 0.24), 0.7)
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
	var normalized_direction := direction.normalized()
	if normalized_direction == Vector2.ZERO:
		normalized_direction = Vector2.RIGHT

	var end_position := origin + normalized_direction * laser_range
	_spawn_burst(origin, Color(1.0, 0.2, 0.24), 8)
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

	_finish_run(false)


func _finish_run(victory: bool) -> void:
	_run_finished = true
	_wave_in_progress = false
	_reward_open = false
	_finalize_run_stats()
	_apply_meta_progress(victory)

	if is_instance_valid(_auto_fire_timer):
		_auto_fire_timer.stop()
	if is_instance_valid(upgrade_panel):
		upgrade_panel.hide()
	if is_instance_valid(result_panel):
		result_panel.call("show_result", victory, run_stats, max_run_wave)
	if is_instance_valid(hud):
		hud.call("set_wave_message", "Run concluida" if victory else "Run encerrada")

	if victory:
		_spawn_burst(arena_rect.get_center(), Color(0.54, 1.0, 0.72), 28)
		_start_camera_shake(0.28, 10.0)
	else:
		_start_camera_shake(0.24, 9.0)

	_clear_active_threats()


func _finalize_run_stats() -> void:
	run_stats["run_time_seconds"] = run_time_seconds
	run_stats["max_wave_reached"] = maxi(int(run_stats.get("max_wave_reached", 0)), current_wave)
	run_stats["final_score"] = score
	run_stats["build_nodes"] = _get_spell_chain_labels()
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
	var labels: Array[String] = []

	for node_data in spell_chain_nodes:
		labels.append(str(node_data.get("node_label", node_data.get("name", "No"))))

	return labels


func _clear_active_threats() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

	_clear_projectiles()


func _clear_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(projectile):
			projectile.queue_free()
	for projectile in get_tree().get_nodes_in_group("player_projectiles"):
		if is_instance_valid(projectile):
			projectile.queue_free()


func _restart_scene() -> void:
	_is_restarting = true
	get_tree().reload_current_scene()


func _go_to_main_menu() -> void:
	_is_restarting = true
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
