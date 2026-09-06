extends Control

@onready var new_game_button: Button = $VBox/NewGameButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var music_button: Button = $VBox/MusicButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    new_game_button.pressed.connect(GameManager.goto_new_game)
    continue_button.pressed.connect(GameManager.goto_profile_select)
    music_button.pressed.connect(_on_music)
    quit_button.pressed.connect(_on_quit)
    _refresh_music_button()
    # First scene at boot, so the menu theme starts here rather than in goto_menu.
    AudioManager.play_music(&"menu")
    continue_button.disabled = not SaveManager.any_profiles()
    new_game_button.grab_focus()

func _on_music() -> void:
    AudioManager.toggle_music()
    _refresh_music_button()

func _refresh_music_button() -> void:
    music_button.text = "Music: Off" if AudioManager.music_muted else "Music: On"

func _on_quit() -> void:
    get_tree().quit()
