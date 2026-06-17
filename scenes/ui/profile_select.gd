extends Control
## Continue: pick a saved profile, then jump straight into its current level with
## its saved difficulty.

@onready var slots: Array[Button] = [$VBox/Slot0, $VBox/Slot1, $VBox/Slot2]
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    var first_filled: Button = null
    for i in slots.size():
        var b := slots[i]
        if SaveManager.has_profile(i):
            var summary := SaveManager.profile_summary(i)
            b.text = "%s   Level %d · %d★" % [
                summary.get("name", "?"), int(summary.get("current", 1)), int(summary.get("total_stars", 0))]
            b.pressed.connect(_on_pick.bind(i))
            if first_filled == null:
                first_filled = b
        else:
            b.text = "Slot %d — Empty" % (i + 1)
            b.disabled = true
    back_button.pressed.connect(GameManager.goto_menu)
    if first_filled:
        first_filled.grab_focus()
    else:
        back_button.grab_focus()

func _on_pick(slot: int) -> void:
    SaveManager.set_active(slot)
    GameManager.resume_active()
