# Dark Maze + Flashlight

**Status:** ✅ Implemented (2026-09-06)

Make the Hard maze scary through darkness rather than the monster model: the sun goes
out, black fog swallows the corridors, and the player carries a flashlight with a
limited battery. A dead battery is recharged by solving a math problem, so the fear
mechanic also adds arithmetic practice.

## Shipped

- `MazeConfig.dark_maze` / `MazeConfig.flashlight_seconds` (`data/maze/maze_config.gd`).
  Hard sets `dark_maze = true`, `flashlight_seconds = 30`. Easy and Medium stay lit.
- `level_generated.gd` `_apply_darkness()`: duplicates the scene `Environment`, sets
  near-zero ambient light, dense black fog, and hides the `Sun`. Duplication keeps the
  shared scene resource lit for the next non-dark level.
- `player.tscn` `Head/Camera3D/Flashlight` (`SpotLight3D`, shadows on) driven by
  `player.gd`: `_press_flashlight` toggles on the `flashlight` input action (**F**),
  `_process` drains the charge and flickers the beam under six seconds, a dead battery
  plus F opens a `math_problem.tscn` prompt, and `_on_flashlight_charged` refills it.
  Wrong answers keep the prompt open with no key penalty.
- `GameManager.flashlight_changed` + `set_flashlight_state` mirror the state; the HUD
  `FlashlightLabel` shows seconds left, "off", or "dead - press F".
- `key.gd` `_glow()` gives orbs an emissive material in dark mazes so they remain
  findable without the beam.
- Runtime coverage in `tools/test_runtime.gd` (`_test_dark_maze_runtime`,
  `_test_lit_maze_after_dark`).

## Decisions recorded

- **Gating:** darkness is a `MazeConfig` knob, on for Hard only. Flip `dark_maze` on
  Medium to extend it.
- **Battery:** drains only while on and the player is not in a prompt, so kids can
  conserve it by switching off. Starts full on spawn.
- **Recharge:** any math problem from the current `MathConfig`; the prompt blocks
  movement like key and monster prompts do. The monster keeps hunting meanwhile.

## Follow-ups

- Sound design (heartbeat scaling with monster distance) and a catch jump-scare were
  suggested alongside this plan and remain unplanned.
