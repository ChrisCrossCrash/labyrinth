extends RigidBody3D

@onready var ball_loop_sound: AudioStreamPlayer3D = $BallRollingSound

## How quickly the rolling sound volume will adjust.
@export var roll_vol_lerp_weight = 30.0

## At this speed and above, the rolling sound will be at max volume.
@export var max_speed: float = 2.0

## The minimum amount of speed required to play the rolling sound,
## Expressed as a fraction of `max_sound_speed`.
@export var min_sound_speed = 0.1

## Returns true if the ball is currently rolling on the platform.
var is_rolling := false


func _ready() -> void:
    ball_loop_sound.volume_linear = 0.0


func _physics_process(delta: float) -> void:
    is_rolling = is_on_platform()
    _update_rolling_sound(delta)


func _update_rolling_sound(delta) -> void:
    # Get the horizontal velocity so that we can adjust the volume based on speed
    var horizontal_velocity := Vector3(linear_velocity.x, 0, linear_velocity.z)
    var speed := horizontal_velocity.length()
    var fraction_max_speed := clampf(speed / max_speed, 0.0, 1.0)
    var volume_target = remap(fraction_max_speed, min_sound_speed, 1.0, 0.0, 1.0)
    volume_target = clamp(volume_target, 0.0, 1.0)
    ball_loop_sound.volume_linear = lerp(
        ball_loop_sound.volume_linear,
        volume_target,
        delta * roll_vol_lerp_weight
    )

    if is_rolling and not ball_loop_sound.playing:
        ball_loop_sound.stream_paused = false
    elif not is_rolling and ball_loop_sound.playing:
        ball_loop_sound.stream_paused = true


func is_on_platform() -> bool:
    var colliding_bodies := get_colliding_bodies()
    for body in colliding_bodies:
        if body.is_in_group("platform"):
            return true
    return false
