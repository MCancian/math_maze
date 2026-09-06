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
    await _test_monster_runtime(HARD_MAZE, "hard", "shadow", true, 4.2)
    _test_dark_maze_config()
    await _test_dark_maze_runtime()
    await _test_lit_maze_after_dark()
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

func _test_dark_maze_config() -> void:
    _check(HARD_MAZE.dark_maze, "hard maze should be dark")
    _check(not EASY_MAZE.dark_maze, "easy maze should stay lit")
    _check(not MEDIUM_MAZE.dark_maze, "medium maze should stay lit")
    _check(HARD_MAZE.flashlight_seconds > 0.0, "hard flashlight needs a positive charge")
    _check(InputMap.has_action("flashlight"), "flashlight input action should exist")
    var f_bound := false
    for ev in InputMap.action_get_events("flashlight"):
        if ev is InputEventKey and ev.keycode == KEY_F:
            f_bound = true
    _check(f_bound, "flashlight action should be bound to F")

func _spawn_level(maze_cfg: MazeConfig) -> Node:
    GameManager.current_level = GEN_05
    GameManager.maze = maze_cfg
    GameManager.math = ADDITION
    GameManager.reset_run(1)
    var level := GENERATED_LEVEL.instantiate()
    add_child(level)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    return level

func _despawn_level(level: Node) -> void:
    remove_child(level)
    level.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame

func _player() -> Node:
    var players := get_tree().get_nodes_in_group("player")
    return players[0] if players.size() == 1 else null

func _test_dark_maze_runtime() -> void:
    var level: Node = await _spawn_level(HARD_MAZE)
    var env: Environment = level.get_node("WorldEnvironment").environment
    _check(env.fog_enabled, "dark maze should enable fog")
    _check(not level.get_node("Sun").visible, "dark maze should hide the sun")

    var player: Node = _player()
    _check(player != null, "dark maze should spawn one player")
    if player:
        var light: SpotLight3D = player.get_node("Head/Camera3D/Flashlight")
        _check(player.flashlight_enabled, "dark maze should enable the flashlight")
        _check(player.flashlight_on and light.visible, "flashlight should start on")
        _check(player.flashlight_charge > HARD_MAZE.flashlight_seconds - 1.0, "flashlight should start (nearly) fully charged")
        _check(GameManager.flashlight_enabled and GameManager.flashlight_on, "GameManager should mirror flashlight state")

        player._press_flashlight()
        _check(not player.flashlight_on and not light.visible, "F should turn the flashlight off")
        player._press_flashlight()
        _check(player.flashlight_on and light.visible, "F should turn the flashlight back on")

        var before: float = player.flashlight_charge
        player._process(1.0)
        _check(player.flashlight_charge < before, "flashlight should drain while on")

        player.flashlight_charge = 0.5
        player._process(1.0)
        _check(not player.flashlight_on and not light.visible, "flashlight should switch off when drained")
        _check(is_zero_approx(GameManager.flashlight_charge_remaining), "GameManager should report a dead battery")

        var hud_label: Label = player.get_node("HUD/FlashlightLabel")
        _check(hud_label.text.find("dead") >= 0, "HUD should say the flashlight is dead")

        player._press_flashlight()
        var ui: Control = player._flashlight_ui
        _check(player.is_interacting, "dead flashlight + F should open a math problem")
        _check(ui != null and ui.visible, "recharge prompt should be visible")
        if ui:
            ui.current_answer = 7
            ui.answer_input.text = "3"
            ui._check_answer()
            _check(player.is_interacting and is_zero_approx(player.flashlight_charge), "wrong answer should not recharge")
            ui.answer_input.text = "7"
            ui._check_answer()
            _check(not player.is_interacting, "correct answer should release the player")
            _check(player.flashlight_on and light.visible, "correct answer should turn the flashlight on")
            _check(is_equal_approx(player.flashlight_charge, HARD_MAZE.flashlight_seconds), "correct answer should fully recharge")

    var keys := get_tree().get_nodes_in_group("key")
    var glowing := 0
    for key in keys:
        for child in key.get_children():
            if child is MeshInstance3D and child.material_override != null:
                glowing += 1
    _check(keys.size() > 0 and glowing == keys.size(), "dark maze keys should glow")

    await _despawn_level(level)

func _test_lit_maze_after_dark() -> void:
    var level: Node = await _spawn_level(EASY_MAZE)
    var env: Environment = level.get_node("WorldEnvironment").environment
    _check(not env.fog_enabled, "lit maze after a dark one should have no fog (shared Environment must not be mutated)")
    _check(level.get_node("Sun").visible, "lit maze should keep the sun")
    var player: Node = _player()
    if player:
        _check(not player.flashlight_enabled, "lit maze should disable the flashlight")
        _check(not player.get_node("Head/Camera3D/Flashlight").visible, "lit maze flashlight should be hidden")
        _check(player.get_node("HUD/FlashlightLabel").text == "", "lit maze HUD should hide the flashlight label")
    await _despawn_level(level)

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
        _check(monster.get_node("Visual/Shadow").visible == (expected_visual == "shadow"), "%s monster shadow visibility should match config" % label)
        _check(monster.get_node("HardSound").playing == expect_sound, "%s monster sound state should match config" % label)
        if expected_visual == "shadow":
            _check(monster.get_node("Visual/Shadow/LeftEye").position.z > 0.0, "hard monster eyes should be on the front")
            _check(monster.get_node("Visual/Shadow/RightEye").position.z > 0.0, "hard monster eyes should be on the front")
            var body: MeshInstance3D = monster.get_node("Visual/Shadow/Body")
            var material := body.material_override as StandardMaterial3D
            _check(material != null and material.albedo_color.a < 1.0, "hard monster shadow should be transparent")

    remove_child(level)
    level.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame
