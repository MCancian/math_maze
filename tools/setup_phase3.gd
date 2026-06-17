extends SceneTree

func _init():
    print("Setting up Phase 3 textures...")
    
    var wall_mat = ResourceLoader.load("res://wall_material.tres")
    if wall_mat:
        wall_mat.albedo_texture = ResourceLoader.load("res://textures/wall_diffuse.jpg")
        wall_mat.normal_enabled = true
        wall_mat.normal_texture = ResourceLoader.load("res://textures/wall_nor_gl.jpg")
        wall_mat.roughness_texture = ResourceLoader.load("res://textures/wall_rough.jpg")
        wall_mat.uv1_triplanar = true
        wall_mat.albedo_color = Color(1,1,1)
        ResourceSaver.save(wall_mat, "res://wall_material.tres")
    
    var floor_mat = ResourceLoader.load("res://floor_material.tres")
    if floor_mat:
        floor_mat.albedo_texture = ResourceLoader.load("res://textures/floor_diffuse.jpg")
        floor_mat.normal_enabled = true
        floor_mat.normal_texture = ResourceLoader.load("res://textures/floor_nor_gl.jpg")
        floor_mat.roughness_texture = ResourceLoader.load("res://textures/floor_rough.jpg")
        floor_mat.uv1_triplanar = true
        floor_mat.albedo_color = Color(1,1,1)
        ResourceSaver.save(floor_mat, "res://floor_material.tres")
    
    var orb_mat = StandardMaterial3D.new()
    orb_mat.albedo_texture = ResourceLoader.load("res://textures/orb_diffuse.jpg")
    orb_mat.normal_enabled = true
    orb_mat.normal_texture = ResourceLoader.load("res://textures/orb_nor_gl.jpg")
    orb_mat.roughness_texture = ResourceLoader.load("res://textures/orb_rough.jpg")
    orb_mat.emission_enabled = true
    orb_mat.emission = Color(0.2, 0.4, 0.5)
    orb_mat.emission_energy_multiplier = 0.5
    ResourceSaver.save(orb_mat, "res://orb_material.tres")
    
    var key_scene = ResourceLoader.load("res://key.tscn")
    var key_node = key_scene.instantiate()
    var mesh = key_node.get_node_or_null("MeshInstance3D")
    if mesh and mesh.mesh:
        mesh.mesh.material = orb_mat
    
    var new_key_scene = PackedScene.new()
    new_key_scene.pack(key_node)
    ResourceSaver.save(new_key_scene, "res://key.tscn")
    
    print("Phase 3 textures applied successfully.")
    quit()
