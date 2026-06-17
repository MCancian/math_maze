extends CanvasLayer

@onready var keys_label: Label = $KeysLabel
@onready var message_label: Label = $MessageLabel

func _ready() -> void:
    GameManager.keys_changed.connect(update_keys)
    update_keys(GameManager.keys_collected, GameManager.keys_required)
    message_label.text = ""
    message_label.modulate.a = 0.0

func update_keys(collected: int, required: int) -> void:
    keys_label.text = "Keys: %d / %d" % [collected, required]
    
func show_message(text: String) -> void:
    message_label.text = text
    var tween = create_tween()
    tween.tween_property(message_label, "modulate:a", 1.0, 0.2)
    tween.tween_property(message_label, "modulate:a", 0.0, 0.5).set_delay(2.0)
