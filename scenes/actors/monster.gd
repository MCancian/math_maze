extends Area3D

const CELL := 4.0
const UI_SCENE := preload("res://scenes/ui/math_problem.tscn")

enum State { ACTIVE, CAUGHT, COOLDOWN }

var maze_info: Dictionary = {}
var maze_cfg: MazeConfig
var links: Dictionary = {}
var speed := 3.4
var cooldown_seconds := 120.0
var cooldown_remaining := 0.0
var state: State = State.ACTIVE
var ui_instance: Control
var caught_player: Node
var _target_cell := Vector2i.ZERO
var _has_target := false
var _status_emit_timer := 0.0
var _bee_visual := false
var _scary_visual := false
var _sound_enabled := false
var _sound_playback: AudioStreamGeneratorPlayback
var _sound_phase := 0.0
var _pulse_phase := 0.0

@onready var visual: Node3D = $Visual
@onready var slime_visual: MeshInstance3D = $Visual/Slime
@onready var bee_visual: Node3D = $Visual/Bee
@onready var shadow_visual: Node3D = $Visual/Shadow
@onready var hard_sound: AudioStreamPlayer3D = $HardSound

func setup(info: Dictionary, cfg: MazeConfig) -> void:
    maze_info = info
    maze_cfg = cfg
    links = info.get("links", {})
    if cfg:
        speed = cfg.monster_speed
        cooldown_seconds = cfg.monster_cooldown_seconds
        _bee_visual = cfg.monster_bee_visual
        _scary_visual = cfg.monster_scary_visual
        _sound_enabled = cfg.monster_sound_enabled

func _ready() -> void:
    add_to_group("monster")
    body_entered.connect(_on_body_entered)
    ui_instance = UI_SCENE.instantiate()
    ui_instance.set_wrong_answer_message("Incorrect! You lost a key. Try again.")
    get_tree().root.call_deferred("add_child", ui_instance)
    ui_instance.solved.connect(_on_solved)
    ui_instance.wrong_answer.connect(_on_wrong_answer)
    _apply_visual_style()
    _setup_hard_sound()
    call_deferred("_activate")

func _exit_tree() -> void:
    if ui_instance and is_instance_valid(ui_instance):
        ui_instance.queue_free()

func _process(delta: float) -> void:
    match state:
        State.ACTIVE:
            _move_toward_player(delta)
            _update_hard_sound()
            GameManager.set_monster_state(true, 0.0)
        State.CAUGHT:
            _stop_hard_sound()
        State.COOLDOWN:
            _stop_hard_sound()
            cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)
            _status_emit_timer -= delta
            if _status_emit_timer <= 0.0:
                _status_emit_timer = 0.25
                GameManager.set_monster_state(false, cooldown_remaining)
            if cooldown_remaining <= 0.0:
                _respawn_far_from_player()

func _activate() -> void:
    state = State.ACTIVE
    visible = true
    monitoring = true
    if _sound_enabled and not hard_sound.playing:
        hard_sound.play()
        _sound_playback = hard_sound.get_stream_playback() as AudioStreamGeneratorPlayback
    _has_target = false
    GameManager.set_monster_state(true, 0.0)

func _move_toward_player(delta: float) -> void:
    var player := _player()
    if player == null or links.is_empty():
        return

    if not _has_target or _is_at_target():
        var current_cell := _world_cell(global_position)
        var player_cell := _world_cell(player.global_position)
        _target_cell = _next_step(current_cell, player_cell)
        _has_target = true

    var target := _cell_world(_target_cell, global_position.y)
    var before := global_position
    global_position = global_position.move_toward(target, speed * delta)
    if before.distance_squared_to(global_position) > 0.0001:
        look_at(Vector3(target.x, global_position.y, target.z), Vector3.UP, true)
    visual.position.y = 0.1 + sin(Time.get_ticks_msec() / 160.0) * 0.08

func _is_at_target() -> bool:
    var target := _cell_world(_target_cell, global_position.y)
    var flat := Vector2(global_position.x - target.x, global_position.z - target.z)
    return flat.length() <= 0.1

func _apply_visual_style() -> void:
    bee_visual.visible = _bee_visual and not _scary_visual
    slime_visual.visible = not _bee_visual and not _scary_visual
    shadow_visual.visible = _scary_visual

func _setup_hard_sound() -> void:
    if not _sound_enabled:
        return
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = 11025.0
    stream.buffer_length = 0.25
    hard_sound.stream = stream
    hard_sound.volume_db = -10.0
    hard_sound.max_distance = 32.0
    hard_sound.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

