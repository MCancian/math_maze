extends Node

const GENERATED_LEVEL := preload("res://scenes/levels/level_generated.tscn")
const MATH_UI := preload("res://scenes/ui/math_problem.tscn")
const MAIN_MENU := preload("res://scenes/ui/main_menu.tscn")
const ADDITION := preload("res://data/math/addition.tres")
const EASY_MAZE := preload("res://data/maze/maze_easy.tres")
const MEDIUM_MAZE := preload("res://data/maze/maze_medium.tres")
const HARD_MAZE := preload("res://data/maze/maze_hard.tres")
const GEN_05 := preload("res://data/levels/gen_05.tres")

var _failures: Array[String] = []

func _ready() -> void:
    await _run()

func _run() -> void:
    _test_main_menu_instantiates()
    await _test_math_problem_input()
    _test_key_loss_clamps()
    _test_monster_config_gates()
    await _test_monster_runtime(EASY_MAZE, "easy", "bee", false, 2.2)
    await _test_monster_runtime(MEDIUM_MAZE, "medium", "slime", false, 3.0)
    await _test_monster_runtime(HARD_MAZE, "hard", "horror", true, 4.2)
    _finish()

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _finish() -> void:
    if _failures.is_empty():
        print("Runtime gameplay tests passed")
        get_tree().quit(0)
        return
    for failure in _failures:
        push_error(failure)
    get_tree().quit(1)

func _test_main_menu_instantiates() -> void:
    var main_menu := MAIN_MENU.instantiate()
    add_child(main_menu)
    _check(main_menu != null, "main menu should instantiate")
    main_menu.queue_free()

func _test_math_problem_input() -> void:
    GameManager.math = ADDITION
    var ui := MATH_UI.instantiate()
    add_child(ui)
    await get_tree().process_frame

    ui.show_problem()
    ui.answer_input.text = "12abc/3-+=x"
    ui._on_answer_text_changed(ui.answer_input.text)
    _check(ui.answer_input.text == "12/3", "math input should keep only digits and slashes")

    var wrong_count := {"value": 0}
    ui.wrong_answer.connect(func() -> void: wrong_count["value"] += 1)
    ui.current_answer = 4
    ui.current_question_text = "What is 2 + 2?"
    ui.answer_input.text = "5"
    ui._check_answer()
    _check(wrong_count["value"] == 1, "wrong answer should emit wrong_answer once")
    _check(ui.question_label.text.find("What is 2 + 2?") >= 0, "wrong answer should show the original question again")

    var solved_count := {"value": 0}
    ui.solved.connect(func() -> void: solved_count["value"] += 1)
    ui.current_answer = 4
    ui.answer_input.text = "4/1"
    ui._check_answer()
    _check(solved_count["value"] == 1, "slash answer equivalent to whole number should solve")

    ui.queue_free()
    await get_tree().process_frame

func _test_key_loss_clamps() -> void:
    GameManager.reset_run(3)
    GameManager.collect_key()
    GameManager.collect_key()
    GameManager.lose_key()
    _check(GameManager.keys_collected == 1, "lose_key should remove one collected key")
    GameManager.lose_key()
    GameManager.lose_key()
    _check(GameManager.keys_collected == 0, "lose_key should clamp at zero")

func _test_monster_config_gates() -> void:
    _check(EASY_MAZE.allows_monster(), "easy maze should allow friendly bee monster")
    _check(MEDIUM_MAZE.allows_monster(), "medium maze should allow monster")
    _check(HARD_MAZE.allows_monster(), "hard maze should allow monster")
    _check(EASY_MAZE.monster_bee_visual, "easy monster should use bee visual")
    _check(not EASY_MAZE.monster_sound_enabled, "easy monster should not play sound")
    _check(not MEDIUM_MAZE.monster_bee_visual, "medium monster should not use bee visual")
    _check(not MEDIUM_MAZE.monster_scary_visual, "medium monster should keep slime visual")
    _check(not MEDIUM_MAZE.monster_sound_enabled, "medium monster should not play sound")
    _check(HARD_MAZE.monster_scary_visual, "hard monster should use scary visual")
    _check(HARD_MAZE.monster_sound_enabled, "hard monster should play sound")
    _check(HARD_MAZE.monster_speed > MEDIUM_MAZE.monster_speed, "hard monster should be faster than medium")

func _test_monster_runtime(maze_cfg: MazeConfig, label: String, expected_visual: String, expect_sound: bool, expected_speed: float) -> void:
    GameManager.current_level = GEN_05
    GameManager.maze = maze_cfg
    GameManager.math = ADDITION
    GameManager.reset_run(1)

    var level := GENERATED_LEVEL.instantiate()
    add_child(level)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame

    var monsters := get_tree().get_nodes_in_group("monster")
    _check(monsters.size() == 1, "%s maze should spawn exactly one monster" % label)
    if monsters.size() == 1:
        var monster: Node = monsters[0]
        _check(is_equal_approx(monster.speed, expected_speed), "%s monster speed should match config" % label)
        _check(monster.get_node("Visual/Bee").visible == (expected_visual == "bee"), "%s monster bee visibility should match config" % label)
        _check(monster.get_node("Visual/Slime").visible == (expected_visual == "slime"), "%s monster slime visibility should match config" % label)
        _check(monster.get_node("Visual/Horror").visible == (expected_visual == "horror"), "%s monster horror visibility should match config" % label)
        _check(monster.get_node("Visual/Shadow").visible == false, "%s monster shadow fallback should stay hidden" % label)
        _check(monster.get_node("HardSound").playing == expect_sound, "%s monster sound state should match config" % label)
        if expected_visual == "horror":
            var animation_player: AnimationPlayer = monster._find_animation_player(monster.get_node("Visual/Horror"))
            _check(animation_player != null, "hard horror monster should import an AnimationPlayer")
            if animation_player != null:
                _check(not animation_player.get_animation_list().is_empty(), "hard horror monster should have animation clips")

    remove_child(level)
    level.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame
