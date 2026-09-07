extends RefCounted
## Where the game's own files live: the save file and the device settings. Normally user://.
## When MM_USER_DIR names an absolute directory, every such file goes there instead:
## tools/gate.sh points it at a temp dir so the suite never touches the live saves, and a
## reviewer sandbox forces it to an empty decoy (revue.toml `decoy_env`).
## Why not XDG_DATA_HOME: ~/.local/bin/godot is the flatpak, whose sandbox overrides that
## variable with its own (measured 2026-09-07). Unset = user://, the shipped behaviour.
## Not an autoload: preload it by path so the -s harness (no autoloads) can use it too.

static func file(name: String) -> String:
    var dir := OS.get_environment("MM_USER_DIR")
    if dir.is_empty():
        return "user://" + name
    DirAccess.make_dir_recursive_absolute(dir)
    return dir.path_join(name)
