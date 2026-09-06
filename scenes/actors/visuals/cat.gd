extends Node3D
## Cat idle: pads along the floor with a light bounce, trotting legs and a
## swaying tail. Unlike the bee it stays grounded, so the bounce is small.

const LEG_SWING := 0.55

@onready var _tail: Node3D = $Tail
@onready var _head: Node3D = $Head
@onready var _legs: Array[Node3D] = [
    $FrontLeftLeg, $FrontRightLeg, $BackLeftLeg, $BackRightLeg,
]

func animate(_delta: float, moving: bool) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    position.y = sin(t * 5.0) * (0.04 if moving else 0.015)
    _tail.rotation.z = sin(t * 2.4) * 0.35
    _tail.rotation.x = sin(t * 1.7) * 0.12
    _head.rotation.y = sin(t * 1.1) * 0.12
    var swing := (sin(t * 9.0) * LEG_SWING if moving else 0.0)
    # Diagonal pairs move together, the way a real cat trots.
    for i in _legs.size():
        var diagonal: bool = (i == 0 or i == 3)
        _legs[i].rotation.x = (swing if diagonal else -swing)
