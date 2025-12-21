extends RigidBody3D

@export var time_to_live := 4.0
@export var ttl_std_dev := 0.5
@export var fade_duration := 0.2

var time_alive := 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D

var _colors: Array[Color] = [
    Color("#006ba6"),
    Color("#0496ff"),
    Color("#ffbc42"),
    Color("#d81159"),
    Color("#8f2d56"),
]

var _mat: StandardMaterial3D
var _base_color: Color


func _ready() -> void:
    time_to_live += randfn(0.0, ttl_std_dev)

    _base_color = _colors.pick_random()

    _mat = mesh.get_active_material(0).duplicate() as StandardMaterial3D
    _mat.albedo_color = _base_color

    mesh.set_surface_override_material(0, _mat)


func _physics_process(delta: float) -> void:
    time_alive += delta
    if global_position.y < -1.0:
        # Skip to fade duration
        time_alive = max(time_alive, time_to_live - fade_duration)
    if time_alive > time_to_live:
        queue_free()

    var time_remaining := time_to_live - time_alive
    var alpha := clampf(time_remaining, 0.0, 1.0)
    _mat.albedo_color = Color(_base_color.r, _base_color.g, _base_color.b, alpha)
