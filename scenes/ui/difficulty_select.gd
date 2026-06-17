extends Control
## Pick math difficulty and maze difficulty independently, then Start.

@onready var math_buttons: Array[Button] = [
    $VBox/MathRow/AdditionButton,
    $VBox/MathRow/MultiplicationButton,
    $VBox/MathRow/FractionsButton,
]
@onready var maze_buttons: Array[Button] = [
    $VBox/MazeRow/MazeEasyButton,
    $VBox/MazeRow/MazeMediumButton,
    $VBox/MazeRow/MazeHardButton,
]
@onready var start_button: Button = $VBox/StartButton
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    start_button.pressed.connect(_on_start)
    back_button.pressed.connect(GameManager.goto_menu)
    start_button.grab_focus()

func _selected_math() -> MathConfig:
    for i in math_buttons.size():
        if math_buttons[i].button_pressed:
            return GameManager.MATH_CONFIGS[i] as MathConfig
    return GameManager.DEFAULT_MATH

func _selected_maze() -> MazeConfig:
    for i in maze_buttons.size():
        if maze_buttons[i].button_pressed:
            return GameManager.MAZE_CONFIGS[i] as MazeConfig
    return GameManager.DEFAULT_MAZE

func _on_start() -> void:
    var math_cfg := _selected_math()
    var maze_cfg := _selected_maze()
    GameManager.math = math_cfg
    GameManager.maze = maze_cfg
    SaveManager.set_difficulty(math_cfg.resource_path, maze_cfg.resource_path)
    GameManager.goto_level_select()
