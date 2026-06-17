extends Control

@onready var new_game_button: Button = $VBox/NewGameButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    new_game_button.pressed.connect(GameManager.goto_new_game)
    continue_button.pressed.connect(GameManager.goto_profile_select)
    quit_button.pressed.connect(_on_quit)
    continue_button.disabled = not SaveManager.any_profiles()
    new_game_button.grab_focus()

func _on_quit() -> void:
    get_tree().quit()
