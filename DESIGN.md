# math_maze — Architecture & Growth Design

First-person 3D math maze (Godot 4.6). Player walks a maze, touches a glowing orb,
solves an arithmetic problem, earns a key, opens the exit door, wins.

This doc is the target architecture for growth: menus, difficulty levels, multiple
maps, save/progress. Built incrementally — each rollout step stays playable.

## Decisions (locked)

| Topic        | Choice                                                                 |
|--------------|-----------------------------------------------------------------------|
| Map authoring| **Hybrid** — data-driven grid (`LevelData`) built at runtime + optional hand-placed set-piece `.tscn` per level. |
| Difficulty   | One knob drives **both** math hardness **and** maze size/complexity.  |
| Audience     | **Grade-school kids** — arithmetic focus (add → subtract → times tables). |
| Persistence  | **Yes** — unlocked levels + best stars/times, via save file.          |

## Target folder layout

```
res://
  autoload/
    game_manager.gd      # run state + scene-flow spine (autoload: GameManager)
    save_manager.gd      # user://save.json: unlocks, best stars/times  (autoload: SaveManager)
    audio_manager.gd     # music/sfx — stub for now                (autoload: AudioManager)
  scenes/
    actors/   player.tscn/.gd, key.tscn/.gd, door.tscn/.gd
    ui/       hud.gd, math_problem.tscn/.gd, main_menu, level_select, win, lose, loading (steps 2+)
    levels/   level_01.tscn (current map), level_NN.tscn / built from data
  data/
    levels/      level_01.tres ...   (LevelData resources)
    difficulty/  easy.tres, medium.tres, hard.tres  (DifficultyConfig resources)
  materials/  wall/floor/orb .tres
  textures/   (unchanged)
  tools/      setup*.gd, fix_*.gd, download_textures.py, test_game.py  (one-off dev generators)
```

Scripts live **next to** their scene (Godot-idiomatic, fewer path refs). `.gd.uid`
files travel with their script.

## Autoloads

### GameManager (the spine)
Owns the run; everything else talks to it instead of each other (kills the
`get_nodes_in_group("player")[0]...` hops in `door.gd`/`key.gd`).

```
signals: keys_changed(collected, required), level_won, level_lost
state:   keys_collected, keys_required, elapsed_time
         current_level: LevelData, difficulty: DifficultyConfig
api:     reset_run(required), collect_key(), has_required_keys(), win(), lose(),
         start_level(LevelData), next_level(), goto_menu()   # scene-flow added in step 2
```

### SaveManager (step 5)
`user://save.json`. `unlocked_levels: int`, `best: {level_id: {time, stars}}`,
`settings`. API: `is_unlocked(id)`, `record_result(id, time, stars)`, `load()/save()`.

### AudioManager (stub)
Slot reserved; `play_sfx(name)`, `play_music(name)` no-ops for now.

> Drop the 170 KB `mcp_interaction_server.gd` autoload from **shipping** builds —
> it's a dev test harness, not game logic. Stays at repo root for dev use.

## Data resources

### DifficultyConfig (`Resource`)
```
operations: Array[int]   # enum ADD, SUB, MUL
operand_min: int
operand_max: int
keys_required: int       # also raises maze difficulty
maze_size: int           # grid dimension → both math + maze scale together
time_limit: float = 0    # 0 = none (added later)
```
`math_problem.gd` reads this instead of hardcoding `a + b`. New difficulty = new `.tres`.

Grade-school progression: easy `[ADD]` 1–10 → medium `[ADD,SUB]` → hard times tables `[MUL]`.

### LevelData (`Resource`)
```
id: StringName
display_name: String
difficulty: DifficultyConfig
grid: PackedByteArray / text   # data-driven layout: walls, key spawns, door, player start
set_piece: PackedScene = null  # optional hand-built overlay (hybrid)
unlock_order: int
```

## Map pipeline (hybrid)

```
LevelData.grid ──► LevelBuilder.build(data) ──► instances floor/walls/key/door at runtime
                +  data.set_piece (optional)  ──► overlaid hand-built geometry
```
The procedural geometry code currently in `tools/setup*.gd` is **ported into
`LevelBuilder`** — that's where runtime generation belongs, instead of one-shot
editor scripts that rewrite `main.tscn`.

## Screen flow (step 2)

```
Boot → MainMenu → LevelSelect (reads SaveManager unlocks)
     → Loading → Level → Win (record stars/time, unlock next) | Lose
     → back to Menu / Next
```
`GameManager.change_scene()` owns transitions; Loading screen covers heavy level builds.

## Rollout (refactor before features)

1. **Reorg + GameManager** — folders, move files+fix path refs, add the 3 autoloads,
   route key/door/hud through `GameManager`. No new features; current map still plays.
2. **Screen flow** — MainMenu / Win / Lose / Loading scenes; current map = `level_01`.
3. **DifficultyConfig** — `math_problem.gd` reads config; ship easy/medium/hard `.tres`.
4. **LevelData + LevelBuilder** — port `setup*.gd` into runtime builder; add `level_02` as data.
5. **SaveManager** — unlocks + best stars/times; LevelSelect reads them.

## Current → target mapping (step 1)

| Now (root)              | Target                                   |
|-------------------------|------------------------------------------|
| main.tscn               | scenes/levels/level_01.tscn              |
| player.tscn/.gd         | scenes/actors/player.tscn/.gd            |
| key.tscn/.gd            | scenes/actors/key.tscn/.gd               |
| door.tscn/.gd           | scenes/actors/door.tscn/.gd              |
| hud.gd                  | scenes/ui/hud.gd                         |
| math_problem_ui.tscn/.gd| scenes/ui/math_problem.tscn/.gd          |
| *_material.tres         | materials/                               |
| setup*/fix_*/*.py       | tools/                                   |
| (new)                   | autoload/game_manager.gd + save + audio  |

Logic moved in step 1: key counting and win condition leave `player.gd` /
`door.gd` group-lookups and live in `GameManager`. `hud.gd` listens to
`GameManager.keys_changed`. `player.gd` no longer owns `keys`.
