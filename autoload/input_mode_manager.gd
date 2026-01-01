extends Node

enum InputMode {
    MOUSE_KEYBOARD,
    GAMEPAD
}

const MOUSE_MOTION_THRESHOLD := 8.0 ## Pixels
const JOY_AXIS_DEADZONE := 0.3 ## 0-1

signal input_mode_changed(new_mode: InputMode)

var current_mode: InputMode = InputMode.MOUSE_KEYBOARD
var is_monitoring := true


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
    if not is_monitoring:
        return
    var new_mode := current_mode

    # GAMEPAD
    if event is InputEventJoypadButton:
        new_mode = InputMode.GAMEPAD
    elif event is InputEventJoypadMotion:
        if abs(event.axis_value) >= JOY_AXIS_DEADZONE:
            new_mode = InputMode.GAMEPAD

    # MOUSE
    elif event is InputEventMouseButton and event.is_pressed():
        new_mode = InputMode.MOUSE_KEYBOARD
    elif event is InputEventMouseMotion:
        if event.relative.length() >= MOUSE_MOTION_THRESHOLD:
            new_mode = InputMode.MOUSE_KEYBOARD

    # KEYBOARD
    elif event is InputEventKey and event.is_pressed():
        new_mode = InputMode.MOUSE_KEYBOARD

    if new_mode != current_mode:
        current_mode = new_mode
        input_mode_changed.emit(current_mode)
