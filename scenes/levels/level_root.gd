extends Node3D
## Root for hand-built levels (e.g. level_01). Sets the required key count from
## the keys actually present, so difficulty's key count doesn't break a fixed map.

func _ready() -> void:
    var keys := get_tree().get_nodes_in_group("key").size()
    GameManager.reset_run(max(1, keys))
    GameManager.start_run_timer()
