extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CIRCLE_CHASER_SCENE := preload("res://scenes/enemies/circle_chaser.tscn")
const TRIANGLE_DASHER_SCENE := preload("res://scenes/enemies/triangle_dasher.tscn")
const SQUARE_TANK_SCENE := preload("res://scenes/enemies/square_tank.tscn")
const BASIC_PROJECTILE_SCENE := preload("res://scenes/projectiles/basic_projectile.tscn")
const GAME_HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")
const UPGRADE_PANEL_SCENE := preload("res://scenes/ui/upgrade_panel.tscn")

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
@export var base_enemies_per_wave: int = 1
@export var enemies_added_per_wave: int = 2
@export var wave_interval: float = 2.0
@export var enemy_health_per_wave: int = 6
@export var enemy_speed_per_wave: float = 8.0
@export var fallback_enemy_score_value: int = 10
@export var spawn_edge_padding: float = 28.0
@export var min_spawn_distance_from_player: float = 180.0

var player: Node2D
var hud: Control
var upgrade_panel: Control
var enemies: Array[Node2D] = []
var arena_rect: Rect2
var current_wave: int = 0
var score: int = 0
var _auto_fire_timer: Timer
var _is_restarting: bool = false
var _wave_in_progress: bool = false
var _reward_open: bool = false
var _rng := RandomNumberGenerator.new()
var _available_upgrades: Array[Dictionary] = []


func _ready() -> void:
	_rng.randomize()
	_available_upgrades = _create_upgrade_data()
	arena_rect = Rect2(arena_position, arena_size)

	_spawn_player()
	_spawn_hud()
	_start_auto_fire()
	_start_wave(1)
	queue_redraw()


func _draw() -> void:
	draw_rect(arena_rect, Color(0.045, 0.055, 0.07), true)
	draw_rect(arena_rect, Color(0.26, 0.46, 0.62), false, 3.0)

	var inner_rect := arena_rect.grow(-8.0)
	draw_rect(inner_rect, Color(0.09, 0.13, 0.16), false, 1.0)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Node2D
	add_child(player)
	player.global_position = arena_rect.get_center()
	player.call("set_arena_rect", arena_rect)
	player.connect("died", Callable(self, "_on_player_died"))


func _spawn_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HudLayer"
	add_child(hud_layer)

	hud = GAME_HUD_SCENE.instantiate() as Control
	hud_layer.add_child(hud)
	hud.call("bind_player", player)

	upgrade_panel = UPGRADE_PANEL_SCENE.instantiate() as Control
	hud_layer.add_child(upgrade_panel)
	upgrade_panel.connect("upgrade_selected", Callable(self, "_on_upgrade_selected"))


func _start_wave(wave_number: int) -> void:
	if _is_restarting:
		return

	current_wave = wave_number
	_wave_in_progress = true
	_reward_open = false
	enemies.clear()

	if is_instance_valid(_auto_fire_timer):
		_auto_fire_timer.wait_time = auto_fire_interval
		_auto_fire_timer.start()

	var enemy_scenes := _build_enemy_scenes_for_wave(current_wave)
	for enemy_scene in enemy_scenes:
		_spawn_enemy(enemy_scene, _get_spawn_position_near_arena_edge())

	_update_hud()
	hud.call("set_wave_message", "")


func _get_enemy_count_for_wave(wave_number: int) -> int:
	return base_enemies_per_wave + wave_number * enemies_added_per_wave


func _build_enemy_scenes_for_wave(wave_number: int) -> Array[PackedScene]:
	var enemy_count := _get_enemy_count_for_wave(wave_number)
	var triangle_count := 0
	var square_count := 0

	if wave_number >= 2:
		triangle_count = maxi(1, int(floor(float(enemy_count) * 0.25)))
	if wave_number >= 3:
		square_count = maxi(1, int(floor(float(enemy_count) * 0.18)))

	if triangle_count + square_count > enemy_count:
		triangle_count = maxi(enemy_count - square_count, 0)

	var circle_count := maxi(enemy_count - triangle_count - square_count, 0)
	var enemy_scenes: Array[PackedScene] = []

	for _index in range(circle_count):
		enemy_scenes.append(CIRCLE_CHASER_SCENE)
	for _index in range(triangle_count):
		enemy_scenes.append(TRIANGLE_DASHER_SCENE)
	for _index in range(square_count):
		enemy_scenes.append(SQUARE_TANK_SCENE)

	_shuffle_enemy_scenes(enemy_scenes)
	return enemy_scenes


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
	enemies.append(enemy)


func _apply_wave_scaling_to_enemy(enemy: Node) -> void:
	var wave_bonus := maxi(current_wave - 1, 0)
	var base_health = enemy.get("max_health")
	var base_speed = enemy.get("speed")

	if base_health != null:
		enemy.set("max_health", int(base_health) + wave_bonus * enemy_health_per_wave)
	if base_speed != null:
		enemy.set("speed", float(base_speed) + float(wave_bonus) * enemy_speed_per_wave)


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
	if _is_restarting or _reward_open or not is_instance_valid(player):
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


