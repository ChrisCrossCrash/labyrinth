extends Node3D

const FALL_Y_THRESHOLD := -1.0

@onready var ball: RigidBody3D = $Ball
@onready var fell_through_sound: AudioStreamPlayer3D = $FellThroughSound
@onready var win_sound: AudioStreamPlayer = $WinSound
@onready var post_finish_timer: Timer = $PostFinishTimer
@onready var confetti_spawner: ConfettiSpawner = $ConfettiSpawner

@onready var completion_time_label: Label = $Overlay/CompletionTimeLabel
@onready var cheated_label: Label = $Overlay/CheatedLabel

@onready var waypoints: Array[Node] = $Platform/Waypoints.get_children()

var _ball_start_pos: Vector3
var _fall_through_handled := false
var _run_time_elapsed := 0.0
var _fastest_run_time := INF
var _highest_waypoint_reached := -1


func _ready() -> void:
    _ball_start_pos = ball.global_position

    for wp: Area3D in waypoints:
        wp.connect("waypoint_reached", _on_waypoint_reached)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_1"):
        if OS.is_debug_build():
            print("exploding confetti...")
            confetti_spawner.explode()


func _process(delta: float) -> void:
    _update_timer(delta)


func _update_timer(delta: float) -> void:
    _run_time_elapsed += delta


func _physics_process(_delta: float) -> void:
    if ball.global_position.y < FALL_Y_THRESHOLD and not _fall_through_handled:
        _handle_ball_fall_through()


func _handle_ball_fall_through() -> void:
    # This gets unset by `_reset_ball()`
    _fall_through_handled = true

    fell_through_sound.global_position = ball.global_position
    fell_through_sound.play()

    # Do not reset in a celebration period.
    # Let _on_celebration_timer_timeout() handle it.
    var is_post_finish = not post_finish_timer.is_stopped()
    if not is_post_finish:
        _reset_run()


func _reset_run() -> void:
    _reset_ball()
    _reset_timer()
    post_finish_timer.stop()
    completion_time_label.hide()
    cheated_label.hide()
    _highest_waypoint_reached = -1


## Resets the ball position and clears its linear and angular velocity.
func _reset_ball() -> void:
    ball.global_position = _ball_start_pos
    ball.linear_velocity = Vector3.ZERO
    ball.angular_velocity = Vector3.ZERO
    _fall_through_handled = false


func _reset_timer() -> void:
    _run_time_elapsed = 0.0


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

    win_sound.play()
    confetti_spawner.explode()

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


func _on_title_screen_game_started() -> void:
    get_tree().paused = false
