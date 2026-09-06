extends Node3D
## Bee idle: hovers, and flaps its wings while the monster is moving.

@onready var _left_wing: Node3D = $FriendlyOverlay/LeftWing
@onready var _right_wing: Node3D = $FriendlyOverlay/RightWing

func animate(_delta: float, moving: bool) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    position.y = 0.9 + sin(t * 6.0) * 0.1
    var flap := (sin(t * 40.0) * 0.5 if moving else sin(t * 6.0) * 0.15)
    _left_wing.rotation.z = flap
    _right_wing.rotation.z = -flap
