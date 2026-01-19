extends Node3D

enum GameState {
    UNSET,
    NOT_STARTED,
    IN_PROGRESS,
    CELEBRATING,
    CHEATED_FINISH,
}

const FALL_Y_THRESHOLD := -1.0

@onready var ball: Ball = $Ball
@onready var fell_through_sound: AudioStreamPlayer3D = $FellThroughSound
@onready var win_sound: AudioStreamPlayer = $WinSound
@onready var post_finish_timer: Timer = $PostFinishTimer
@onready var confetti_spawner: ConfettiSpawner = $ConfettiSpawner
@onready var completion_time_label: Label = $Overlay/CompletionTimeLabel
@onready var cheated_label: Label = $Overlay/CheatedLabel
@onready var camera_rig: CameraRig = $CameraRig
@onready var title_screen: TitleScreen = $TitleScreen

@onready var waypoints: Array[Node] = $Platform/Waypoints.get_children()

var _game_state: GameState = GameState.UNSET
var _ball_start_pos: Vector3
var _fall_through_handled := false
var _run_time_elapsed := 0.0
var _fastest_run_time := INF
var _highest_waypoint_reached := -1

# Cached “payload” for the CELEBRATING state.
var _celebration_time := 0.0
var _celebration_is_new_record := false


func _ready() -> void:
    _ball_start_pos = ball.global_position

    for wp: Area3D in waypoints:
        wp.connect("waypoint_reached", _on_waypoint_reached)

    # Ensure initial state is applied consistently.
    _transition_to(GameState.NOT_STARTED)


func _input(event: InputEvent) -> void:
    if _game_state == GameState.NOT_STARTED:
        if C3Utils.is_any_key(event):
            _transition_to(GameState.IN_PROGRESS)
        return
    if event.is_action_pressed("debug_1"):
        if OS.is_debug_build():
            print("exploding confetti...")
            confetti_spawner.explode()

    if event.is_action_pressed("reset"):
        call_deferred("_reset_run")


func _process(delta: float) -> void:
    # Timer only runs during the active run.
    if _game_state == GameState.IN_PROGRESS:
        _run_time_elapsed += delta


func _physics_process(_delta: float) -> void:
    if ball.global_position.y < FALL_Y_THRESHOLD and not _fall_through_handled:
        _handle_ball_fall_through()


# -------------------------
# FSM core
# -------------------------

func _transition_to(new_state: GameState) -> void:
    if new_state == _game_state:
        return

    if OS.is_debug_build():
        var old_state_str: String = GameState.keys()[_game_state]
        var new_state_str: String = GameState.keys()[new_state]
        print("Transitioning from " + old_state_str + " to " + new_state_str)

    _on_state_exit(_game_state)
    _game_state = new_state
    _on_state_enter(_game_state)


func _on_state_enter(state: GameState) -> void:
    match state:
        GameState.NOT_STARTED:
            camera_rig.set_is_orbiting(true)
            ball.freeze = true

        GameState.IN_PROGRESS:
            _reset_run()

        GameState.CELEBRATING:
            _update_completion_time_label(_celebration_time, _celebration_is_new_record)
            post_finish_timer.start()

        GameState.CHEATED_FINISH:
            cheated_label.show()
            post_finish_timer.start()


func _on_state_exit(state: GameState) -> void:
    match state:
        GameState.NOT_STARTED:
            camera_rig.set_is_orbiting(false)
            ball.freeze = false
            title_screen.fade_away()

        GameState.IN_PROGRESS:
            pass

        GameState.CELEBRATING:
            pass

        GameState.CHEATED_FINISH:
            pass


# -------------------------
# Run lifecycle helpers
# -------------------------

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


func _handle_ball_fall_through() -> void:
    # This gets unset by `_reset_ball()`
    _fall_through_handled = true

    fell_through_sound.global_position = ball.global_position
    fell_through_sound.play()

    # Only reset immediately during active play.
    # In end states, let the post_finish_timer bring us back to IN_PROGRESS.
    if _game_state == GameState.IN_PROGRESS:
        _reset_run()


# -------------------------
# Events / signals
# -------------------------

func _on_win_zone_body_entered(body: Node3D) -> void:
    # Only allow finishing from active gameplay (prevents retriggering in end states).
    if _game_state != GameState.IN_PROGRESS:
        return
    if body != ball:
        return

    var did_complete_waypoints := _highest_waypoint_reached == waypoints.size() - 1
    if not did_complete_waypoints:
        _transition_to(GameState.CHEATED_FINISH)
        return

    # Compute record info before transitioning (payload for CELEBRATING).
    var completion_time := _run_time_elapsed
    var is_first_run := _fastest_run_time == INF
    var is_new_record := (completion_time < _fastest_run_time and not is_first_run)
    if is_new_record or is_first_run:
        _fastest_run_time = completion_time

    _celebration_time = completion_time
    _celebration_is_new_record = is_new_record

    win_sound.play()
    confetti_spawner.explode()

    _transition_to(GameState.CELEBRATING)


func _update_completion_time_label(completion_time: float, is_new_record: bool) -> void:
    var time_text := "Completion Time: %.2f seconds" % completion_time
    if is_new_record:
        time_text += "\nThat's a new record!"
    completion_time_label.text = time_text
    completion_time_label.show()


func _on_post_finish_timer_timeout() -> void:
    # End states always return to gameplay via the FSM.
    _transition_to(GameState.IN_PROGRESS)


func _on_waypoint_reached(wp_idx: int) -> void:
    var is_new_highest_waypoint := wp_idx == _highest_waypoint_reached + 1
    if not is_new_highest_waypoint:
        return
    _highest_waypoint_reached = wp_idx


func _on_title_screen_game_started() -> void:
    get_tree().paused = false
