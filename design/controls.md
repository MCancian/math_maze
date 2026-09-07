# Controls

## Requirements

### Moving

- **W A S D** — walk.
- **Mouse** — look around. The mouse is captured while playing.
- **Escape** — release the mouse, or capture it again.

### Interacting

- Walking into an orb, the exit door, or the monster triggers it. No key press is needed.
- **E** is bound as "interact", but nothing listens to it today.
- **F** — flashlight on or off; with a dead battery, opens the recharge problem.
- **Ctrl+M** — mute or unmute the music.
- **M** — reserved for the map overlay; does nothing today.

### Answering a problem

- Type the answer. The box accepts only digits and a slash.
- **Enter** or the Submit button checks it.
- Movement and looking are frozen while a prompt is open, and the mouse is released so
  the Submit button can be clicked.

## Decisions

- **Touch, not press.** Kids should not have to learn an interaction key; walking into a
  thing is the whole interface.
- **Digits and a slash only.** The box cannot be filled with text that could never be a
  right answer.
- **Frozen during a prompt**, so a problem is solved standing still and the monster's
  catch cannot be walked out of.

## Planned

- **map-overlay** — the M key shows a map of visited corridors.
