# Difficulty

## Requirements

Difficulty is two independent choices, made side by side on one screen: a **math**
difficulty and a **maze** difficulty. Either can be changed without touching the other.

### Math

- **Addition** — two single-digit numbers (each up to 9).
- **Multiplication** — two single-digit numbers (each up to 9).
- **Fractions-of** — "what is n/d of W?", with the whole chosen so the answer is a whole number.

Rules for every math mode:

- The answer is always a whole number.
- The answer box accepts only digits and a slash. A slash answer that equals a whole
  number counts: typing 4/1 for 4 is correct.
- A wrong answer shows the same question again with an "Incorrect" message; the player
  keeps trying until it is right.

### Maze

| | Easy | Medium | Hard |
| --- | --- | --- | --- |
| Size | 4 × 4 cells | 7 × 7 cells | 9 × 9 cells |
| Loops | none, one route | moderately looped | heavily looped |
| Keys required | 1 | 2 | 3 |
| Lighting | lit | dark, flashlight | dark, flashlight |
| Creature | cat, silent | slime, silent | shadow with red eyes, growl and heartbeat |
| Music | bouncy "explore" | minor-key "spooky" | darker "dread" |

Keys are placed at the far dead-ends of the maze. When loops leave too few dead-ends,
the remaining keys go to the farthest cells left over, so the required number of keys is
always reachable.

## Decisions

- **Two axes, not one dial.** A strong reader who is still learning to multiply can pick
  a hard maze with easy math; a confident mathematician who gets lost easily can do the
  reverse.
- **Whole-number answers only**, so the answer box never needs decimals and a fraction
  question still has one obviously right answer.
- **Keys always fit the maze.** A settings choice can never produce a maze with fewer
  keys than the door demands.

## Planned

- **lose-conditions** — per-maze-difficulty limits that can end a run, gentle on Easy.
- **levels-and-visuals** — maze size and loopiness may also climb across levels.
