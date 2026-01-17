class_name CameraRig
extends Node3D

## The camera controlled by this rig.
##
## All position, rotation, and FOV changes are applied to this camera while
## the rig itself remains at the world origin.
@onready var camera: Camera3D = $Camera3D

## Reference to the player-controlled ball.
##
## Used as the primary look-at target during normal gameplay camera behavior.
@onready var ball: Ball = get_tree().get_first_node_in_group("ball")

## Camera position at startup, in global space.
##
## Used as the baseline when restoring the camera from orbit or zoom states.
var default_camera_pos: Vector3

## Camera orientation at startup, in global space.
##
## Represents the neutral viewing direction before any zoom or orbit blending.
var default_camera_basis: Basis

## Camera field-of-view at startup (degrees).
##
## Used as the default FOV when zoom is inactive.
var default_camera_fov: float

## Smoothed world-space point the camera should look at.
##
## Tracks the ball position with temporal smoothing and vertical clamping
## to prevent jitter and extreme pitch angles.
var _smoothed_look_target: Vector3

## Continuous zoom blend factor in the range [0, 1].
##
## 0.0 represents the default camera view, while 1.0 represents a fully
## zoomed-in view.
var _zoom_t := 0.0

## Whether zoom is currently latched on.
##
## When latched, the camera remains zoomed even after the zoom input
## is released.
var _zoom_latched := false

## Target camera field-of-view (degrees) when fully zoomed.
##
## Lower values result in a tighter, more telephoto-like zoom.
@export var zoom_fov_deg := 10.0

## Responsiveness of the zoom blend.
##
## Higher values cause zoom to react more quickly to input changes.
@export var zoom_strength_smooth := 5.0

## Responsiveness of camera rotation when following its target.
##
## Higher values make the camera orientation converge more aggressively.
@export var follow_rot_smooth := 50.0

## Responsiveness of the smoothed look-at target.
##
## Higher values reduce lag when tracking the ball but may feel less stable.
@export var look_target_smooth := 10.0

## Minimum allowed Y value for the look-at target (world-space).
##
## Prevents the camera from pitching too far downward.
@export var look_y_min := -0.5

## Maximum allowed Y value for the look-at target (world-space).
##
## Prevents the camera from pitching too far upward.
@export var look_y_max := 0.5

## Angular speed of the orbit motion (radians per second).
##
## Controls how fast the camera rig rotates around the platform while orbiting.
@export var orbit_speed := 0.2

## --- Orbit pose tuning ---

## Local-space camera offset used during orbit mode.
##
## This offset is transformed by the rotating rig to produce a circular
## orbit around the platform.
@export var orbit_local_offset := Vector3(0.0, 2.0, 1.0)

## World-space point the orbiting camera should look at.
##
## Typically the center of the platform or playfield.
@export var orbit_look_target := Vector3.ZERO

## Camera field-of-view (degrees) used during orbit mode.
##
## Often wider than the gameplay FOV to create a cinematic presentation.
@export var orbit_fov_deg := 45.0

## Responsiveness of blending into and out of orbit mode.
##
## Higher values result in faster, snappier transitions.
@export var orbit_blend_smooth := 4.0

## Whether the camera is currently in orbit mode.
##
## Orbit mode causes the rig to rotate and the camera to blend toward
## a cinematic orbit pose.
var _is_orbiting := false

## Continuous blend factor between gameplay and orbit camera poses.
##
## 0.0 represents normal gameplay camera behavior, while 1.0 represents
## full orbit mode.
var _orbit_t := 0.0


func _ready() -> void:
    default_camera_pos = camera.global_position
    default_camera_basis = camera.global_basis
    default_camera_fov = camera.fov

    _smoothed_look_target = ball.global_position
    _smoothed_look_target.y = clamp(_smoothed_look_target.y, look_y_min, look_y_max)


func _unhandled_input(event: InputEvent) -> void:
    if OS.is_debug_build() and event.is_action_pressed("debug_2"):
        set_is_orbiting(not _is_orbiting)


