extends SceneTree

func _init():
    var main_scene = ResourceLoader.load("res://main.tscn")
    var main = main_scene.instantiate()
    
    var wall_mat = ResourceLoader.load("res://wall_material.tres")
    var floor_mat = ResourceLoader.load("res://floor_material.tres")
    
    var floor_node = main.get_node_or_null("Floor")
    if floor_node:
        floor_node.material = floor_mat
        
    var walls = main.get_node_or_null("Walls")
    if walls:
        for w in walls.get_children():
            w.material = wall_mat
            
    var ms_new = PackedScene.new()
    ms_new.pack(main)
    ResourceSaver.save(ms_new, "res://main.tscn")
    
    print("Fixed main.tscn materials")
    quit()
