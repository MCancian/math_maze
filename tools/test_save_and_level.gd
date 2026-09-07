extends SceneTree
## Pure data/persistence checks, run WITHOUT autoloads (`godot --headless -s`), so every script
## under test is reached with load() + duck typing, never a class_name or autoload identifier.
##
## Run through tools/gate.sh (which isolates user:// via MM_USER_DIR). Direct:
##   godot --headless --path . -s res://tools/test_save_and_level.gd [-- --test=<_test_name>]
## Each test in _tests() runs standalone (own setup). A failure prints `FAIL: <test>: <message>`
## on stdout; the finish line is `SaveManager/LevelData tests: N failure(s)`; exit 0/1; an
## unknown --test name exits 2.

const UserDir := preload("res://autoload/user_dir.gd")

var save_path: String = UserDir.file("save.json")
var _failures: Array[String] = []
var _current := ""
var _had_existing_save := false
var _existing_save_text := ""

func _tests() -> Dictionary:
    return {
        "_test_level_stars": _test_level_stars,
        "_test_save_manager_helpers": _test_save_manager_helpers,
    }

func _init() -> void:
    var tests := _tests()
    var only := _requested_test()
    if only != "" and not tests.has(only):
        print("no test named '%s' in tools/test_save_and_level.gd" % only)
        quit(2)
        return
    _backup_existing_save()
    for test_name in tests:
        if only != "" and test_name != only:
            continue
        _current = test_name
        tests[test_name].call()
    _restore_existing_save()
    print("SaveManager/LevelData tests: %d failure(s)" % _failures.size())
    quit(0 if _failures.is_empty() else 1)

func _requested_test() -> String:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--test="):
            return arg.trim_prefix("--test=")
    return ""

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        print("FAIL: %s: %s" % [_current, message])
        push_error("%s: %s" % [_current, message])

## Belt and braces: the gate already redirects user://, and a bare run of this script outside it
## must still leave a real save.json exactly as it found it.
func _backup_existing_save() -> void:
    _had_existing_save = FileAccess.file_exists(save_path)
    if _had_existing_save:
        var f := FileAccess.open(save_path, FileAccess.READ)
        if f == null:
            _had_existing_save = false
            return
        _existing_save_text = f.get_as_text()
        f.close()

func _restore_existing_save() -> void:
    if _had_existing_save:
        var f := FileAccess.open(save_path, FileAccess.WRITE)
        if f != null:
            f.store_string(_existing_save_text)
            f.close()
    elif FileAccess.file_exists(save_path):
        DirAccess.remove_absolute(save_path)

func _test_level_stars() -> void:
    var level = load("res://data/levels/level_data.gd").new()
    var thresholds: Array[float] = [10.0, 20.0]
    level.star_thresholds = thresholds
    _check(level.stars_for(9.99) == 3, "stars_for should award 3 below first threshold")
    _check(level.stars_for(10.0) == 2, "stars_for should award 2 at first threshold")
    _check(level.stars_for(19.99) == 2, "stars_for should award 2 below second threshold")
    _check(level.stars_for(20.0) == 1, "stars_for should award 1 at second threshold")

func _test_save_manager_helpers() -> void:
    var save_manager = load("res://autoload/save_manager.gd").new()
    save_manager.profiles = [null, null, null]
    save_manager.active_slot = -1

    save_manager.new_profile(0, "Ada", "res://data/math/addition.tres", "res://data/maze/maze_easy.tres")
    _check(save_manager.has_active_profile(), "new_profile should activate its slot")

    var summary: Dictionary = save_manager.profile_summary(0)
    _check(summary.get("name") == "Ada", "profile_summary should expose name")
    _check(int(summary.get("current")) == 1, "profile_summary should expose current level")
    _check(int(summary.get("total_stars")) == 0, "profile_summary should expose total stars")

    save_manager.set_difficulty("res://data/math/fractions.tres", "res://data/maze/maze_hard.tres")
    _check(save_manager.active_math_path() == "res://data/math/fractions.tres", "set_difficulty should save math path")
    _check(save_manager.active_maze_path() == "res://data/maze/maze_hard.tres", "set_difficulty should save maze path")

    save_manager.set_current(3)
    _check(save_manager.current_order() == 3, "set_current should save current order")

    save_manager.record_result(&"gen_01", 20.0, 2)
    save_manager.record_result(&"gen_01", 25.0, 3)
    var rec: Dictionary = save_manager.best_for(&"gen_01")
    _check(is_equal_approx(float(rec.get("time")), 20.0), "best_for should keep lowest time")
    _check(int(rec.get("stars")) == 3, "best_for should keep highest stars")

    rec["stars"] = 0
    _check(int(save_manager.best_for(&"gen_01").get("stars")) == 3, "best_for should return a defensive copy")
    _check(int(save_manager.profile_summary(0).get("total_stars")) == 3, "record_result should recompute total stars")
    _check(FileAccess.file_exists(save_path), "save_game should write the save file at %s" % save_path)
    save_manager.free()
