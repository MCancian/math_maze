# Levels and progression

## Requirements

### Levels

- There are five generated levels, Level 1 to Level 5.
- Each level has a fixed seed, so its layout is the same every time it is played.
- A level's layout is fixed per seed **and** per chosen maze difficulty: Level 3 at Easy
  and Level 3 at Hard are two different mazes, but each of those is always the same.
- Levels unlock in order. Winning a level unlocks the next one.

### Profiles

- There are three named profile slots. A new game names a profile into one of them.
- A profile remembers its math and maze choice, the highest level unlocked, the level to
  resume, and, for each level, the best time and the best star count.
- **Continue** picks a profile and resumes its current level with its saved difficulty.
- **Level Select** is reached only in the New Game flow today, right after choosing
  difficulty.

### Best times and stars

- A win records the finishing time. The best time per level is kept.
- One to three stars are awarded from the time: under 30 seconds earns 3, under
  60 seconds earns 2, anything slower earns 1. The best star count per level is kept.
- A profile's total stars is the sum of its best stars across levels. Stars are shown
  but cannot be spent.

## Decisions

- **Records per level, not per difficulty.** One best time and one star count per level
  keeps the level list simple to read; the difficulty a record was set at is not tracked.
- **Three fixed slots.** Enough for the children of one household, with no account
  management.
- **Stars are banked, not spent.** They are reserved for a future spend system; there is
  deliberately no placeholder currency or score until that system is designed.
- **Fixed seeds.** A layout a child can learn makes best times fair.

## Planned

- **bonus-problems-and-coins** — replaying an earlier unlocked level, a coins currency, and spending stars or coins.
- **levels-and-visuals** — levels differing by more than their seed, such as a ramp in maze size across levels.
