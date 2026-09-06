# Music

**Status:** ✅ Implemented (2026-09-06)

Plan 12 shipped procedural SFX and left `AudioManager.play_music` a no-op. This fills
it in, in the same no-assets style: tunes are described as notes and synthesised.

## Shipped

- `autoload/audio_manager.gd` gained a music layer. A track is
  `{bpm, beats, parts:[{voice, gain, notes}]}` where a note is
  `[start_beat, midi, length_beats]`; `_render_music` sums the parts into one buffer,
  normalises to `MUSIC_PEAK`, and returns a fully looping `AudioStreamWAV`.
  Voices: `sine`, `pluck`, `bell`, `bass`, `pad`.
- Four tracks, built by `_build_tracks()`: `menu` (calm C-Am-F-G music box, 20 s),
  `explore` (bouncy major-key march for lit mazes, 14.5 s), `spooky` (A-minor tiptoe
  for dark mazes — cartoon-spooky, not frightening, 18.5 s), `victory` (win fanfare,
  6.7 s).
- Public API: `play_music(name)`, `stop_music()`, `get_music(name)`,
  `current_music()`, `is_music_playing()`, `set_music_muted(bool)`, `toggle_music()`,
  `music_track_names()`.
- `MazeConfig.music_track` picks the in-maze tune (Easy `explore`, Medium and Hard
  `spooky`). `GameManager` starts `menu` on every menu-side screen, the maze track in
  `start_level`, and `victory` on a win; `main_menu.gd` starts `menu` at boot since
  that scene is not reached through `goto_menu`.
- Mute on **Ctrl+M** (`music_toggle`) or the Main Menu's Music button, persisted to
  `user://settings.cfg`.
- Runtime coverage in `tools/test_runtime.gd` `_test_music`.

## Decisions recorded

- **Threaded render:** tracks are 7-20 seconds, and the longest takes ~1.4 s to
  synthesise — a visible freeze if done inline. `play_music` sets the wanted track and
  `_process_music` renders it on a `WorkerThreadPool` task, starting playback when it
  lands. Rendered streams are cached, so a track only costs that once.
- **Lazy, not at boot:** unlike SFX, music renders on first use. Nothing pays for
  tracks it never hears.
- **Ctrl+M, not M:** plan 08 reserves M for the map overlay.
- **Mute in `user://settings.cfg`, not `SaveManager`:** it is a device preference, not
  per-profile progress.
- **Music at -11 dB** so the math prompt sounds stay on top of it.

## Follow-ups

- A volume slider (the follow-up plan 12 left open) now that there are two layers.
- Ducking the music while a math problem is open.
- Loop `beats` must stay a whole number of bars with no note crossing the end, or the
  loop clicks; a guard in `_render_music` would make that harder to get wrong.
