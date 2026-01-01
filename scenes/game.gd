extends Node3D

@onready var ball: RigidBody3D = $Ball
@onready var fell_through_sound: AudioStreamPlayer3D = $FellThroughSound
@onready var win_sound: AudioStreamPlayer = $WinSound
@onready var camera: Camera3D = $Camera3D
@onready var post_finish_timer: Timer = $PostFinishTimer
@onready var completion_time_label: Label = $Overlay/CompletionTimeLabel
@onready var cheated_label: Label = $Overlay/CheatedLabel
@onready var waypoints := $Platform/Waypoints.get_children()
@onready var confetti_piece_scene = preload("res://scenes/confetti_piece.tscn")

var _ball_start_pos: Vector3
var _default_camera_pos: Vector3
var _default_camera_basis: Basis
var _default_camera_fov: float
var _fall_through_handled: bool = false
var _run_time_elapsed := 0.0
var _fastest_run_time := INF
var _highest_waypoint_reached := -1

## Target camera field-of-view (degrees) when fully zoomed.
@export var zoom_fov_deg := 10.0

## How quickly the zoom blend reacts to changes in zoom input (higher = snappier).
@export var zoom_strength_smooth := 5.0

## How quickly the camera rotates toward its target rotation (higher = snappier).
@export var follow_rot_smooth := 50.0

## How quickly the followed target position is smoothed (higher = snappier).
@export var look_target_smooth := 10.0

## Minimum Y value for the followed target position (world-space).
@export var look_y_min := -0.5

## Maximum Y value for the followed target position (world-space).
@export var look_y_max := 0.5

## The number of confetti pieces spawned when the player wins
@export var confetti_spawn_count := 600

# Maximum confetti pieces to spawn per frame
@export var confetti_spawn_rate := 25

var _zoom_t := 0.0
var _zoom_latched := false
var _smoothed_look_target: Vector3


func _ready() -> void:
    _ball_start_pos = ball.global_position

    _default_camera_pos = camera.global_position
    _default_camera_basis = camera.global_basis
    _default_camera_fov = camera.fov

    _smoothed_look_target = ball.global_position
    _smoothed_look_target.y = clamp(_smoothed_look_target.y, look_y_min, look_y_max)

    for wp: Area3D in waypoints:
        wp.connect("waypoint_reached", _on_waypoint_reached)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("zoom_toggle"):
        _zoom_latched = !_zoom_latched

    if event.is_action_pressed("reset"):
        call_deferred("_reset_run")

    if event.is_action_pressed("debug_1"):
        if OS.is_debug_build():
            _explode_confetti()


func _process(delta: float) -> void:
    _update_camera_zoom(delta)
    _update_timer(delta)


func _update_timer(delta: float) -> void:
    _run_time_elapsed += delta


func _reset_timer() -> void:
    _run_time_elapsed = 0.0


## Updates the camera's rotation and FOV based on zoom input, without changing camera position.
func _update_camera_zoom(delta: float) -> void:
    camera.global_position = _default_camera_pos

    var zoom_strength := Input.get_action_strength("zoom")
    var zoom_target := 1.0 if _zoom_latched else zoom_strength

    var zw := 1.0 - exp(-zoom_strength_smooth * delta)
    _zoom_t = lerp(_zoom_t, zoom_target, zw)

    var raw_target := ball.global_position
    raw_target.y = clamp(raw_target.y, look_y_min, look_y_max)

    var tw := 1.0 - exp(-look_target_smooth * delta)
    _smoothed_look_target = _smoothed_look_target.lerp(raw_target, tw)

    var zoomed_basis := Transform3D(
        camera.global_basis,
        _default_camera_pos
    ).looking_at(_smoothed_look_target, Vector3.UP).basis

    var desired_basis := _default_camera_basis.slerp(zoomed_basis, _zoom_t)
    var desired_fov := lerpf(_default_camera_fov, zoom_fov_deg, _zoom_t)

    var rw := 1.0 - exp(-follow_rot_smooth * delta)
    camera.global_basis = camera.global_basis.slerp(desired_basis, rw)
    camera.fov = desired_fov


