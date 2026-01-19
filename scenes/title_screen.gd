class_name TitleScreen
extends CanvasLayer

@export var fade_duration := 0.5

@onready var fade_items: Control = $FadeItems

## Fades the title screen away when the game starts.
func fade_away() -> void:
    var tween := create_tween()
    tween.tween_property(fade_items, "modulate:a", 0.0, fade_duration)
    tween.finished.connect(hide)
