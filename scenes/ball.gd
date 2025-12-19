extends RigidBody3D

@onready var ball_loop_sound: AudioStreamPlayer3D = $BallRollingSound
@onready var hit_wall_sound: AudioStreamPlayer3D = $BallHitWallSound

## How quickly the rolling sound volume will adjust.
@export var roll_vol_lerp_weight := 30.0

## At this speed and above, the rolling sound will be at max volume.
@export var max_speed := 2.0

## The minimum amount of speed required to play the rolling sound,
## Expressed as a fraction of `max_sound_speed`.
@export var min_sound_speed := 0.1

## The minimum impulse magnitude required to trigger a wall hit sound.
@export var wall_hit_impulse_threshold := 0.4

## Minimum time between wall hit sounds.
@export var wall_hit_cooldown_sec := 0.1

## The impulse magnitude that will result in full volume for wall hit sounds.
@export var wall_hit_full_volume_impulse := 2.0

## Scale factor for vertical component of wall hit impulses.
## This reduces the importance of floor hits in the wall hit sound logic.
@export var wall_hit_vertical_impulse_scale := 0.5

## true if the ball is currently rolling on the platform.
var is_rolling := false

## Cooldown timer for wall hit sounds.
var _wall_hit_cooldown_left := 0.0


func _ready() -> void:
    ball_loop_sound.volume_linear = 0.0


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    # Find strongest impulse against a wall *this physics step*
    var strongest := 0.0
    var count := state.get_contact_count()

    for i in range(count):
        var collider := state.get_contact_collider_object(i)
        if collider == null:
            continue
        if not collider.is_in_group("walls"):
            continue

        # This is a Vector3 impulse; magnitude correlates well with "hit strength"
        var impulse := state.get_contact_impulse(i)

        # Scale down vertical component to reduce floor hit importance
        impulse.y = impulse.y * wall_hit_vertical_impulse_scale

        var impulse_mag := impulse.length()
        strongest = maxf(strongest, impulse_mag)

    _update_collision_sound(strongest)


func _physics_process(delta: float) -> void:
    _wall_hit_cooldown_left = maxf(_wall_hit_cooldown_left - delta, 0.0)

    is_rolling = is_on_platform()
    _update_rolling_sound(delta)


func _update_collision_sound(strongest_impulse: float) -> void:
    if _wall_hit_cooldown_left > 0.0:
        return

    if strongest_impulse < wall_hit_impulse_threshold:
        return

    var vol := clampf(strongest_impulse / wall_hit_full_volume_impulse, 0.0, 1.0)
    hit_wall_sound.volume_linear = vol

    hit_wall_sound.play()

    _wall_hit_cooldown_left = wall_hit_cooldown_sec


func _update_rolling_sound(delta: float) -> void:
    var horizontal_velocity := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
    var speed := horizontal_velocity.length()

    var fraction_max_speed := clampf(speed / max_speed, 0.0, 1.0)
    var volume_target := remap(fraction_max_speed, min_sound_speed, 1.0, 0.0, 1.0)
    volume_target = clampf(volume_target, 0.0, 1.0)

    var w := clampf(delta * roll_vol_lerp_weight, 0.0, 1.0)
    ball_loop_sound.volume_linear = lerp(ball_loop_sound.volume_linear, volume_target, w)


    ball_loop_sound.stream_paused = not is_rolling


func is_on_platform() -> bool:
    for body in get_colliding_bodies():
        if body.is_in_group("platform"):
            return true
    return false
