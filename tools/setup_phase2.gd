extends SceneTree

func _init():
    print("Setting up Phase 2...")
    
    # 1. Create Procedural Materials
    var wall_mat = StandardMaterial3D.new()
    var wall_noise = FastNoiseLite.new()
    wall_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
    wall_noise.frequency = 0.05
    var wall_tex = NoiseTexture2D.new()
    wall_tex.noise = wall_noise
    wall_tex.generate_mipmaps = true
    wall_mat.albedo_texture = wall_tex
    wall_mat.albedo_color = Color(0.4, 0.4, 0.4)
    ResourceSaver.save(wall_mat, "res://wall_material.tres")
    
    var floor_mat = StandardMaterial3D.new()
    var floor_noise = FastNoiseLite.new()
    floor_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    floor_noise.frequency = 0.02
    var floor_tex = NoiseTexture2D.new()
    floor_tex.noise = floor_noise
    floor_tex.generate_mipmaps = true
    floor_mat.albedo_texture = floor_tex
    floor_mat.albedo_color = Color(0.2, 0.3, 0.2)
    ResourceSaver.save(floor_mat, "res://floor_material.tres")
    
    # 2. Add HUD to Player
    var p_scene = ResourceLoader.load("res://player.tscn")
    var player = p_scene.instantiate()
    
    var old_hud = player.get_node_or_null("HUD")
    if old_hud:
        old_hud.free()
        
    var hud = CanvasLayer.new()
    hud.name = "HUD"
    var hud_script = ResourceLoader.load("res://hud.gd")
    hud.set_script(hud_script)
    
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
    
    player.add_child(hud)
    hud.owner = player
    
    var ps_new = PackedScene.new()
    ps_new.pack(player)
    ResourceSaver.save(ps_new, "res://player.tscn")
    
    # 3. Create Door Scene
    var door = Area3D.new()
    door.name = "Door"
    var d_script = ResourceLoader.load("res://door.gd")
    door.set_script(d_script)
    
    var d_col = CollisionShape3D.new()
    var d_shape = BoxShape3D.new()
    d_shape.size = Vector3(3, 4, 1)
    d_col.shape = d_shape
    d_col.position.y = 2.0
    door.add_child(d_col)
    d_col.owner = door
    
    var d_mesh = MeshInstance3D.new()
    d_mesh.name = "MeshInstance3D"
    var b_mesh = BoxMesh.new()
    b_mesh.size = Vector3(3, 4, 0.5)
    d_mesh.mesh = b_mesh
    d_mesh.position.y = 2.0
    var d_mat = StandardMaterial3D.new()
    d_mat.albedo_color = Color(0.3, 0.15, 0.05)
    b_mesh.material = d_mat
    door.add_child(d_mesh)
    d_mesh.owner = door
    
    var d_static = StaticBody3D.new()
    d_static.name = "StaticBody3D"
    door.add_child(d_static)
    d_static.owner = door
    var ds_col = CollisionShape3D.new()
    ds_col.name = "CollisionShape3D"
    ds_col.shape = d_shape
    ds_col.position.y = 2.0
    d_static.add_child(ds_col)
    ds_col.owner = door
    
    var ds_scene = PackedScene.new()
    ds_scene.pack(door)
    ResourceSaver.save(ds_scene, "res://door.tscn")
    
    # 4. Rebuild Main Scene
    var main = Node3D.new()
    main.name = "Main"
    
    var env = WorldEnvironment.new()
    var we = Environment.new()
    we.background_mode = Environment.BG_COLOR
    we.background_color = Color(0.05, 0.05, 0.1)
    we.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    we.ambient_light_color = Color(0.1, 0.1, 0.15)
    env.environment = we
    main.add_child(env)
    env.owner = main
    
    var floor_csg = CSGBox3D.new()
    floor_csg.name = "Floor"
    floor_csg.size = Vector3(50, 1, 50)
    floor_csg.position.y = -0.5
    floor_csg.use_collision = true
    floor_csg.material = floor_mat
    main.add_child(floor_csg)
    floor_csg.owner = main
    
    var walls = Node3D.new()
    walls.name = "Walls"
    main.add_child(walls)
    walls.owner = main
    
    var wall_data = [
        {"pos": Vector3(-2, 1.5, -5), "size": Vector3(1, 3, 20)},
        {"pos": Vector3(2, 1.5, -5), "size": Vector3(1, 3, 20)},
        {"pos": Vector3(0, 1.5, 5), "size": Vector3(5, 3, 1)},
        {"pos": Vector3(0, 1.5, -17), "size": Vector3(30, 3, 1)},
        {"pos": Vector3(-9.5, 1.5, -13), "size": Vector3(14, 3, 1)},
        {"pos": Vector3(9.5, 1.5, -13), "size": Vector3(14, 3, 1)},
        {"pos": Vector3(-17, 1.5, -15), "size": Vector3(1, 3, 5)},
        {"pos": Vector3(17, 1.5, -15), "size": Vector3(1, 3, 5)},
    ]
    
    for wd in wall_data:
        var w = CSGBox3D.new()
        w.position = wd["pos"]
        w.size = wd["size"]
        w.use_collision = true
        w.material = wall_mat
        walls.add_child(w)
        w.owner = main
        
    var lights = [
        {"pos": Vector3(0, 2, -5), "color": Color(1, 0.6, 0.2)},
        {"pos": Vector3(-10, 2, -15), "color": Color(0.2, 0.6, 1.0)},
        {"pos": Vector3(10, 2, -15), "color": Color(1, 0.2, 0.2)}
    ]
    
    for l_data in lights:
        var l = OmniLight3D.new()
        l.position = l_data["pos"]
        l.light_color = l_data["color"]
        l.light_energy = 2.0
        l.omni_range = 10.0
        l.shadow_enabled = true
        main.add_child(l)
        l.owner = main
    
    var inst_player = ResourceLoader.load("res://player.tscn").instantiate()
    inst_player.position = Vector3(0, 1, 0)
    main.add_child(inst_player)
    inst_player.owner = main
    
    var inst_key = ResourceLoader.load("res://key.tscn").instantiate()
    inst_key.position = Vector3(-14, 1, -15)
    main.add_child(inst_key)
    inst_key.owner = main
    
    var inst_door = ResourceLoader.load("res://door.tscn").instantiate()
    inst_door.position = Vector3(14, 0, -15)
    inst_door.rotation_degrees = Vector3(0, -90, 0)
    main.add_child(inst_door)
    inst_door.owner = main
    
    var ms_new = PackedScene.new()
    ms_new.pack(main)
    ResourceSaver.save(ms_new, "res://main.tscn")
    
    print("Phase 2 setup complete.")
    quit()
