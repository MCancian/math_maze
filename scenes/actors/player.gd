extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const FLASHLIGHT_UI := preload("res://scenes/ui/math_problem.tscn")
## Below this many seconds of charge the beam flickers.
const FLASHLIGHT_FLICKER_BELOW := 6.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_sensitivity := 0.002
var is_interacting := false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

## Flashlight (dark mazes only, MazeConfig.dark_maze). F toggles; drains while on.
## Dead battery: F opens a math problem, correct answer refills it.
var flashlight_enabled := false
var flashlight_on := false
var flashlight_charge := 0.0
var flashlight_full := 30.0
var _flashlight_ui: Control
var _flashlight_base_energy := 4.0
var _flashlight_emit_timer := 0.0

## Breadcrumb trail: drop a floor marker every TRAIL_STEP units travelled so
## the player can see where they've already been.
const TRAIL_STEP := 2.0
var _last_crumb := Vector3.ZERO
var _crumb_mesh: CylinderMesh
var _crumb_mat: StandardMaterial3D

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    add_to_group("player")
    _last_crumb = global_position
    _crumb_mesh = CylinderMesh.new()
    _crumb_mesh.top_radius = 0.35
    _crumb_mesh.bottom_radius = 0.35
    _crumb_mesh.height = 0.04
    _crumb_mat = StandardMaterial3D.new()
    _crumb_mat.albedo_color = Color(0.25, 0.85, 1.0, 0.55)
    _crumb_mat.emission_enabled = true
    _crumb_mat.emission = Color(0.2, 0.7, 1.0)
    _crumb_mat.emission_energy_multiplier = 1.5
    _crumb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _setup_flashlight()

func _exit_tree() -> void:
    if _flashlight_ui and is_instance_valid(_flashlight_ui):
        _flashlight_ui.queue_free()

func _setup_flashlight() -> void:
    var cfg: MazeConfig = GameManager.maze
    flashlight_enabled = cfg != null and cfg.dark_maze
    _flashlight_base_energy = flashlight.light_energy
    if not flashlight_enabled:
        flashlight.visible = false
        GameManager.set_flashlight_state(false, false, 0.0)
        return
    flashlight_full = cfg.flashlight_seconds
    flashlight_charge = flashlight_full
    _flashlight_ui = FLASHLIGHT_UI.instantiate()
    _flashlight_ui.set_wrong_answer_message("Incorrect! Still dark. Try again.")
    get_tree().root.call_deferred("add_child", _flashlight_ui)
    _flashlight_ui.solved.connect(_on_flashlight_charged)
    _set_flashlight(true)

func _process(delta: float) -> void:
    if not flashlight_enabled or not flashlight_on or is_interacting:
        return
    flashlight_charge = maxf(flashlight_charge - delta, 0.0)
    if flashlight_charge <= 0.0:
        _set_flashlight(false)
        return
    if flashlight_charge < FLASHLIGHT_FLICKER_BELOW:
        flashlight.light_energy = _flashlight_base_energy * (0.35 + randf() * 0.65)
    _flashlight_emit_timer -= delta
    if _flashlight_emit_timer <= 0.0:
        _flashlight_emit_timer = 0.25
        _emit_flashlight()

func _press_flashlight() -> void:
    if not flashlight_enabled:
        return
    if flashlight_on:
        _set_flashlight(false)
    elif flashlight_charge > 0.0:
        _set_flashlight(true)
    else:
        set_interacting(true)
        _flashlight_ui.show_problem()

func _on_flashlight_charged() -> void:
    flashlight_charge = flashlight_full
    set_interacting(false)
    _set_flashlight(true)

func _set_flashlight(on: bool) -> void:
    flashlight_on = on and flashlight_charge > 0.0
    flashlight.visible = flashlight_on
    flashlight.light_energy = _flashlight_base_energy
    _flashlight_emit_timer = 0.25
    _emit_flashlight()

func _emit_flashlight() -> void:
    GameManager.set_flashlight_state(flashlight_enabled, flashlight_on, flashlight_charge)

func _drop_crumb() -> void:
    var holder := get_parent()
    if holder == null:
        return
    var crumb := MeshInstance3D.new()
    crumb.mesh = _crumb_mesh
    crumb.material_override = _crumb_mat
    crumb.add_to_group("trail")
    holder.add_child(crumb)
    crumb.global_position = Vector3(global_position.x, 0.06, global_position.z)

func _input(event: InputEvent) -> void:
    if is_interacting:
        return
        
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, -deg_to_rad(89), deg_to_rad(89))
        
    if event.is_action_pressed("flashlight"):
        _press_flashlight()

    if event.is_action_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
    if is_interacting:
        return
        
    if not is_on_floor():
        velocity.y -= gravity * delta

    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

    move_and_slide()

    var flat := Vector2(global_position.x - _last_crumb.x, global_position.z - _last_crumb.z)
    if flat.length() >= TRAIL_STEP:
        _last_crumb = global_position
        _drop_crumb()

func set_interacting(interacting: bool) -> void:
    is_interacting = interacting
    if interacting:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
