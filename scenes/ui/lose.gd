extends Control

@onready var try_again_button: Button = $VBox/TryAgainButton
@onready var menu_button: Button = $VBox/MenuButton

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    try_again_button.pressed.connect(GameManager.restart_level)
    menu_button.pressed.connect(GameManager.goto_menu)
    try_again_button.grab_focus()
