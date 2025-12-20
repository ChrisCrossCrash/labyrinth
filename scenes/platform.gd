extends Node3D

@export var angle_max_deg := 20.0
@export var tilt_rate := 2.0

@onready var platform := $FloorHoles
@onready var xpivot := $Shell_xpivot

func _process(delta: float) -> void:
    var input_joy := Input.get_vector("forward", "backward", "right", "left")
    var target_x_rad := deg_to_rad(input_joy.x * angle_max_deg)
    var target_y_rad := deg_to_rad(input_joy.y * angle_max_deg)
    var rotation_target := Vector3(target_x_rad, 0.0, target_y_rad)

    # Pivot the main platform along x and y
    platform.rotation = platform.rotation.lerp(rotation_target, tilt_rate * delta)

    # Pivot the x-pivot frame only along x
    xpivot.rotation = xpivot.rotation.lerp(rotation_target, tilt_rate * delta)
    xpivot.rotation.z = 0.0
