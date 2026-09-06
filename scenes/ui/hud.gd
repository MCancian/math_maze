extends CanvasLayer

@onready var keys_label: Label = $KeysLabel
@onready var monster_label: Label = $MonsterLabel
@onready var flashlight_label: Label = $FlashlightLabel
@onready var message_label: Label = $MessageLabel

func _ready() -> void:
    GameManager.keys_changed.connect(update_keys)
    GameManager.monster_state_changed.connect(update_monster)
    update_keys(GameManager.keys_collected, GameManager.keys_required)
    update_monster(GameManager.monster_active, GameManager.monster_cooldown_remaining)
    GameManager.flashlight_changed.connect(update_flashlight)
    update_flashlight(GameManager.flashlight_enabled, GameManager.flashlight_on, GameManager.flashlight_charge_remaining)
    message_label.text = ""
    message_label.modulate.a = 0.0

func update_keys(collected: int, required: int) -> void:
    keys_label.text = "Keys: %d / %d" % [collected, required]

func update_monster(active: bool, cooldown_remaining: float) -> void:
    if active:
        monster_label.text = "Monster: active"
        monster_label.modulate = Color(1.0, 0.45, 0.35, 1.0)
    elif cooldown_remaining > 0.0:
        monster_label.text = "Monster: back in %ds" % ceili(cooldown_remaining)
        monster_label.modulate = Color(0.55, 0.85, 1.0, 1.0)
    else:
        monster_label.text = ""

func update_flashlight(enabled: bool, on: bool, charge_remaining: float) -> void:
    if not enabled:
        flashlight_label.text = ""
    elif on:
        flashlight_label.text = "Flashlight: %ds" % ceili(charge_remaining)
        flashlight_label.modulate = Color(1.0, 0.92, 0.55, 1.0)
    elif charge_remaining > 0.0:
        flashlight_label.text = "Flashlight: off (%ds) - F" % ceili(charge_remaining)
        flashlight_label.modulate = Color(0.75, 0.75, 0.75, 1.0)
    else:
        flashlight_label.text = "Flashlight: dead - press F to solve and recharge"
        flashlight_label.modulate = Color(1.0, 0.4, 0.35, 1.0)

func show_message(text: String) -> void:
    message_label.text = text
    var tween = create_tween()
    tween.tween_property(message_label, "modulate:a", 1.0, 0.2)
    tween.tween_property(message_label, "modulate:a", 0.0, 0.5).set_delay(2.0)
