extends Resource
class_name MazeConfig
## Controls ONLY the maze (independent of math difficulty).
## Authored as .tres in data/maze/. Read by LevelBuilder + level_generated via GameManager.maze.

@export var display_name: String = "Easy"
## Cells per side fed to MazeGen (grid becomes 2*(size+3)+1 walls).
@export var maze_size: int = 1
## 0.0 = perfect maze (single solution, many dead-ends).
## Higher = more dead-ends opened into loops → multiple routes.
@export_range(0.0, 1.0) var braid_factor: float = 0.0
## Keys to collect before the door opens.
@export var keys_required: int = 1

## Default monster gate for open/hard mazes. LevelData can override this.
@export var monster_enabled: bool = false
@export_range(0.0, 1.0) var monster_braid_threshold: float = 0.5
## Player SPEED is 5.0; monster stays slower so escape remains possible.
@export var monster_speed: float = 3.4
@export var monster_cooldown_seconds: float = 120.0
## Presentation knobs: Easy can use a friendly bee; Hard can use shadow + rumble.
@export var monster_bee_visual: bool = false
@export var monster_scary_visual: bool = false
@export var monster_sound_enabled: bool = false

func allows_monster() -> bool:
    return monster_enabled and braid_factor >= monster_braid_threshold
