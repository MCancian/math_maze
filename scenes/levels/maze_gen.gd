extends RefCounted
class_name MazeGen
## Seeded recursive-backtracker. Produces a PERFECT maze (single path, dead-ends).
## generate() returns a wall-grid (size 2N+1) plus cell metadata for placement.

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## n = cells per side. braid in [0,1]: fraction of dead-ends opened into loops
## (0 = perfect maze, single solution). Returns:
##   grid: Array[Array[int]]  1 = wall, 0 = passage, size (2n+1)x(2n+1)
##   w, h, n
##   entrance, exit: Vector2i  (cell coords)
##   deadends: Array[Vector2i] (cells with one connection, exit excluded later)
##   dist: Dictionary cell -> distance from entrance
static func generate(n: int, seed_val: int, braid: float = 0.0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var start := Vector2i.ZERO
	var visited := {start: true}
	var links := {start: []}        # cell -> Array[Vector2i] connected neighbors
	var stack: Array[Vector2i] = [start]

	while not stack.is_empty():
		var c: Vector2i = stack.back()
		var options: Array[Vector2i] = []
		for d in DIRS:
			var nc: Vector2i = c + d
			if nc.x >= 0 and nc.x < n and nc.y >= 0 and nc.y < n and not visited.has(nc):
				options.append(nc)
		if options.is_empty():
			stack.pop_back()
			continue
		var nxt: Vector2i = options[rng.randi_range(0, options.size() - 1)]
		visited[nxt] = true
		if not links.has(nxt):
			links[nxt] = []
		links[c].append(nxt)
		links[nxt].append(c)
		stack.push_back(nxt)

	# Braid: open a fraction of dead-ends by linking to an unconnected neighbor,
	# creating loops / multiple routes. Keep entrance untouched.
	if braid > 0.0:
		for cell in links.keys():
			if cell == start or links[cell].size() != 1:
				continue
			if rng.randf() >= braid:
				continue
			var cands: Array[Vector2i] = []
			for d in DIRS:
				var nb: Vector2i = cell + d
				if nb.x >= 0 and nb.x < n and nb.y >= 0 and nb.y < n \
						and links.has(nb) and not links[cell].has(nb):
					cands.append(nb)
			if cands.is_empty():
				continue
			var pick: Vector2i = cands[rng.randi_range(0, cands.size() - 1)]
			links[cell].append(pick)
			links[pick].append(cell)

	# Rasterize cells + connections into the wall grid.
	var w := 2 * n + 1
	var h := 2 * n + 1
	var grid: Array = []
	for y in h:
		var row: Array = []
		for x in w:
			row.append(1)
		grid.append(row)
	for cell in links.keys():
		grid[2 * cell.y + 1][2 * cell.x + 1] = 0
		for nb in links[cell]:
			grid[cell.y + nb.y + 1][cell.x + nb.x + 1] = 0  # midpoint between cells

	# BFS from entrance: distances + farthest cell = exit.
	var dist := {start: 0}
	var queue: Array[Vector2i] = [start]
	var far := start
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for nb in links[c]:
			if not dist.has(nb):
				dist[nb] = dist[c] + 1
				if dist[nb] > dist[far]:
					far = nb
				queue.append(nb)

	var deadends: Array[Vector2i] = []
	for cell in links.keys():
		if links[cell].size() == 1 and cell != start:
			deadends.append(cell)

	return {
		"grid": grid, "w": w, "h": h, "n": n,
		"entrance": start, "exit": far, "deadends": deadends, "dist": dist,
	}
