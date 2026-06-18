# Testing

Run the headless suite from the repo root:

```bash
./tools/run_tests.sh
```

The script runs:

1. `godot --headless --editor --quit --path .` — registers global classes and imports
   assets.
2. `tools/test_save_and_level.gd` — save/profile helpers and `LevelData.stars_for`.
3. `tools/test_runtime.tscn` — runtime scene tests with autoloads loaded.

`tools/test_runtime.gd` covers current gameplay regressions:

- Main menu instantiates.
- Math answer input keeps only digits and `/`.
- Wrong answers show the original question again.
- Slash answers equivalent to whole numbers solve.
- `GameManager.lose_key()` clamps at zero.
- Monster gates for Easy/Medium/Hard.
- Easy monster spawns as a slow bee with no sound.
- Medium monster spawns as slime with no sound.
- Hard monster spawns faster, as animated horror model, with sound enabled.

Prefer adding new runtime coverage to `tools/test_runtime.gd` when behavior depends on
autoloads, scenes, groups, or signals. Keep pure data/persistence checks in
`tools/test_save_and_level.gd`.
