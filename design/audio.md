# Audio

## Requirements

Every sound and every tune is synthesised by the game at runtime. There are no audio
files in the repository.

### Sound effects

- Correct answer.
- Wrong answer.
- Key collected.
- Door opens.
- Flashlight on, flashlight off, and a dead click when the battery is empty.
- Monster catch stinger, on Hard.
- Heartbeat, on Hard: beats faster and louder continuously as the monster gets closer.
- Growl, on Hard: loops from the monster's position and fades with distance.

### Music

Five looping tunes:

- **menu** — a calm music box, on every menu screen.
- **explore** — a bouncy march, in lit mazes.
- **spooky** — a minor-key tiptoe, in Medium mazes.
- **dread** — a darker theme, in Hard mazes only.
- **victory** — a short fanfare on a win.

Music sits well under the sound effects so a prompt's sounds are always heard. A tune is
rendered in the background the first time it is needed, so nothing freezes, and is kept
for the rest of the session.

### Mute

Music is muted and unmuted with **Ctrl+M** or the Main Menu's Music button. The setting
is remembered per device, not per profile.

## Decisions

- **Procedural over assets.** No licensing, nothing to download, and every sound can be
  tuned in code.
- **Speaker-safe.** Each sound keeps a meaningful share of its energy above 150 Hz so it
  is audible on small laptop speakers, not only on headphones.
- **Ctrl+M, not M**, because M is reserved for the map overlay.
- **Mute is a device preference**, not profile progress, so it is stored with the
  device settings rather than in a save profile.

## Planned

- **audio-polish** — footsteps, a persisted volume slider, music ducking under a math prompt, a loop-length guard, and a catch jump-scare.
- **map-overlay** — the M key the mute binding steps around.
