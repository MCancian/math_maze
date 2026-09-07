# Overview

## Requirements

Math Maze is a first-person 3D maze game for grade-school kids. Arithmetic is the
lock; the maze is the door.

The core loop:

1. Walk the maze corridors.
2. Touch a glowing orb. A math problem appears.
3. Solve it to earn a key.
4. Collect the number of keys the maze difficulty requires.
5. Reach the exit door and walk through it to win.

The exit door always sits flush in the maze's outer wall, on the perimeter, so it reads
as the way out rather than a slab standing in open space. As the player walks, a trail
of small glowing discs is left on the floor, marking where they have already been.

On a win the game shows the finishing time and awards one to three stars for it.

Screens, in the order a player meets them:

- **Main Menu** — New Game, Continue (only when a saved profile exists), Music on/off, Quit.
- **New Game** — type a name and pick one of three profile slots.
- **Difficulty** — choose a math difficulty and a maze difficulty, separately.
- **Level Select** — pick any unlocked level; locked ones are shown but cannot be started.
- **Loading** — a short screen while the maze is built.
- **Level** — the maze itself, with a heads-up display showing keys collected.
- **Win** — time, stars, and a Next Level button when there is one.

**Continue** goes from the Main Menu to **Profile Select**, then straight into that
profile's current level with its saved difficulty choices.

A Lose screen exists, but nothing in the game reaches it yet: there is currently no way
to lose a run.

## Decisions

- **Arithmetic gates progress, not reflexes.** Every locked thing (orb, dead flashlight,
  monster catch) is opened by a correct answer, never by speed or aim.
- **Kids first.** Easy is bright, quiet and friendly; fear and pressure are added only on
  the harder settings, and only ever as a math interruption.
- **Fixed layouts.** Levels are the same every time they are played, so a best time means
  something and a child can learn a maze.

## Planned

- **lose-conditions** — a run can be lost, reaching the existing Lose screen.
- **map-overlay** — a map of visited corridors on the M key.
- **bonus-problems-and-coins** — optional extra problems that award a spendable currency.
- **wall-textures-and-objects** — varied wall looks and small decorations in the corridors.
- **performance** — large mazes build and draw without a hitch.
