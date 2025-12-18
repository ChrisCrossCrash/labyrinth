extends Node3D

@export var angle_max_deg := 20.0
@export var tilt_rate := 3.0

func _process(delta: float) -> void:
    var input_joy := Input.get_vector("forward", "backward", "right", "left")
    var target_x_rad := deg_to_rad(input_joy.x * angle_max_deg)
    var target_y_rad := deg_to_rad(input_joy.y * angle_max_deg)
    var rotation_target := Vector3(target_x_rad, 0.0, target_y_rad)
    rotation = rotation.lerp(rotation_target, 3.0 * delta)
