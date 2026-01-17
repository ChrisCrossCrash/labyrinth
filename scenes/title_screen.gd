class_name TitleScreen
extends CanvasLayer

signal game_started

## A short timer to ignore space bar input after the game is started so that
## the game doesn't immediately zoom when the player presses the spacebar to
## start the game.
@onready var spacebar_ignore_timer: Timer = $SpacebarIgnoreTimer

var _has_started := false


func _ready() -> void:
    # The title screen must keep receiving input while the game is paused.
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED

    # If we want this timer to count down while paused, it must also run when paused.
    spacebar_ignore_timer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


## Call this from the main game to show title + pause the world.
func begin() -> void:
    _has_started = false
    show()
    get_tree().paused = true


func is_ignoring_spacebar() -> bool:
    return not spacebar_ignore_timer.is_stopped()


func _input(event: InputEvent) -> void:
    if _has_started:
        return

    if not _is_start_event(event):
        return

    _has_started = true

    # Prevent immediate zoom when starting with spacebar.
    spacebar_ignore_timer.start()

    hide()
    game_started.emit()


func _is_start_event(event: InputEvent) -> bool:
    # Keyboard
    if event is InputEventKey and event.pressed and not event.echo:
        return true

    # Mouse clicks (not motion / wheel)
    if event is InputEventMouseButton and event.pressed:
        return true

    # Gamepad buttons
    if event is InputEventJoypadButton and event.pressed:
        return true

    return false
