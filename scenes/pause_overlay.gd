extends CanvasLayer

@onready var pause_menu: VBoxContainer = $PauseMenuVBoxContainer
@onready var settings_menu: VBoxContainer = $SettingsVBoxContainer
@onready var bg_panel: Panel = $BGPanel
@onready var fullscreen_check_button: CheckButton = $SettingsVBoxContainer/FullscreenCheckButton
@onready var ssao_check_button: CheckButton = $SettingsVBoxContainer/SSAOCheckButton
@onready var ssr_check_button: CheckButton = $SettingsVBoxContainer/SSRCheckButton
@onready var resume_button: Button = $PauseMenuVBoxContainer/ResumeButton

@export var is_fullscreen := false:
    get:
        return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    set(value):
        _set_fullscreen(value)
        fullscreen_check_button.set_pressed_no_signal(value)

var _current_overlay_mode: OverlayMode = OverlayMode.HIDDEN
var _world_env: WorldEnvironment

enum OverlayMode {
    HIDDEN,
    PAUSED,
    SETTINGS
}


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

    elif event.is_action_pressed("ui_cancel"):
        match _current_overlay_mode:
            OverlayMode.PAUSED:
                _set_overlay_mode(OverlayMode.HIDDEN)
            OverlayMode.SETTINGS:
                _set_overlay_mode(OverlayMode.PAUSED)


func _set_overlay_mode(mode: OverlayMode) -> void:
    _current_overlay_mode = mode
    match mode:
        OverlayMode.HIDDEN:
            bg_panel.hide()
            pause_menu.hide()
            settings_menu.hide()
            get_tree().paused = false
            return
        OverlayMode.PAUSED:
            bg_panel.show()
            pause_menu.show()
            settings_menu.hide()
            get_tree().paused = true
            resume_button.grab_focus()
            return
        OverlayMode.SETTINGS:
            bg_panel.show()
            pause_menu.hide()
            settings_menu.show()
            fullscreen_check_button.grab_focus()
            return


func _on_resume_button_pressed() -> void:
    _set_overlay_mode(OverlayMode.HIDDEN)


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


func _on_input_mode_changed(mode: InputModeManager.InputMode) -> void:
    print("Input mode changed: " + str(mode))
    var should_show_focus = mode == InputModeManager.InputMode.GAMEPAD
    var gp_focusable := get_tree().get_nodes_in_group("gamepad_focusable")
    for ctrl: Control in gp_focusable:
        if should_show_focus:
            ctrl.remove_theme_stylebox_override("focus")
        else:
            ctrl.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
