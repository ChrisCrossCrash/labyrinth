extends CanvasLayer

enum OverlayMode { HIDDEN, PAUSED, SETTINGS, CONTROLS }

@export var is_fullscreen := false:
    get:
        return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    set(value):
        _set_fullscreen(value)
        fullscreen_check_button.set_pressed_no_signal(value)

@onready var pause_menu: VBoxContainer = $PauseMenuVBoxContainer
@onready var settings_menu: VBoxContainer = $SettingsVBoxContainer
@onready var controls_overlay: Control = $ControlsOverlay
@onready var km_controls_overlay: VBoxContainer = $ControlsOverlay/MKControlsVBoxContainer
@onready var gamepad_controls_overlay: VBoxContainer = $ControlsOverlay/GamepadControlsVBoxContainer
@onready var bg_panel: Panel = $BGPanel
@onready var fullscreen_check_button: CheckButton = $SettingsVBoxContainer/FullscreenCheckButton
@onready var ssao_check_button: CheckButton = $SettingsVBoxContainer/SSAOCheckButton
@onready var ssr_check_button: CheckButton = $SettingsVBoxContainer/SSRCheckButton
@onready var resume_button: Button = $PauseMenuVBoxContainer/ResumeButton

var _current_overlay_mode: OverlayMode = OverlayMode.HIDDEN
var _world_env: WorldEnvironment


func _ready() -> void:
    _set_overlay_mode(OverlayMode.HIDDEN)
    _world_env = get_tree().get_first_node_in_group("world_environment")
    ssao_check_button.set_pressed_no_signal(_world_env.environment.ssao_enabled)
    ssr_check_button.set_pressed_no_signal(_world_env.environment.ssr_enabled)
    fullscreen_check_button.set_pressed_no_signal(is_fullscreen)
    InputModeManager.input_mode_changed.connect(_on_input_mode_changed)
    _on_input_mode_changed(InputModeManager.current_mode)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        match _current_overlay_mode:
            OverlayMode.HIDDEN:
                _set_overlay_mode(OverlayMode.PAUSED)
            OverlayMode.PAUSED:
                _set_overlay_mode(OverlayMode.HIDDEN)
            OverlayMode.SETTINGS:
                _set_overlay_mode(OverlayMode.PAUSED)
            OverlayMode.CONTROLS:
                _set_overlay_mode(OverlayMode.PAUSED)

    elif event.is_action_pressed("ui_cancel"):
        match _current_overlay_mode:
            OverlayMode.PAUSED:
                _set_overlay_mode(OverlayMode.HIDDEN)
            OverlayMode.SETTINGS:
                _set_overlay_mode(OverlayMode.PAUSED)
            OverlayMode.CONTROLS:
                _set_overlay_mode(OverlayMode.PAUSED)


func _set_overlay_mode(mode: OverlayMode) -> void:
    _current_overlay_mode = mode
    match mode:
        OverlayMode.HIDDEN:
            bg_panel.hide()
            pause_menu.hide()
            get_tree().paused = false
            return
        OverlayMode.PAUSED:
            bg_panel.show()
            pause_menu.show()
            settings_menu.hide()
            controls_overlay.hide()
            get_tree().paused = true
            resume_button.grab_focus()
            return
        OverlayMode.SETTINGS:
            pause_menu.hide()
            settings_menu.show()
            fullscreen_check_button.grab_focus()
            return
        OverlayMode.CONTROLS:
            pause_menu.hide()
            controls_overlay.show()
            return


func _set_fullscreen(wants_fullscreen: bool) -> void:
    # We have to disable input monitoring before switching to fullscreen,
    # and then re-enable it after because otherwise the mouse's new position
    # on the game window will count as an input.
    InputModeManager.is_monitoring = false
    await get_tree().process_frame
    if wants_fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    await get_tree().process_frame
    InputModeManager.is_monitoring = true


## Sets whether or not the focus will be shown on the pause screen menu,
## based on the input mode.
func _calculate_focus_mode(input_mode: InputModeManager.InputMode) -> void:
    var should_show_focus = input_mode == InputModeManager.InputMode.GAMEPAD
    var gp_focusable := get_tree().get_nodes_in_group("gamepad_focusable")
    for ctrl: Control in gp_focusable:
        if should_show_focus:
            ctrl.remove_theme_stylebox_override("focus")
        else:
            ctrl.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Sets which control scheme is shown, based on the input mode.
func _show_control_scheme(input_mode: InputModeManager.InputMode) -> void:
    if input_mode == InputModeManager.InputMode.MOUSE_KEYBOARD:
        gamepad_controls_overlay.hide()
        km_controls_overlay.show()
    else:
        km_controls_overlay.hide()
        gamepad_controls_overlay.show()


func _on_resume_button_pressed() -> void:
    _set_overlay_mode(OverlayMode.HIDDEN)


func _on_controls_button_pressed() -> void:
    _set_overlay_mode(OverlayMode.CONTROLS)


func _on_settings_button_pressed() -> void:
    _set_overlay_mode(OverlayMode.SETTINGS)


func _on_quit_button_pressed() -> void:
    get_tree().quit()


func _on_ssao_check_button_toggled(toggled_on: bool) -> void:
    _world_env.environment.ssao_enabled = toggled_on


func _on_ssr_check_button_toggled(toggled_on: bool) -> void:
    _world_env.environment.ssr_enabled = toggled_on


func _on_fullscreen_check_button_toggled(toggled_on: bool) -> void:
    _set_fullscreen(toggled_on)


func _on_input_mode_changed(input_mode: InputModeManager.InputMode) -> void:
    _calculate_focus_mode(input_mode)
    _show_control_scheme(input_mode)
