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
