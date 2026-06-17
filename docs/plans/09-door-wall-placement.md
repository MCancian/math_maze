# Door Wall Placement

**Status:** 🔜 Future (bug fix)

On generated levels the exit door appears free-standing in the middle of an open area
instead of set into a wall, so it doesn't read as "the way out." This plan makes the
exit always sit on the maze **perimeter** with the door **flush in an outer wall**.

## Background: how the maze is laid out

Read these two files first — the fix lives entirely in them:
`scenes/levels/maze_gen.gd` and `scenes/levels/level_builder.gd`.

- A maze is `n × n` **cells**. A cell is `Vector2i(cx, cy)` with `cx, cy` in `[0, n)`.
- `MazeGen.generate()` rasterizes cells into a **wall grid** of size `w = h = 2n + 1`,
  stored as `grid[y][x]` where `1` = wall, `0` = passage.
  - Cell `(cx, cy)` maps to grid position `(2*cx + 1, 2*cy + 1)` (odd indices).
  - The grid border (index `0` and `w - 1` on each axis) is **always wall** — that's
    the maze's outer boundary.
- World mapping (in `LevelBuilder`): grid X → world **X**, grid Y → world **Z**.
  `_grid_world(gx, gy, w, h, y)` returns the world position of a grid cell;
  `_cell_world(cell, ...)` is the same for a maze cell (it calls `_grid_world` with
  `2*cx+1, 2*cy+1`).

### Why the door floats today

`MazeGen` sets `exit` to the BFS-**farthest cell anywhere** (`far`). `LevelBuilder` puts
the door at `_cell_world(info["exit"])` — the **center of that cell** — with no rotation.
On open/braided mazes the farthest cell is often interior with no adjacent wall, so the
door slab stands in open space.

### The door's geometry (`scenes/actors/door.tscn`)

The barrier/trigger/mesh are **thin along Z** (barrier `size(4,4,0.6)`, trigger
`size(4,4,3.5)`, mesh `size(3.4,4,0.4)`). Unrotated, the door blocks movement along Z and
spans X. So:
- Exit opening facing **±Z** (north/south wall): door needs **no rotation**.
- Exit opening facing **±X** (east/west wall): door needs **`rotation.y = PI/2`** so its
  thin axis lines up with X.

The slab is symmetric, so which way it "faces" is cosmetic — only the axis matters.

## Implementation

### Step 1 — `scenes/levels/maze_gen.gd`: pick a perimeter exit + carve the opening

After the BFS block that builds `dist` (and the existing `far` tracking — keep it as a
fallback), and **before** the `deadends` block / `return`, choose the exit from perimeter
cells and open the outer wall in front of it:

```gdscript
	# Exit = farthest PERIMETER cell from the entrance, so the door can sit in an
	# outer wall. (far stays a fallback for tiny mazes with no other perimeter cell.)
	var exit_cell := far
	var best := -1
	for cell in dist.keys():
		if cell == start:
			continue
		var on_perimeter: bool = cell.x == 0 or cell.x == n - 1 or cell.y == 0 or cell.y == n - 1
		if on_perimeter and dist[cell] > best:
			best = dist[cell]
			exit_cell = cell

	# Outward normal of the edge the exit cell touches (x-edges win on a corner).
	var exit_dir := Vector2i.ZERO
	if exit_cell.x == 0:
		exit_dir = Vector2i(-1, 0)
	elif exit_cell.x == n - 1:
		exit_dir = Vector2i(1, 0)
	elif exit_cell.y == 0:
		exit_dir = Vector2i(0, -1)
	elif exit_cell.y == n - 1:
		exit_dir = Vector2i(0, 1)

	# Carve the border wall just outside the exit cell so the door isn't buried
	# behind a solid border wall — gives a continuous passage out through the door.
	var open_gx: int = 2 * exit_cell.x + 1 + exit_dir.x
	var open_gy: int = 2 * exit_cell.y + 1 + exit_dir.y
	if exit_dir != Vector2i.ZERO:
		grid[open_gy][open_gx] = 0
```

Then update the returned dictionary: change `"exit": far` to `"exit": exit_cell` and add
the two new fields:

```gdscript
	return {
		"grid": grid, "w": w, "h": h, "n": n,
		"entrance": start, "exit": exit_cell,
		"exit_dir": exit_dir, "exit_opening": Vector2i(open_gx, open_gy),
		"deadends": deadends, "dist": dist,
	}
```

(Keep `far` defined — it seeds `exit_cell` as the fallback. `deadends.erase(exit)` in the
builder still works because `exit` is a valid cell coord.)

### Step 2 — `scenes/levels/level_builder.gd`: place the door in the opening

Replace the current door block (the three lines under `# Door at the exit ...`):

```gdscript
	# Door set into the outer wall at the carved opening, thin axis aligned to the wall.
	var door := DOOR.instantiate()
	var opening: Vector2i = info["exit_opening"]
	door.position = _grid_world(opening.x, opening.y, w, h, 0.0)
	if info["exit_dir"].x != 0:
		door.rotation.y = PI / 2.0   # east/west wall: rotate thin (Z) axis onto X
	root.add_child(door)
```

The wall loop already skips the opening because we set `grid[open_gy][open_gx] = 0`, so no
wall CSGBox spawns where the door goes. The full-size floor still covers it. Key placement
is unchanged (it keys off `info["exit"]`/`dist`, which still hold valid cells).

## Validation

1. **Headless connectivity + perimeter test.** Add a temporary script under `tools/`
   (delete after) and run `~/.local/bin/godot --headless --path . -s res://tools/_door_test.gd`.
   Use `load()` (not `class_name` — see AGENTS.md `-s` GOTCHA):

   ```gdscript
   extends SceneTree
   func _init() -> void:
       var MG = load("res://scenes/levels/maze_gen.gd")
       var fails := 0
       for seed_val in [1337, 4242, 9001, 271828, 161803]:
           for braid in [0.0, 0.25, 0.5]:
               var info = MG.generate(6, seed_val, braid)
               var ex = info["exit"]; var n = info["n"]
               var on_perim = ex.x == 0 or ex.x == n-1 or ex.y == 0 or ex.y == n-1
               var op = info["exit_opening"]; var w = info["w"]
               var border = op.x == 0 or op.x == w-1 or op.y == 0 or op.y == w-1
               var carved = info["grid"][op.y][op.x] == 0
               if not (on_perim and border and carved):
                   fails += 1; print("FAIL seed=%d braid=%s" % [seed_val, braid])
       print("=== fails: ", fails, " ===")
       quit(1 if fails > 0 else 0)
   ```
   Expect `fails: 0`. (Optionally add a flood-fill from the entrance interior asserting
   every cell interior `(2cx+1,2cy+1)` is still reachable — braiding never disconnects,
   and one carved border opening can't either.)

2. **Clean boot:** `~/.local/bin/godot --headless --path .` → exit 0, no errors.

3. **Manual visual check:** play a couple of `gen_*` levels — the door should sit in the
   outer wall, reachable from inside, and still open + win on contact with a key.

## Acceptance criteria

- For every `gen_*` seed and every maze difficulty, the exit cell is on the perimeter and
  the door sits in the outer wall (no free-standing door).
- The maze stays fully connected; the door still triggers `GameManager.win()` with the
  required keys.
- Hand-built tutorial (`level_01`) is untouched (it has its own door, not built here).

## Touches

`scenes/levels/maze_gen.gd` (perimeter exit + carve opening + new return fields),
`scenes/levels/level_builder.gd` (door position/rotation from `exit_opening`/`exit_dir`).
No changes to `door.tscn` expected.
