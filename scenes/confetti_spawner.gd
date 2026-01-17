class_name ConfettiSpawner
extends Node3D


## The number of confetti pieces spawned when the player wins
@export var confetti_spawn_count := 600

## Maximum confetti pieces to spawn per frame
@export var confetti_spawn_rate := 25

@onready var confetti_piece_scene: PackedScene = preload("res://scenes/confetti_piece.tscn")



func explode() -> void:
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
