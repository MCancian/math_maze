extends SceneTree

func _init():
    print("Setting up project...")
    
    # 1. Setup Input Map
    var inputs = {
        "move_forward": KEY_W,
        "move_backward": KEY_S,
        "move_left": KEY_A,
        "move_right": KEY_D,
        "interact": KEY_E
    }
    
    for action in inputs:
        if not ProjectSettings.has_setting("input/" + action):
            var event = InputEventKey.new()
            event.keycode = inputs[action]
            ProjectSettings.set_setting("input/" + action, {"deadzone": 0.5, "events": [event]})
    
    ProjectSettings.set_setting("application/run/main_scene", "res://main.tscn")
    ProjectSettings.save()
    print("Input map saved.")
    
    # Create player scene
    var player = CharacterBody3D.new()
    player.name = "Player"
    var coll = CollisionShape3D.new()
    var shape = CapsuleShape3D.new()
    coll.shape = shape
    coll.position.y = 1.0
    player.add_child(coll)
    coll.owner = player
    
    var head = Node3D.new()
    head.name = "Head"
    head.position.y = 1.5
    player.add_child(head)
    head.owner = player
    
    var cam = Camera3D.new()
    cam.name = "Camera3D"
    head.add_child(cam)
    cam.owner = player
    
    var ray = RayCast3D.new()
    ray.name = "RayCast3D"
    ray.target_position = Vector3(0, 0, -2)
    ray.collide_with_areas = true
    ray.collide_with_bodies = false
    cam.add_child(ray)
    ray.owner = player
    
    var ps = PackedScene.new()
    ps.pack(player)
    ResourceSaver.save(ps, "res://player.tscn")
    
    # Create key scene
    var key = Area3D.new()
    key.name = "Key"
    var key_col = CollisionShape3D.new()
    var key_shape = BoxShape3D.new()
    key_shape.size = Vector3(0.5, 0.5, 0.5)
    key_col.shape = key_shape
    key.add_child(key_col)
    key_col.owner = key
    
    var key_mesh = MeshInstance3D.new()
    var smesh = SphereMesh.new()
    smesh.radius = 0.25
    smesh.height = 0.5
    key_mesh.mesh = smesh
    key.add_child(key_mesh)
    key_mesh.owner = key
    
    var ks = PackedScene.new()
    ks.pack(key)
    ResourceSaver.save(ks, "res://key.tscn")
    
    # Create math ui
    var ui = Control.new()
    ui.name = "MathProblemUI"
    ui.set_anchors_preset(Control.PRESET_FULL_RECT)
    var panel = Panel.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.custom_minimum_size = Vector2(400, 200)
    ui.add_child(panel)
    panel.owner = ui
    
    var vbox = VBoxContainer.new()
    vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
    panel.add_child(vbox)
    vbox.owner = ui
    
    var lbl = Label.new()
    lbl.name = "QuestionLabel"
    lbl.text = "Math Problem?"
    vbox.add_child(lbl)
    lbl.owner = ui
    
    var inp = LineEdit.new()
    inp.name = "AnswerInput"
    vbox.add_child(inp)
    inp.owner = ui
    
    var btn = Button.new()
    btn.name = "SubmitButton"
    btn.text = "Submit"
    vbox.add_child(btn)
    btn.owner = ui
    
    var uis = PackedScene.new()
    uis.pack(ui)
    ResourceSaver.save(uis, "res://math_problem_ui.tscn")
    
    # Create main scene
    var main = Node3D.new()
    main.name = "Main"
    
    var floor = CSGBox3D.new()
    floor.name = "Floor"
    floor.size = Vector3(20, 1, 20)
    floor.position.y = -0.5
    floor.use_collision = true
    main.add_child(floor)
    floor.owner = main
    
    var wall1 = CSGBox3D.new()
    wall1.size = Vector3(20, 3, 1)
    wall1.position = Vector3(0, 1.5, -10)
    wall1.use_collision = true
    main.add_child(wall1)
    wall1.owner = main
    
    var sun = DirectionalLight3D.new()
    sun.transform.basis = Basis().rotated(Vector3(1,0,0), -PI/4)
    main.add_child(sun)
    sun.owner = main
    
    var ms = PackedScene.new()
    ms.pack(main)
    ResourceSaver.save(ms, "res://main.tscn")
    
    print("All scenes generated.")
    quit()
