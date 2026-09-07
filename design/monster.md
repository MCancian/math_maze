# Monster

## Requirements

One creature per maze difficulty roams the corridors and chases the player. It is always
slower than the player, so it can be outrun.

- **Easy** — a cat. It chases too, slowly and silently: it is a monster in a friendly
  costume.
- **Medium** — a slime, silent.
- **Hard** — a shadow with red eyes. A growl loops from wherever it is and gets louder as
  it nears. A heartbeat plays that beats faster and louder, continuously, as the distance
  closes: it starts within about 30 units, from one beat every 1.3 seconds far away to one
  every 0.42 seconds when the monster is on top of the player.

On Medium and Hard the monster appears only when the maze is open enough, that is when
the maze has loops above a threshold. Today's Medium and Hard settings always satisfy it.

A **catch** happens when the monster reaches the player:

- The player is frozen and a math prompt opens. On Hard a stinger sound plays.
- A wrong answer costs one collected key. With no keys in hand nothing is lost, and the
  message says so. The prompt stays open until the answer is right.
- A correct answer makes the monster vanish for a two-minute cooldown. It then reappears
  at the farthest reachable cell from the player and resumes the chase.

The heads-up display shows "Monster: active" while it hunts and "Monster: back in N s"
during the cooldown.

A level may force the monster on or off regardless of the maze difficulty. That is the
only per-level override today.

## Decisions

- **A math interrupt, not a lose condition.** Being caught costs a key and a problem,
  never the run. The tension is real but the worst case is more arithmetic.
- **Grid path-finding, not a navigation mesh.** The maze is a grid; the monster walks
  cell to cell toward the player, which is simple and predictable.
- **Slower than the player**, always, so escape stays possible and the chase is a choice.
- **A per-level override exists** so a hand-tuned level can disable or force the chase.

## Planned

- **levels-and-visuals** — a per-level creature choice, and a rigged cat model replacing the primitive one.
- **audio-polish** — footsteps for the monster, and a catch jump-scare on Hard.