func _update_hard_sound() -> void:
    if not _sound_enabled:
        return
    if not hard_sound.playing:
        hard_sound.play()
        _sound_playback = hard_sound.get_stream_playback() as AudioStreamGeneratorPlayback
    if _sound_playback == null:
        return
    var frames_available := _sound_playback.get_frames_available()
    var sample_rate := 11025.0
    var player := _player()
    var proximity := 0.35
    if player:
        var distance := global_position.distance_to(player.global_position)
        proximity = clampf(1.0 - distance / 36.0, 0.18, 0.85)
    for i in frames_available:
        _sound_phase = fmod(_sound_phase + TAU * 58.0 / sample_rate, TAU)
        _pulse_phase = fmod(_pulse_phase + TAU * 1.7 / sample_rate, TAU)
        var pulse := pow(maxf(sin(_pulse_phase), 0.0), 6.0)
        var growl := sin(_sound_phase) * 0.22 + sin(_sound_phase * 0.52) * 0.16
        var sample := growl * (0.25 + pulse * 0.75) * proximity
        _sound_playback.push_frame(Vector2(sample, sample))

func _stop_hard_sound() -> void:
    if _sound_enabled and hard_sound.playing:
        hard_sound.stop()

func _on_body_entered(body: Node3D) -> void:
    if state != State.ACTIVE or not body.is_in_group("player"):
        return
    state = State.CAUGHT
    caught_player = body
    monitoring = false
    _has_target = false
    GameManager.set_monster_state(false, 0.0)
    body.set_interacting(true)
    ui_instance.show_problem()

func _on_wrong_answer() -> void:
    if GameManager.keys_collected > 0:
        GameManager.lose_key()
        ui_instance.set_wrong_answer_message("Incorrect! You lost a key. Try again.")
    else:
        ui_instance.set_wrong_answer_message("Incorrect! No key to lose. Try again.")

func _on_solved() -> void:
    if caught_player and is_instance_valid(caught_player):
        caught_player.set_interacting(false)
    caught_player = null
    _start_cooldown()

func _start_cooldown() -> void:
    state = State.COOLDOWN
    cooldown_remaining = cooldown_seconds
    visible = false
    monitoring = false
    _stop_hard_sound()
    _status_emit_timer = 0.0
    GameManager.set_monster_state(false, cooldown_remaining)

func _respawn_far_from_player() -> void:
    var player := _player()
    var origin: Vector2i = maze_info.get("entrance", Vector2i.ZERO)
    if player:
        origin = _world_cell(player.global_position)
    global_position = _cell_world(_farthest_cell_from(origin), global_position.y)
    _activate()

func _player() -> Node3D:
    var players := get_tree().get_nodes_in_group("player")
    if players.is_empty():
        return null
    return players[0] as Node3D

func _next_step(start: Vector2i, goal: Vector2i) -> Vector2i:
    if start == goal or not links.has(start):
        return start
    var queue: Array[Vector2i] = [start]
    var came := {start: start}
    while not queue.is_empty():
        var cell: Vector2i = queue.pop_front()
        for nb in links.get(cell, []):
            if came.has(nb):
                continue
            came[nb] = cell
            if nb == goal:
                var step: Vector2i = goal
                while came[step] != start:
                    step = came[step]
                return step
            queue.append(nb)
    return start

func _farthest_cell_from(start: Vector2i) -> Vector2i:
    if not links.has(start):
        return maze_info.get("entrance", Vector2i.ZERO) as Vector2i
    var dist := {start: 0}
    var queue: Array[Vector2i] = [start]
    var far := start
    while not queue.is_empty():
        var cell: Vector2i = queue.pop_front()
        for nb in links.get(cell, []):
            if dist.has(nb):
                continue
            dist[nb] = dist[cell] + 1
            if dist[nb] > dist[far]:
                far = nb
            queue.append(nb)
    return far

func _world_cell(pos: Vector3) -> Vector2i:
    var w: int = maze_info.get("w", 1)
    var h: int = maze_info.get("h", 1)
    var n: int = maze_info.get("n", 1)
    var gx := roundi(pos.x / CELL + (w - 1) / 2.0)
    var gy := roundi(pos.z / CELL + (h - 1) / 2.0)
    var cx := clampi(roundi((gx - 1) / 2.0), 0, n - 1)
    var cy := clampi(roundi((gy - 1) / 2.0), 0, n - 1)
    return Vector2i(cx, cy)

func _cell_world(cell: Vector2i, y: float) -> Vector3:
    var w: int = maze_info.get("w", 1)
    var h: int = maze_info.get("h", 1)
    return Vector3((2 * cell.x + 1 - (w - 1) / 2.0) * CELL, y, (2 * cell.y + 1 - (h - 1) / 2.0) * CELL)
