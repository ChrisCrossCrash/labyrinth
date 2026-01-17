class_name CameraRig
extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var ball: Ball = get_tree().get_first_node_in_group("ball")

var default_camera_pos: Vector3
var default_camera_basis: Basis
var default_camera_fov: float
var _smoothed_look_target: Vector3
var _zoom_t := 0.0
var _zoom_latched := false


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


func _ready() -> void:
    default_camera_pos = camera.global_position
    default_camera_basis = camera.global_basis
    default_camera_fov = camera.fov

    _smoothed_look_target = ball.global_position
    _smoothed_look_target.y = clamp(_smoothed_look_target.y, look_y_min, look_y_max)


func _process(delta: float) -> void:
    _update_camera_zoom(delta)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("zoom_toggle"):
        _zoom_latched = !_zoom_latched

    if event.is_action_pressed("reset"):
        call_deferred("_reset_run")


## Updates the camera's rotation and FOV based on zoom input, without changing camera position.
func _update_camera_zoom(delta: float) -> void:
    camera.global_position = default_camera_pos

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
        default_camera_pos
    ).looking_at(_smoothed_look_target, Vector3.UP).basis

    var desired_basis := default_camera_basis.slerp(zoomed_basis, _zoom_t)
    var desired_fov := lerpf(default_camera_fov, zoom_fov_deg, _zoom_t)

    var rw := 1.0 - exp(-follow_rot_smooth * delta)
    camera.global_basis = camera.global_basis.slerp(desired_basis, rw)
    camera.fov = desired_fov
