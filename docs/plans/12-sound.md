# Sound

**Status:** ✅ Implemented (2026-09-06)

The game shipped silent apart from the Hard monster's 58 Hz generator rumble, which
most speakers cannot reproduce. This plan fills the `AudioManager` stub with
procedurally synthesised sound effects so no audio assets are needed, and gives the
Hard monster a growl and heartbeat that can actually be heard.

## Shipped

- `autoload/audio_manager.gd` renders every effect into an `AudioStreamWAV` at boot
  (`_render` + one `_sfx_*` function per sound, 22050 Hz mono 16-bit). Public API:
  `play_sfx(name, volume_db)` over a pool of eight `AudioStreamPlayer`s,
  `get_stream(name)` for positional players, `has_sfx(name)`, and
  `set_heartbeat(intensity)` / `heartbeat_interval(intensity)`.
- Names: `correct`, `wrong` (math prompt), `key` (orb collected), `door` (exit opens),
  `flashlight_on` / `flashlight_off` / `flashlight_dead` (player F key and drain),
  `monster_catch` (stinger on catch), `heartbeat` (non-positional pulse), `growl`
  (2-second loop).
- `monster.gd`: `HardSound` now plays the `growl` loop positionally
  (inverse-distance, `unit_size` 6, `max_distance` 48). `_update_hard_sound` feeds
  `heartbeat_intensity(distance)` to `AudioManager.set_heartbeat`, which shortens the
  beat interval from 1.3 s to 0.42 s and raises volume as the monster closes in.
  Cooldown, catch, and level exit stop the heartbeat. Only `monster_sound_enabled`
  configs (Hard) use these.
- Runtime coverage in `tools/test_runtime.gd` (`_test_audio_manager`, plus growl
  and heartbeat checks in `_test_monster_runtime`).

## Decisions recorded

- **Procedural over assets:** keeps the repo free of audio licensing and lets each
  sound be tuned in code. Synthesis cost at boot is a few tens of milliseconds.
- **Speaker-safe design:** every effect keeps a meaningful share of its energy above
  150 Hz. The heartbeat is a low body plus a 230 Hz knock for that reason.
- **Growl range:** audible across a 9x9 Hard maze so players hear the monster before
  the flashlight finds it.

## Follow-ups

- ~~Music~~ — shipped in [14-music](14-music.md).
- Footsteps for the player and monster.
- A volume setting persisted through `SaveManager`.
