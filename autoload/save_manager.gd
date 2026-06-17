extends Node
## Persists player progress to user://save.json as up to 3 named profiles.
## Each profile keeps its chosen math/maze difficulty, unlock progress, the level
## to resume, and a per-level best record (time + stars). Stars accumulate toward
## a future spend system (upgrades, etc.).

const SAVE_PATH := "user://save.json"
const NUM_SLOTS := 3

## Fixed-size array; each entry is a profile Dictionary or null (empty slot).
## Treat as private storage; use the intent-named helpers below from other scripts.
var profiles: Array = [null, null, null]
var active_slot: int = -1

func _ready() -> void:
    load_game()

## --- Profile access ---

func has_profile(slot: int) -> bool:
    return slot >= 0 and slot < NUM_SLOTS and profiles[slot] != null

func any_profiles() -> bool:
    for p in profiles:
        if p != null:
            return true
    return false

func has_active_profile() -> bool:
    return has_profile(active_slot)

func set_active(slot: int) -> void:
    if has_profile(slot):
        active_slot = slot

func profile_summary(slot: int) -> Dictionary:
    if not has_profile(slot):
        return {}
    var p: Dictionary = profiles[slot]
    return {
        "name": String(p.get("name", "?")),
        "current": int(p.get("current", 1)),
        "total_stars": int(p.get("total_stars", 0)),
    }

## Returns the active profile, or an empty dict if none (dev/test paths).
## Prefer the helpers below so save-file keys stay centralized here.
func active() -> Dictionary:
    if active_slot >= 0 and active_slot < NUM_SLOTS and profiles[active_slot] != null:
        return profiles[active_slot]
    return {}

func active_math_path(default_path: String = "") -> String:
    var p := active()
    if p.is_empty():
        return default_path
    return String(p.get("math", default_path))

func active_maze_path(default_path: String = "") -> String:
    var p := active()
    if p.is_empty():
        return default_path
    return String(p.get("maze", default_path))

func current_order(default_order: int = 1) -> int:
    var p := active()
    if p.is_empty():
        return default_order
    return int(p.get("current", default_order))

func new_profile(slot: int, profile_name: String, math_path: String, maze_path: String) -> void:
    if slot < 0 or slot >= NUM_SLOTS:
        return
    profiles[slot] = {
        "name": profile_name,
        "math": math_path,
        "maze": maze_path,
        "unlocked": 1,
        "current": 1,
        "total_stars": 0,
        "best": {},
    }
    active_slot = slot
    save_game()

## --- Progress ---

func set_difficulty(math_path: String, maze_path: String) -> void:
    var p := active()
    if p.is_empty():
        return
    p["math"] = math_path
    p["maze"] = maze_path
    save_game()

func set_current(order: int) -> void:
    var p := active()
    if p.is_empty():
        return
    p["current"] = order
    save_game()

func best_for(level_id: StringName) -> Dictionary:
    var p := active()
    if p.is_empty():
        return {}
    var best: Dictionary = p.get("best", {})
    var rec: Dictionary = best.get(String(level_id), {})
    return rec.duplicate()

func is_unlocked(order: int) -> bool:
    var p := active()
    var unlocked: int = p.get("unlocked", 1) if not p.is_empty() else 1
    return order <= unlocked

func unlock(order: int) -> void:
    var p := active()
    if p.is_empty():
        return
    p["unlocked"] = max(int(p.get("unlocked", 1)), order)
    save_game()

## Records a finished level on the active profile: keeps the best (lowest) time
## and the best (highest) star count per level, then recomputes total stars.
func record_result(level_id: StringName, time: float, stars: int) -> void:
    var p := active()
    if p.is_empty():
        return
    var best: Dictionary = p.get("best", {})
    var key := String(level_id)
    var rec: Dictionary = best.get(key, {})
    if rec.is_empty():
        rec = {"time": time, "stars": stars}
    else:
        rec["time"] = min(float(rec.get("time", time)), time)
        rec["stars"] = max(int(rec.get("stars", 0)), stars)
    best[key] = rec
    p["best"] = best
    var total := 0
    for k in best:
        total += int(best[k].get("stars", 0))
    p["total_stars"] = total
    save_game()

## --- Persistence ---

func load_game() -> void:
    profiles = [null, null, null]
    active_slot = -1
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        return
    var text := f.get_as_text()
    f.close()
    var data: Variant = JSON.parse_string(text)
    if typeof(data) != TYPE_DICTIONARY:
        return  # missing/corrupt → empty slots, no crash
    var loaded: Array = data.get("profiles", [])
    for i in NUM_SLOTS:
        if i < loaded.size() and typeof(loaded[i]) == TYPE_DICTIONARY:
            profiles[i] = loaded[i]
    var a := int(data.get("active", -1))
    if has_profile(a):
        active_slot = a

func save_game() -> void:
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f == null:
        return
    f.store_string(JSON.stringify({"active": active_slot, "profiles": profiles}))
    f.close()
