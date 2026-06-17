extends SceneTree

const SAVE_PATH := "user://save.json"

var _failures: Array[String] = []
var _had_existing_save := false
var _existing_save_text := ""

func _init() -> void:
    _backup_existing_save()
    _test_level_stars()
    _test_save_manager_helpers()
    _restore_existing_save()

    if _failures.is_empty():
        print("SaveManager/LevelData tests passed")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _backup_existing_save() -> void:
    _had_existing_save = FileAccess.file_exists(SAVE_PATH)
    if _had_existing_save:
        var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
        if f == null:
            _had_existing_save = false
            return
        _existing_save_text = f.get_as_text()
        f.close()

func _restore_existing_save() -> void:
    if _had_existing_save:
        var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        if f != null:
            f.store_string(_existing_save_text)
            f.close()
    elif FileAccess.file_exists(SAVE_PATH):
        var dir := DirAccess.open("user://")
        if dir != null:
            dir.remove("save.json")

func _test_level_stars() -> void:
    var level := LevelData.new()
    level.star_thresholds = [10.0, 20.0]
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
    save_manager.free()
