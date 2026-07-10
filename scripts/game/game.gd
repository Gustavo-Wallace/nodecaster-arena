extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const BASIC_CHASER_SCENE := preload("res://scenes/enemies/basic_chaser.tscn")
const BASIC_PROJECTILE_SCENE := preload("res://scenes/projectiles/basic_projectile.tscn")
const GAME_HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")

@export var arena_position: Vector2 = Vector2(96.0, 72.0)
@export var arena_size: Vector2 = Vector2(1088.0, 576.0)
@export var initial_enemy_count: int = 1
@export var auto_fire_interval: float = 0.45

var player: Node2D
var hud: Control
var enemies: Array[Node2D] = []
var arena_rect: Rect2
var _auto_fire_timer: Timer
var _is_restarting: bool = false


func _ready() -> void:
	arena_rect = Rect2(arena_position, arena_size)

	_spawn_player()
	_spawn_hud()
	_spawn_initial_enemies()
	_start_auto_fire()
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


func _spawn_initial_enemies() -> void:
	for index in range(initial_enemy_count):
		var spawn_offset := Vector2(0.0, float(index) * 44.0)
		var spawn_position := arena_rect.position + Vector2(arena_rect.size.x * 0.74, arena_rect.size.y * 0.5) + spawn_offset
		_spawn_enemy(spawn_position)


func _spawn_enemy(spawn_position: Vector2) -> void:
	var enemy := BASIC_CHASER_SCENE.instantiate() as Node2D
	add_child(enemy)
	enemy.global_position = spawn_position
	enemy.call("setup", player)
	enemy.connect("died", Callable(self, "_on_enemy_died"))
	enemies.append(enemy)


func _start_auto_fire() -> void:
	_auto_fire_timer = Timer.new()
	_auto_fire_timer.name = "AutoFireTimer"
	_auto_fire_timer.wait_time = auto_fire_interval
	_auto_fire_timer.autostart = true
	_auto_fire_timer.timeout.connect(_fire_at_nearest_enemy)
	add_child(_auto_fire_timer)


func _fire_at_nearest_enemy() -> void:
	if _is_restarting or not is_instance_valid(player):
		return

	var target := _get_nearest_enemy()
	if target == null:
		return

	var fire_direction := player.global_position.direction_to(target.global_position)
	if fire_direction == Vector2.ZERO:
		fire_direction = Vector2.RIGHT

	var projectile := BASIC_PROJECTILE_SCENE.instantiate() as Area2D
	add_child(projectile)
	projectile.call("setup", player.global_position + fire_direction * 30.0, target.global_position)


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


func _on_player_died() -> void:
	if _is_restarting:
		return

	_is_restarting = true
	get_tree().create_timer(0.6).timeout.connect(_restart_scene)


func _restart_scene() -> void:
	get_tree().reload_current_scene()
