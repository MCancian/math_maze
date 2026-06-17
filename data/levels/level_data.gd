extends Resource
class_name LevelData
## A level definition. If `scene` is set it's a hand-built level (loaded as-is);
## otherwise it's generated from `maze_seed` + the active MazeConfig (size, braid).

@export var id: StringName = &"level"
@export var display_name: String = "Level"
@export var unlock_order: int = 1
## Hand-built scene. Null = procedurally generated.
@export var scene: PackedScene
## Fixed seed → identical maze every play (only used when generated).
@export var maze_seed: int = 0
## Optional hand-placed overlay laid over a generated maze (hybrid).
@export var set_piece: PackedScene
## Finish-time cutoffs (seconds): under [0] = 3 stars, under [1] = 2 stars, else 1.
@export var star_thresholds: Array[float] = [30.0, 60.0]

func stars_for(elapsed: float) -> int:
    if star_thresholds.size() >= 2:
        if elapsed < star_thresholds[0]:
            return 3
        if elapsed < star_thresholds[1]:
            return 2
    return 1
