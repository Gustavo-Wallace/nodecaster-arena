extends Control

signal resume_requested
signal restart_requested
signal main_menu_requested

@onready var pause_panel: Panel = $PausePanel
@onready var resume_button: Button = $PausePanel/ResumeButton
@onready var options_button: Button = $PausePanel/OptionsButton
@onready var restart_button: Button = $PausePanel/RestartButton
@onready var main_menu_button: Button = $PausePanel/MainMenuButton
@onready var status_label: Label = $PausePanel/StatusLabel
@onready var options_panel: Panel = $OptionsPanel
@onready var master_slider: HSlider = $OptionsPanel/MasterSlider
@onready var master_value_label: Label = $OptionsPanel/MasterValueLabel
@onready var sfx_slider: HSlider = $OptionsPanel/SfxSlider
@onready var sfx_value_label: Label = $OptionsPanel/SfxValueLabel
@onready var fullscreen_check: CheckButton = $OptionsPanel/FullscreenCheck
@onready var options_status_label: Label = $OptionsPanel/StatusLabel
@onready var options_back_button: Button = $OptionsPanel/BackButton

var _pending_action: String = ""
var _loading_settings := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	options_panel.hide()
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	master_slider.value_changed.connect(_on_master_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	options_back_button.pressed.connect(_close_options)

	for button in [resume_button, options_button, restart_button, main_menu_button, options_back_button]:
		button.focus_mode = Control.FOCUS_NONE


func open_menu() -> void:
	_pending_action = ""
	status_label.text = ""
	restart_button.text = "Restart Run"
	main_menu_button.text = "Main Menu"
	pause_panel.show()
	options_panel.hide()
	show()


func close_menu() -> void:
	_pending_action = ""
	hide()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
		return

	if options_panel.visible:
		_close_options()
	else:
		resume_requested.emit()
	get_viewport().set_input_as_handled()


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_options_pressed() -> void:
	_pending_action = ""
	_load_settings()
	pause_panel.hide()
	options_panel.show()


func _close_options() -> void:
	options_panel.hide()
	pause_panel.show()


func _on_restart_pressed() -> void:
	if _pending_action == "restart":
		restart_requested.emit()
		return

	_pending_action = "restart"
	status_label.text = "Press Restart Run again to confirm."
	restart_button.text = "Confirm Restart"
	main_menu_button.text = "Main Menu"


func _on_main_menu_pressed() -> void:
	if _pending_action == "main_menu":
		main_menu_requested.emit()
		return

	_pending_action = "main_menu"
	status_label.text = "Press Main Menu again to confirm."
	main_menu_button.text = "Confirm Main Menu"
	restart_button.text = "Restart Run"


func _load_settings() -> void:
	_loading_settings = true
	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager != null:
		master_slider.value = float(settings_manager.call("get_master_volume")) * 100.0
		sfx_slider.value = float(settings_manager.call("get_sfx_volume")) * 100.0
		fullscreen_check.button_pressed = bool(settings_manager.call("is_fullscreen_enabled"))
	_update_volume_labels()
	options_status_label.text = ""
	_loading_settings = false


func _on_master_volume_changed(value: float) -> void:
	_update_volume_labels()
	if not _loading_settings:
		_set_setting("set_master_volume", value / 100.0)


func _on_sfx_volume_changed(value: float) -> void:
	_update_volume_labels()
	if not _loading_settings:
		_set_setting("set_sfx_volume", value / 100.0)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if _loading_settings:
		return

	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager == null:
		return

	settings_manager.call("set_fullscreen_enabled", enabled)
	if enabled and settings_manager.has_method("can_apply_fullscreen") and not bool(settings_manager.call("can_apply_fullscreen")):
		options_status_label.text = "Fullscreen will apply outside the embedded editor window."
	else:
		options_status_label.text = "Fullscreen enabled." if enabled else "Windowed mode enabled."


func _set_setting(method_name: String, value: float) -> void:
	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager != null and settings_manager.has_method(method_name):
		settings_manager.call(method_name, value)


func _update_volume_labels() -> void:
	master_value_label.text = "%d%%" % int(round(master_slider.value))
	sfx_value_label.text = "%d%%" % int(round(sfx_slider.value))
