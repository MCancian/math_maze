extends Control

@onready var next_button: Button = $VBox/NextButton
@onready var play_again_button: Button = $VBox/PlayAgainButton
@onready var menu_button: Button = $VBox/MenuButton

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    next_button.pressed.connect(GameManager.next_level)
    play_again_button.pressed.connect(GameManager.restart_level)
    menu_button.pressed.connect(GameManager.goto_menu)
    if GameManager.has_next_level():
        next_button.grab_focus()
    else:
        next_button.visible = false
        play_again_button.grab_focus()
