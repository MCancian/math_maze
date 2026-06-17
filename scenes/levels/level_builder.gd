extends RefCounted
class_name LevelBuilder
## Spawns 3D geometry + actors from a MazeGen grid into a level root.
## CSGBox per wall (simple; revisit for very large mazes). Returns keys placed.

const CELL := 4.0
const WALL_H := 3.0

const PLAYER := preload("res://scenes/actors/player.tscn")
const KEY := preload("res://scenes/actors/key.tscn")
const DOOR := preload("res://scenes/actors/door.tscn")

static func build(root: Node3D, info: Dictionary, maze_cfg: MazeConfig, set_piece: PackedScene) -> int:
    var grid: Array = info["grid"]
    var w: int = info["w"]
    var h: int = info["h"]
    var wall_mat: Material = load("res://materials/wall_material.tres")
    var floor_mat: Material = load("res://materials/floor_material.tres")

    # Floor
    var floor := CSGBox3D.new()
    floor.name = "Floor"
    floor.size = Vector3(w * CELL, 1.0, h * CELL)
    floor.position = Vector3(0, -0.5, 0)
    floor.use_collision = true
    if floor_mat:
        floor.material = floor_mat
    root.add_child(floor)

    # Walls
    var walls := Node3D.new()
    walls.name = "Walls"
    root.add_child(walls)
    for y in h:
        for x in w:
            if grid[y][x] == 1:
                var b := CSGBox3D.new()
                b.size = Vector3(CELL, WALL_H, CELL)
                b.position = _grid_world(x, y, w, h, WALL_H / 2.0)
                b.use_collision = true
                if wall_mat:
                    b.material = wall_mat
                walls.add_child(b)

    # Door set into the outer wall at the carved opening, thin axis aligned to the wall.
    var door := DOOR.instantiate()
    var opening: Vector2i = info["exit_opening"]
    door.position = _grid_world(opening.x, opening.y, w, h, 0.0)
    if info["exit_dir"].x != 0:
        door.rotation.y = PI / 2.0   # east/west wall: rotate thin (Z) axis onto X
    root.add_child(door)

    # Key spots: prefer dead-ends (tucked away), then fall back to the farthest
    # remaining cells. Braiding removes dead-ends, so dead-ends alone can't be
    # relied on to satisfy keys_required — otherwise a level could place 0 keys.
    var dist: Dictionary = info["dist"]
    var sort_far := func(a, b): return dist.get(a, 0) > dist.get(b, 0)

    var deadends: Array = info["deadends"].duplicate()
    deadends.erase(info["exit"])
    deadends.sort_custom(sort_far)

    var spots: Array = deadends.duplicate()
    if spots.size() < maze_cfg.keys_required:
        var others: Array = dist.keys()
        others.erase(info["entrance"])
        others.erase(info["exit"])
        others.sort_custom(sort_far)
        for cell in others:
            if not spots.has(cell):
                spots.append(cell)

    var want: int = min(maze_cfg.keys_required, spots.size())
    var placed := 0
    for i in want:
        var key := KEY.instantiate()
        key.position = _cell_world(spots[i], w, h, 1.0)
        root.add_child(key)
        placed += 1

    # Optional hand-built overlay (hybrid)
    if set_piece:
        root.add_child(set_piece.instantiate())

    # Player at the entrance — added last so its HUD reads final key count.
    var player := PLAYER.instantiate()
    player.position = _cell_world(info["entrance"], w, h, 1.0)
    root.add_child(player)

    return placed

static func _grid_world(gx: int, gy: int, w: int, h: int, y: float) -> Vector3:
    return Vector3((gx - (w - 1) / 2.0) * CELL, y, (gy - (h - 1) / 2.0) * CELL)

static func _cell_world(cell: Vector2i, w: int, h: int, y: float) -> Vector3:
    return _grid_world(2 * cell.x + 1, 2 * cell.y + 1, w, h, y)
