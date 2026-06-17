extends Control
## Name a profile and pick one of 3 save slots, then move on to difficulty select.

@onready var name_edit: LineEdit = $VBox/NameEdit
@onready var slots: Array[Button] = [
    $VBox/SlotRow/Slot0, $VBox/SlotRow/Slot1, $VBox/SlotRow/Slot2,
]
@onready var next_button: Button = $VBox/NextButton
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    for i in slots.size():
        var b := slots[i]
        if SaveManager.has_profile(i):
            b.text = "%s (overwrite)" % SaveManager.profile_summary(i).get("name", "?")
        b.toggled.connect(func(_p): _refresh())
    name_edit.text_changed.connect(func(_t): _refresh())
    next_button.pressed.connect(_on_next)
    back_button.pressed.connect(GameManager.goto_menu)
    name_edit.grab_focus()

func _selected_slot() -> int:
    for i in slots.size():
        if slots[i].button_pressed:
            return i
    return -1

func _refresh() -> void:
    next_button.disabled = name_edit.text.strip_edges().is_empty() or _selected_slot() < 0

func _on_next() -> void:
    var slot := _selected_slot()
    if slot < 0:
        return
    SaveManager.new_profile(
        slot, name_edit.text.strip_edges(),
        GameManager.DEFAULT_MATH.resource_path, GameManager.DEFAULT_MAZE.resource_path,
    )
    GameManager.goto_difficulty_select()
