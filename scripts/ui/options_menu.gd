extends Control

@onready var master_value_label: Label = $Panel/MasterValueLabel
@onready var master_slider: HSlider = $Panel/MasterSlider
@onready var sfx_value_label: Label = $Panel/SfxValueLabel
@onready var sfx_slider: HSlider = $Panel/SfxSlider
@onready var fullscreen_check: CheckButton = $Panel/FullscreenCheck
@onready var reset_button: Button = $Panel/ResetButton
@onready var back_button: Button = $Panel/BackButton
@onready var confirmation_panel: Panel = $ConfirmationPanel
@onready var confirm_reset_button: Button = $ConfirmationPanel/ConfirmResetButton
@onready var cancel_reset_button: Button = $ConfirmationPanel/CancelResetButton
@onready var status_label: Label = $Panel/StatusLabel

var _loading_values := false


func _ready() -> void:
	master_slider.value_changed.connect(_on_master_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	confirm_reset_button.pressed.connect(_on_confirm_reset_pressed)
	cancel_reset_button.pressed.connect(_on_cancel_reset_pressed)

	for button in [reset_button, back_button, confirm_reset_button, cancel_reset_button]:
		_setup_button_feedback(button)

	confirmation_panel.hide()
	_load_current_settings()


func _load_current_settings() -> void:
	_loading_values = true
	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager != null:
		master_slider.value = float(settings_manager.call("get_master_volume")) * 100.0
		sfx_slider.value = float(settings_manager.call("get_sfx_volume")) * 100.0
		fullscreen_check.button_pressed = bool(settings_manager.call("is_fullscreen_enabled"))
	else:
		master_slider.value = 100.0
		sfx_slider.value = 100.0
		fullscreen_check.button_pressed = false

	_update_volume_labels()
	status_label.text = ""
	_loading_values = false


func _on_master_volume_changed(value: float) -> void:
	_update_volume_labels()
	if _loading_values:
		return

	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager != null:
		settings_manager.call("set_master_volume", value / 100.0)


func _on_sfx_volume_changed(value: float) -> void:
	_update_volume_labels()
	if _loading_values:
		return

	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager != null:
		settings_manager.call("set_sfx_volume", value / 100.0)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if _loading_values:
		return

	_play_audio("play_button_click")
	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager != null:
		settings_manager.call("set_fullscreen_enabled", enabled)
		if enabled and settings_manager.has_method("can_apply_fullscreen") and not bool(settings_manager.call("can_apply_fullscreen")):
			status_label.text = "Fullscreen will apply outside the embedded editor window."
			return
	status_label.text = "Fullscreen enabled." if enabled else "Windowed mode enabled."


func _on_reset_pressed() -> void:
	_play_audio("play_button_click")
	confirmation_panel.show()
	status_label.text = ""


func _on_confirm_reset_pressed() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.call("reset_progress")

	var run_config := get_node_or_null("/root/RunConfig")
	if run_config != null:
		run_config.set("selected_character_id", "circle")

	confirmation_panel.hide()
	status_label.text = "Progress reset."
	_play_audio("play_unlock")


func _on_cancel_reset_pressed() -> void:
	confirmation_panel.hide()
	status_label.text = "Reset cancelled."
	_play_audio("play_error")


func _on_back_pressed() -> void:
	_play_audio("play_button_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _update_volume_labels() -> void:
	master_value_label.text = "%d%%" % int(round(master_slider.value))
	sfx_value_label.text = "%d%%" % int(round(sfx_slider.value))


func _setup_button_feedback(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_entered.connect(_on_button_hovered.bind(button, true))
	button.mouse_exited.connect(_on_button_hovered.bind(button, false))


func _on_button_hovered(button: Button, hovered: bool) -> void:
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * (1.04 if hovered else 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method(method_name):
		audio_manager.call(method_name)
