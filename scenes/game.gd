extends Node3D

@onready var ball := $Ball
@onready var fell_through_sound := $FellThroughSound

var ball_start_pos: Vector3


func _ready() -> void:
    ball_start_pos = ball.global_position


func _physics_process(_delta: float) -> void:
    if ball.global_position.y < -1.0:
        fell_through_sound.global_position = ball.global_position
        fell_through_sound.play()
        _reset_ball()


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("reset"):
        call_deferred("_reset_ball")

    if event.is_action_pressed("exit"):
        get_tree().quit()


func _reset_ball() -> void:
    ball.global_position = ball_start_pos
    ball.linear_velocity = Vector3.ZERO
    ball.angular_velocity = Vector3.ZERO
