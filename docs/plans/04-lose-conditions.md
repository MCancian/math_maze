# Lose Conditions

**Status:** 🔜 Future

Today there is no way to lose — `MazeConfig.time_limit` exists but nothing reads
it, and the Lose screen is unreachable.

## Options

- **Timer:** count down from `time_limit`; hit zero → `GameManager.lose()`. HUD
  shows remaining time. Per maze difficulty.
- **Lives / wrong-answer budget:** N wrong math answers ends the run.
- **Both**, configured per difficulty.

## Notes

- `GameManager.lose()` + `scenes/ui/lose.tscn` already exist; just need a
  trigger and a HUD element.
- Keep it gentle for grade-school kids — generous timer, or make it opt-in per
  difficulty (Easy = no limit).
