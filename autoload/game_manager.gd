extends Node
## Run-state + scene-flow spine. Everything talks to this instead of each other.

signal keys_changed(collected: int, required: int)
signal monster_state_changed(active: bool, cooldown_remaining: float)
signal level_won
signal level_lost

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const NEW_GAME_SCENE := "res://scenes/ui/new_game.tscn"
const PROFILE_SELECT_SCENE := "res://scenes/ui/profile_select.tscn"
const DIFFICULTY_SELECT_SCENE := "res://scenes/ui/difficulty_select.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/ui/level_select.tscn"
const LOADING_SCENE := "res://scenes/ui/loading.tscn"
const WIN_SCENE := "res://scenes/ui/win.tscn"
const LOSE_SCENE := "res://scenes/ui/lose.tscn"
## Scene that builds a procedurally generated level at runtime.
const GENERATED_SCENE := "res://scenes/levels/level_generated.tscn"

const MATH_ADDITION := preload("res://data/math/addition.tres")
const MATH_MULTIPLICATION := preload("res://data/math/multiplication.tres")
const MATH_FRACTIONS := preload("res://data/math/fractions.tres")
const MAZE_EASY := preload("res://data/maze/maze_easy.tres")
const MAZE_MEDIUM := preload("res://data/maze/maze_medium.tres")
const MAZE_HARD := preload("res://data/maze/maze_hard.tres")

const DEFAULT_MATH := MATH_ADDITION
const DEFAULT_MAZE := MAZE_EASY
const MATH_CONFIGS := [MATH_ADDITION, MATH_MULTIPLICATION, MATH_FRACTIONS]
const MAZE_CONFIGS := [MAZE_EASY, MAZE_MEDIUM, MAZE_HARD]

## Hand-built level kept only as a dev test scene (not in the play flow).
const TEST_LEVEL := preload("res://data/levels/level_01.tres")
## Generated levels in progression order — each a distinct maze seed.
const GEN_01 := preload("res://data/levels/gen_01.tres")
const GEN_02 := preload("res://data/levels/gen_02.tres")
const GEN_03 := preload("res://data/levels/gen_03.tres")
const GEN_04 := preload("res://data/levels/gen_04.tres")
const GEN_05 := preload("res://data/levels/gen_05.tres")
const LEVELS := [GEN_01, GEN_02, GEN_03, GEN_04, GEN_05]
## The actual game starts here.
const FIRST_LEVEL := GEN_01

## Door animation plays before the Win screen takes over.
const WIN_DELAY := 1.2

## Math difficulty and maze difficulty are chosen independently.
var math: MathConfig = DEFAULT_MATH
var maze: MazeConfig = DEFAULT_MAZE
var current_level: LevelData = FIRST_LEVEL
var keys_collected: int = 0
var keys_required: int = 1
var elapsed_time: float = 0.0
var monster_active: bool = false
var monster_cooldown_remaining: float = 0.0

## Wall-clock start of the current run, set when the level scene is ready.
var run_start_ms: int = 0

## Set by start_level, consumed by the Loading screen.
var pending_scene_path: String = ""

## Call at the start of each level. keys_required scales with difficulty.
func reset_run(required: int = 1) -> void:
    keys_required = required
    keys_collected = 0
    elapsed_time = 0.0
    keys_changed.emit(keys_collected, keys_required)
    set_monster_state(false, 0.0)

## Call once gameplay actually begins (level scene _ready), so best times are honest.
func start_run_timer() -> void:
    run_start_ms = Time.get_ticks_msec()

func collect_key() -> void:
    keys_collected += 1
    keys_changed.emit(keys_collected, keys_required)

func lose_key() -> void:
    if keys_collected <= 0:
        return
    keys_collected -= 1
    keys_changed.emit(keys_collected, keys_required)

func set_monster_state(active: bool, cooldown_remaining: float = 0.0) -> void:
    monster_active = active
    monster_cooldown_remaining = maxf(cooldown_remaining, 0.0)
    monster_state_changed.emit(monster_active, monster_cooldown_remaining)

func has_required_keys() -> bool:
    return keys_collected >= keys_required

func win() -> void:
    elapsed_time = (Time.get_ticks_msec() - run_start_ms) / 1000.0
    var stars := current_level.stars_for(elapsed_time) if current_level else 1
    SaveManager.record_result(current_level.id, elapsed_time, stars)
    if has_next_level():
        SaveManager.unlock(_next_order())
    level_won.emit()
    await get_tree().create_timer(WIN_DELAY).timeout
    get_tree().change_scene_to_file(WIN_SCENE)

## unlock_order of the level after current_level in LEVELS.
func _next_order() -> int:
    var idx := LEVELS.find(current_level)
    if idx >= 0 and idx + 1 < LEVELS.size():
        return LEVELS[idx + 1].unlock_order
    return current_level.unlock_order

func lose() -> void:
    level_lost.emit()
    get_tree().change_scene_to_file(LOSE_SCENE)

## --- Scene flow ---

func goto_menu() -> void:
    get_tree().change_scene_to_file(MENU_SCENE)

func goto_new_game() -> void:
    get_tree().change_scene_to_file(NEW_GAME_SCENE)

func goto_profile_select() -> void:
    get_tree().change_scene_to_file(PROFILE_SELECT_SCENE)

func goto_difficulty_select() -> void:
    get_tree().change_scene_to_file(DIFFICULTY_SELECT_SCENE)

func goto_level_select() -> void:
    get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)

## Continue: load the active profile's saved difficulty and jump into its current level.
func resume_active() -> void:
    if not SaveManager.has_active_profile():
        goto_menu()
        return
    var math_cfg: MathConfig = load(SaveManager.active_math_path(DEFAULT_MATH.resource_path))
    var maze_cfg: MazeConfig = load(SaveManager.active_maze_path(DEFAULT_MAZE.resource_path))
    var order := SaveManager.current_order(1)
    var level: LevelData = FIRST_LEVEL
    for l in LEVELS:
        if l.unlock_order == order:
            level = l
            break
    start_level(math_cfg, maze_cfg, level)

## Resets run state for the given difficulty, then loads the level (hand-built
## scene or the generator) through the Loading screen.
func start_level(math_cfg: MathConfig, maze_cfg: MazeConfig, level_data: LevelData = FIRST_LEVEL) -> void:
    math = math_cfg
    maze = maze_cfg
    current_level = level_data
    SaveManager.set_current(level_data.unlock_order)
    reset_run(maze_cfg.keys_required)  # tentative; level confirms actual key count on _ready
    pending_scene_path = level_data.scene.resource_path if level_data.scene else GENERATED_SCENE
    get_tree().change_scene_to_file(LOADING_SCENE)

func restart_level() -> void:
    start_level(math, maze, current_level)

## Advances to the next level in LEVELS (same difficulty), or back to the menu.
func next_level() -> void:
    var idx := LEVELS.find(current_level)
    if idx >= 0 and idx + 1 < LEVELS.size():
        start_level(math, maze, LEVELS[idx + 1])
    else:
        goto_menu()

func has_next_level() -> bool:
    var idx := LEVELS.find(current_level)
    return idx >= 0 and idx + 1 < LEVELS.size()
