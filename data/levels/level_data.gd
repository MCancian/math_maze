extends Resource
class_name LevelData
## A level definition. If `scene` is set it's a hand-built level (loaded as-is);
## otherwise it's generated from `maze_seed` + the active MazeConfig (size, braid).

const MONSTER_DEFAULT := 0
const MONSTER_FORCE_ON := 1
const MONSTER_FORCE_OFF := 2

@export var id: StringName = &"level"
@export var display_name: String = "Level"
@export var unlock_order: int = 1
## Hand-built scene. Null = procedurally generated.
@export var scene: PackedScene
## Fixed seed → identical maze every play (only used when generated).
@export var maze_seed: int = 0
## Optional hand-placed overlay laid over a generated maze (hybrid).
@export var set_piece: PackedScene
## Monster spawn override. Default follows MazeConfig.allows_monster().
@export_enum("Default", "Force On", "Force Off") var monster_spawn: int = MONSTER_DEFAULT
## Finish-time cutoffs (seconds): under [0] = 3 stars, under [1] = 2 stars, else 1.
@export var star_thresholds: Array[float] = [30.0, 60.0]

func allows_monster(maze_cfg: MazeConfig) -> bool:
    if monster_spawn == MONSTER_FORCE_ON:
        return true
    if monster_spawn == MONSTER_FORCE_OFF:
        return false
    return maze_cfg != null and maze_cfg.allows_monster()

func stars_for(elapsed: float) -> int:
    if star_thresholds.size() >= 2:
        if elapsed < star_thresholds[0]:
            return 3
        if elapsed < star_thresholds[1]:
            return 2
    return 1