func _physics_process(_delta: float) -> void:
    if ball.global_position.y < -1.0 and not _fall_through_handled:
        _handle_ball_fall_through()


func _handle_ball_fall_through() -> void:
    # This get's unset by `_reset_ball()`
    _fall_through_handled = true

    fell_through_sound.global_position = ball.global_position
    fell_through_sound.play()

    # Do not reset in a celebration period.
    # Let _on_celebration_timer_timeout() handle it.
    var is_post_finish = not post_finish_timer.is_stopped()
    if not is_post_finish:
        _reset_run()

## Resets the ball position and clears its linear and angular velocity.
func _reset_ball() -> void:
    ball.global_position = _ball_start_pos
    ball.linear_velocity = Vector3.ZERO
    ball.angular_velocity = Vector3.ZERO
    _fall_through_handled = false


func _reset_run() -> void:
    _reset_ball()
    _reset_timer()
    completion_time_label.hide()
    cheated_label.hide()
    _highest_waypoint_reached = -1


func _explode_confetti() -> void:
    win_sound.play()
    _spawn_confetti_staggered(confetti_spawn_count)

func _spawn_confetti_staggered(total_count: int) -> void:
    var spawned := 0

    while spawned < total_count:
        var batch := mini(confetti_spawn_rate, total_count - spawned)

        for _i in range(batch):
            _spawn_one_confetti_piece()
            spawned += 1

        # Let the engine render/step a frame before continuing.
        await get_tree().process_frame


func _spawn_one_confetti_piece() -> void:
    var piece := confetti_piece_scene.instantiate() as RigidBody3D
    add_child(piece)

    var pos_init := Vector3(0.8, 2.0, 0.0)
    var pos_rand_offset_amt := 0.2
    var pos_rand_offset := Vector3(
        randfn(0.0, pos_rand_offset_amt),
        randfn(0.0, pos_rand_offset_amt),
        randfn(0.0, pos_rand_offset_amt)
    )

    piece.global_position = pos_init + pos_rand_offset

    var rand_rotation := Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
    piece.rotation = rand_rotation

    var vel_avg_init := Vector3(-1.5, -2.0, 0.0)
    var vel_rand_offset_amt := 1.5
    var vel_rand_offset := Vector3(
        randfn(0.0, vel_rand_offset_amt),
        randfn(0.0, vel_rand_offset_amt),
        randfn(0.0, vel_rand_offset_amt)
    )
    piece.linear_velocity = vel_avg_init + vel_rand_offset

    var rand_ang_vel_amt := 5.0
    var rand_ang_vel := Vector3(
        randfn(0.0, rand_ang_vel_amt),
        randfn(0.0, rand_ang_vel_amt),
        randfn(0.0, rand_ang_vel_amt)
    )
    piece.angular_velocity = rand_ang_vel


func _on_win_zone_body_entered(body: Node3D) -> void:
    var just_finished := body == ball and post_finish_timer.is_stopped()
    if not just_finished:
        return

    var did_complete_waypoints := _highest_waypoint_reached == waypoints.size() - 1
    if not did_complete_waypoints:
        cheated_label.show()
        post_finish_timer.start()
        return

    var completion_time := _run_time_elapsed
    var is_first_run := _fastest_run_time == INF
    var is_new_record := (
        completion_time < _fastest_run_time
        and not is_first_run
    )
    if is_new_record or is_first_run:
        _fastest_run_time = completion_time
    _update_completion_time_label(completion_time, is_new_record)

    _explode_confetti()
    post_finish_timer.start()


func _update_completion_time_label(completion_time: float, is_new_record: bool) -> void:
    var time_text := "Completion Time: %.2f seconds" % completion_time
    if is_new_record:
        time_text += "\nThat's a new record!"
    completion_time_label.text = time_text
    completion_time_label.show()


func _on_post_finish_timer_timeout() -> void:
    _reset_run()


func _on_waypoint_reached(wp_idx: int) -> void:
    var is_new_highest_waypoint := wp_idx == _highest_waypoint_reached + 1
    if not is_new_highest_waypoint:
        return
    _highest_waypoint_reached = wp_idx
