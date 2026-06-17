extends Control
## Lists the levels for the active profile: unlocked ones show best time + stars and
## start on press; locked ones are disabled. Difficulty is already chosen (held on
## GameManager) before reaching here.

@onready var list: VBoxContainer = $VBox/List
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    var first_unlocked: Button = null
    for level in GameManager.LEVELS:
        var b := Button.new()
        b.custom_minimum_size = Vector2(0, 52)
        if SaveManager.is_unlocked(level.unlock_order):
            b.text = "%s%s" % [level.display_name, _record_suffix(SaveManager.best_for(level.id))]
            b.pressed.connect(GameManager.start_level.bind(GameManager.math, GameManager.maze, level))
            if first_unlocked == null:
                first_unlocked = b
        else:
            b.text = "%s  🔒" % level.display_name
            b.disabled = true
        list.add_child(b)
    back_button.pressed.connect(GameManager.goto_difficulty_select)
    if first_unlocked:
        first_unlocked.grab_focus()
    else:
        back_button.grab_focus()

func _record_suffix(rec: Dictionary) -> String:
    if rec.is_empty():
        return ""
    return "   %.1fs  %s" % [float(rec.get("time", 0.0)), "★".repeat(int(rec.get("stars", 0)))]