func _spawn_projectile(spawn_position: Vector2, direction: Vector2) -> void:
	var projectile := BASIC_PROJECTILE_SCENE.instantiate() as Area2D
	add_child(projectile)
	projectile.set("damage", projectile_damage)
	projectile.set("speed", projectile_speed)
	projectile.set("pierce_left", projectile_pierce)
	projectile.call("setup", spawn_position, spawn_position + direction * 100.0)


func _get_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D = null
	var nearest_distance := INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	return nearest_enemy


func _on_enemy_died(enemy: Node) -> void:
	enemies.erase(enemy)
	score += _get_score_value_for_enemy(enemy)
	_update_hud()

	if _wave_in_progress and enemies.is_empty() and not _is_restarting:
		_complete_wave()


func _get_score_value_for_enemy(enemy: Node) -> int:
	var enemy_score = enemy.get("score_value")
	if enemy_score == null:
		return fallback_enemy_score_value

	return int(enemy_score)


func _complete_wave() -> void:
	_wave_in_progress = false
	_reward_open = true

	if is_instance_valid(_auto_fire_timer):
		_auto_fire_timer.stop()

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
	var pool := _available_upgrades.duplicate()
	var picked: Array[Dictionary] = []

	while picked.size() < count and not pool.is_empty():
		var index := _rng.randi_range(0, pool.size() - 1)
		picked.append(pool[index])
		pool.remove_at(index)

	return picked


func _on_upgrade_selected(upgrade: Dictionary) -> void:
	_apply_upgrade(upgrade)
	_reward_open = false
	hud.call("set_wave_message", "Proxima onda...")
	get_tree().create_timer(wave_interval).timeout.connect(_start_next_wave)


func _apply_upgrade(upgrade: Dictionary) -> void:
	var upgrade_id := str(upgrade.get("id", ""))

	match upgrade_id:
		"arcane_damage":
			projectile_damage += 4
		"unstable_cadence":
			auto_fire_interval = maxf(auto_fire_interval * 0.88, min_auto_fire_interval)
			if is_instance_valid(_auto_fire_timer):
				_auto_fire_timer.wait_time = auto_fire_interval
		"light_core":
			if is_instance_valid(player):
				var current_speed = player.get("speed")
				if current_speed != null:
					player.set("speed", float(current_speed) + 35.0)
		"energy_shell":
			if is_instance_valid(player) and player.has_method("increase_max_health"):
				player.call("increase_max_health", 20, 12)
		"swift_projectile":
			projectile_speed += 80.0
		"initial_fragmentation":
			projectile_count = mini(projectile_count + 1, max_projectile_count)
		"piercing":
			projectile_pierce += 1


func _create_upgrade_data() -> Array[Dictionary]:
	return [
		{
			"id": "arcane_damage",
			"name": "Dano Arcano",
			"description": "+4 de dano nos projeteis.",
		},
		{
			"id": "unstable_cadence",
			"name": "Cadencia Instavel",
			"description": "Disparos automaticos 12% mais rapidos.",
		},
		{
			"id": "light_core",
			"name": "Nucleo Leve",
			"description": "+35 de velocidade de movimento.",
		},
		{
			"id": "energy_shell",
			"name": "Casca Energetica",
			"description": "+20 de vida maxima e cura 12.",
		},
		{
			"id": "swift_projectile",
			"name": "Projetil Veloz",
			"description": "+80 de velocidade dos projeteis.",
		},
		{
			"id": "initial_fragmentation",
			"name": "Fragmentacao Inicial",
			"description": "+1 projetil por disparo, em leque.",
		},
		{
			"id": "piercing",
			"name": "Perfuracao",
			"description": "Projeteis atravessam +1 inimigo.",
		},
	]


func _update_hud() -> void:
	if is_instance_valid(hud):
		hud.call("set_wave_info", current_wave, _get_alive_enemy_count(), score)


func _get_alive_enemy_count() -> int:
	var alive_count := 0

	for enemy in enemies:
		if is_instance_valid(enemy):
			alive_count += 1

	return alive_count


func _on_player_died() -> void:
	if _is_restarting:
		return

	_is_restarting = true
	_wave_in_progress = false
	_reward_open = false
	if is_instance_valid(_auto_fire_timer):
		_auto_fire_timer.stop()
	if is_instance_valid(upgrade_panel):
		upgrade_panel.hide()
	if is_instance_valid(hud):
		hud.call("set_wave_message", "Reiniciando...")

	get_tree().create_timer(0.6).timeout.connect(_restart_scene)


func _restart_scene() -> void:
	get_tree().reload_current_scene()