func _process(delta: float) -> void:
    # Blend between "normal" and "orbit" every frame.
    var orbit_target_t := 1.0 if _is_orbiting else 0.0
    var ow := 1.0 - exp(-orbit_blend_smooth * delta)
    _orbit_t = lerp(_orbit_t, orbit_target_t, ow)

    # Advance orbit motion even while blending in/out so it feels alive.
    if _orbit_t > 0.001:
        _orbit(delta)

    _update_camera_pose(delta)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("zoom_toggle"):
        _zoom_latched = !_zoom_latched

    if event.is_action_pressed("reset"):
        call_deferred("_reset_run")


## Enables or disables orbiting mode.
##
## Orbiting mode causes the camera rig to rotate around the platform while
## blending the camera toward a cinematic orbit pose. Disabling orbiting
## smoothly restores the default camera configuration.
func set_is_orbiting(new_is_orbiting: bool) -> void:
    _is_orbiting = new_is_orbiting

    # Small QoL: unlatch and relax zoom when entering orbit so it doesn't "stick".
    if _is_orbiting:
        _zoom_latched = false


## Rotates the camera rig around the Y axis.
##
## This provides the actual orbital motion. The camera's pose is blended
## separately so orbiting can fade in and out smoothly.
func _orbit(delta: float) -> void:
    rotate_y(delta * orbit_speed)


## Computes and applies the final camera pose for the current frame.
##
## Blends between the normal gameplay camera (with optional zoom) and the
## orbit camera pose, then smoothly applies position, rotation, and FOV
## to the camera.
func _update_camera_pose(delta: float) -> void:
    # --- A) Normal/zoom target pose ---
    var normal_target_pos := default_camera_pos
    var normal_target_basis := _compute_zoom_target_basis(delta)
    var normal_target_fov := lerpf(default_camera_fov, zoom_fov_deg, _zoom_t)

    # --- B) Orbit target pose ---
    # Orbit position comes from a fixed local offset on the child camera.
    # Because the rig is rotating, camera.global_position will move around the target.
    var orbit_target_pos := global_transform * orbit_local_offset
    var orbit_target_basis := Transform3D(Basis.IDENTITY, orbit_target_pos)\
        .looking_at(orbit_look_target, Vector3.UP).basis
    var orbit_target_fov := orbit_fov_deg

    # --- Blend A <-> B ---
    var blended_pos := normal_target_pos.lerp(orbit_target_pos, _orbit_t)
    var blended_basis := normal_target_basis.slerp(orbit_target_basis, _orbit_t)
    var blended_fov := lerpf(normal_target_fov, orbit_target_fov, _orbit_t)

    # --- Smooth final application (keeps your existing "snappy" feel) ---
    var rw := 1.0 - exp(-follow_rot_smooth * delta)
    camera.global_position = blended_pos
    camera.global_basis = camera.global_basis.slerp(blended_basis, rw)
    camera.fov = blended_fov


## Computes the desired camera orientation during normal gameplay.
##
## Smoothly tracks the ball while respecting vertical clamping and zoom
## state. Returns a target basis without directly mutating the camera.
func _compute_zoom_target_basis(delta: float) -> Basis:
    # Update zoom blend (_zoom_t)
    var zoom_strength := Input.get_action_strength("zoom")
    var zoom_target := 1.0 if _zoom_latched else zoom_strength
    var zw := 1.0 - exp(-zoom_strength_smooth * delta)
    _zoom_t = lerp(_zoom_t, zoom_target, zw)

    # Smooth the look target
    var raw_target := ball.global_position
    raw_target.y = clamp(raw_target.y, look_y_min, look_y_max)

    var tw := 1.0 - exp(-look_target_smooth * delta)
    _smoothed_look_target = _smoothed_look_target.lerp(raw_target, tw)

    # Basis looking at target from the default camera position
    var zoomed_basis := Transform3D(
        default_camera_basis, # basis doesn't matter much here; position does
        default_camera_pos
    ).looking_at(_smoothed_look_target, Vector3.UP).basis

    # Blend default orientation toward "look at ball" orientation by _zoom_t
    return default_camera_basis.slerp(zoomed_basis, _zoom_t)
