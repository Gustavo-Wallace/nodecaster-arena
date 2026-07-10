extends Node

const SETTINGS_PATH := "user://nodecaster_arena_settings.cfg"
const DEFAULT_WINDOW_SIZE := Vector2i(1280, 720)

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var fullscreen_enabled: bool = false


func _ready() -> void:
	load_settings()
	apply_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK:
		save_settings()
		return

	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen_enabled = bool(config.get_value("display", "fullscreen_enabled", fullscreen_enabled))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen_enabled", fullscreen_enabled)
	config.save(SETTINGS_PATH)


func apply_settings() -> void:
	call_deferred("_apply_fullscreen")
	_apply_audio()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	save_settings()


func set_fullscreen_enabled(enabled: bool) -> void:
	fullscreen_enabled = enabled
	call_deferred("_apply_fullscreen")
	save_settings()


func get_master_volume() -> float:
	return master_volume


func get_sfx_volume() -> float:
	return sfx_volume


func is_fullscreen_enabled() -> bool:
	return fullscreen_enabled


func can_apply_fullscreen() -> bool:
	return not OS.has_feature("editor")


func _apply_audio() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return

	if audio_manager.has_method("set_master_volume"):
		audio_manager.call("set_master_volume", master_volume)
	if audio_manager.has_method("set_sfx_volume"):
		audio_manager.call("set_sfx_volume", sfx_volume)


func _apply_fullscreen() -> void:
	if not can_apply_fullscreen():
		return

	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_restore_windowed_size()


func _restore_windowed_size() -> void:
	var width := int(ProjectSettings.get_setting("display/window/size/viewport_width", DEFAULT_WINDOW_SIZE.x))
	var height := int(ProjectSettings.get_setting("display/window/size/viewport_height", DEFAULT_WINDOW_SIZE.y))
	var window_size := Vector2i(width, height)
	DisplayServer.window_set_size(window_size)

	var screen := DisplayServer.window_get_current_screen()
	var screen_position := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	DisplayServer.window_set_position(screen_position + (screen_size - window_size) / 2)
