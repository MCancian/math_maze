extends Area3D

var ui_scene = preload("res://scenes/ui/math_problem.tscn")
var ui_instance: Control
var time_passed := 0.0
var base_y := 0.0

func _ready() -> void:
    add_to_group("key")
    body_entered.connect(_on_body_entered)
    ui_instance = ui_scene.instantiate()
    get_tree().root.call_deferred("add_child", ui_instance)
    ui_instance.solved.connect(_on_solved)
    base_y = position.y

func _process(delta: float) -> void:
    time_passed += delta
    position.y = base_y + sin(time_passed * 3.0) * 0.2
    var mesh = get_node_or_null("MeshInstance3D")
    if mesh:
        mesh.rotate_y(delta)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        body.set_interacting(true)
        ui_instance.show_problem()
        set_deferred("monitoring", false)

func _on_solved() -> void:
    var player = get_tree().get_nodes_in_group("player")
    if player.size() > 0:
        player[0].set_interacting(false)
    GameManager.collect_key()
    ui_instance.queue_free()
    queue_free()
