extends RigidBody3D

@export var time_to_live := 3.0
@export var ttl_std_dev := 0.5
@export var fade_duration := 0.75

@onready var mesh: MeshInstance3D = $MeshInstance3D

var _time_alive := 0.0

const COLORS: Array[Color] = [
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

    _base_color = COLORS.pick_random()

    _mat = mesh.get_active_material(0).duplicate() as StandardMaterial3D
    _mat.albedo_color = _base_color
    mesh.set_surface_override_material(0, _mat)


func _physics_process(delta: float) -> void:
    _time_alive += delta

    if global_position.y < -1.0:
        # Skip to fade duration
        _time_alive = maxf(_time_alive, time_to_live - fade_duration)

    if _time_alive > time_to_live:
        queue_free()
        return

    var time_remaining := time_to_live - _time_alive
    var denom := maxf(fade_duration, 0.0001)
    var alpha := clampf(time_remaining / denom, 0.0, 1.0)

    _mat.albedo_color = Color(_base_color.r, _base_color.g, _base_color.b, alpha)
