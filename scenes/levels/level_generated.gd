extends Node3D
## Root of a procedurally generated level. Builds the maze from
## GameManager.current_level (seed) + GameManager.maze (size, braid, keys).

func _ready() -> void:
    var data: LevelData = GameManager.current_level
    var maze_cfg: MazeConfig = GameManager.maze
    var n: int = maze_cfg.maze_size + 3
    var seed_val: int = data.maze_seed if data else 0
    var info := MazeGen.generate(n, seed_val, maze_cfg.braid_factor)
    var set_piece: PackedScene = data.set_piece if data else null
    var placed := LevelBuilder.build(self, info, maze_cfg, set_piece)
    GameManager.reset_run(placed)
    GameManager.start_run_timer()
