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
    var placed := LevelBuilder.build(self, info, maze_cfg, set_piece, data)
    if maze_cfg.dark_maze:
        _apply_darkness()
    GameManager.reset_run(placed)
    GameManager.start_run_timer()

## Sun off, faint ambient, dense black fog. Environment is duplicated so the
## shared scene resource stays lit for non-dark configs.
func _apply_darkness() -> void:
    var world_env: WorldEnvironment = $WorldEnvironment
    var env: Environment = world_env.environment.duplicate()
    env.background_color = Color(0, 0, 0, 1)
    env.ambient_light_color = Color(0.05, 0.05, 0.08, 1)
    env.ambient_light_energy = 0.15
    env.fog_enabled = true
    env.fog_light_color = Color(0.01, 0.01, 0.02, 1)
    env.fog_light_energy = 1.0
    env.fog_density = 0.06
    env.fog_sky_affect = 1.0
    world_env.environment = env
    $Sun.visible = false
