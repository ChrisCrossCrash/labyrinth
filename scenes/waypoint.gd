extends Area3D


signal waypoint_reached(index: int)


func _on_body_entered(body: Node3D) -> void:
    if not body.is_in_group("ball"):
        return

    waypoint_reached.emit(get_index())
