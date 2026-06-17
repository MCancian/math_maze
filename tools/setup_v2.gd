extends SceneTree

func _init():
    print("Attaching scripts and building main scene...")
    
    var player_script = ResourceLoader.load("res://player.gd")
    var key_script = ResourceLoader.load("res://key.gd")
    var ui_script = ResourceLoader.load("res://math_problem_ui.gd")
    
    var p_scene = ResourceLoader.load("res://player.tscn")
    var player = p_scene.instantiate()
    player.set_script(player_script)
    var ps_new = PackedScene.new()
    ps_new.pack(player)
    ResourceSaver.save(ps_new, "res://player.tscn")
    
    var k_scene = ResourceLoader.load("res://key.tscn")
    var key = k_scene.instantiate()
    key.set_script(key_script)
    var ks_new = PackedScene.new()
    ks_new.pack(key)
    ResourceSaver.save(ks_new, "res://key.tscn")
    
    var u_scene = ResourceLoader.load("res://math_problem_ui.tscn")
    var ui = u_scene.instantiate()
    ui.set_script(ui_script)
    var us_new = PackedScene.new()
    us_new.pack(ui)
    ResourceSaver.save(us_new, "res://math_problem_ui.tscn")
    
    var m_scene = ResourceLoader.load("res://main.tscn")
    var main = m_scene.instantiate()
    
    var inst_player = ResourceLoader.load("res://player.tscn").instantiate()
    inst_player.position = Vector3(0, 1.5, 0)
    main.add_child(inst_player)
    inst_player.owner = main
    
    var inst_key = ResourceLoader.load("res://key.tscn").instantiate()
    inst_key.position = Vector3(0, 1, -5)
    main.add_child(inst_key)
    inst_key.owner = main
    
    var ms_new = PackedScene.new()
    ms_new.pack(main)
    ResourceSaver.save(ms_new, "res://main.tscn")
    
    print("Done attaching scripts and instantiating.")
    quit()
