extends Area3D

var is_open := false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if is_open:
        return
        
    if body.is_in_group("player"):
        if GameManager.has_required_keys():
            open_door()
        else:
            var hud = body.get_node_or_null("HUD")
            if hud and hud.has_method("show_message"):
                hud.show_message("You need a key to escape!")

func open_door() -> void:
    is_open = true
    var hud = get_tree().get_nodes_in_group("player")[0].get_node_or_null("HUD")
    if hud and hud.has_method("show_message"):
        hud.show_message("Door opened! You Win!")
    GameManager.win()
        
    var tween = create_tween()
    tween.tween_property($MeshInstance3D, "position:y", 6.0, 1.0)
    if has_node("StaticBody3D/CollisionShape3D"):
        $StaticBody3D/CollisionShape3D.set_deferred("disabled", true)
