extends SceneTree

func _init():
    var p_scene = ResourceLoader.load("res://player.tscn")
    var player = p_scene.instantiate()
    
    var old_hud = player.get_node_or_null("HUD")
    if old_hud:
        old_hud.free()
        
    var hud = CanvasLayer.new()
    hud.name = "HUD"
    var hud_script = ResourceLoader.load("res://hud.gd")
    hud.set_script(hud_script)
    
    player.add_child(hud)
    hud.owner = player
    
    var keys_lbl = Label.new()
    keys_lbl.name = "KeysLabel"
    keys_lbl.text = "Keys: 0 / 1"
    keys_lbl.position = Vector2(20, 20)
    keys_lbl.add_theme_font_size_override("font_size", 24)
    hud.add_child(keys_lbl)
    keys_lbl.owner = player 
    
    var msg_lbl = Label.new()
    msg_lbl.name = "MessageLabel"
    msg_lbl.text = ""
    msg_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
    msg_lbl.position = Vector2(0, 50)
    msg_lbl.add_theme_font_size_override("font_size", 32)
    msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_child(msg_lbl)
    msg_lbl.owner = player 
    
    var ps_new = PackedScene.new()
    ps_new.pack(player)
    ResourceSaver.save(ps_new, "res://player.tscn")
    
    print("Player HUD fixed.")
    quit()
