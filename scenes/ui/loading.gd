extends Control
## Threaded-loads GameManager.pending_scene_path, then swaps to it.
## Real value lands in step 4 when levels are built from data (heavy loads).

@onready var progress_bar: ProgressBar = $VBox/ProgressBar

var _path: String = ""

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    _path = GameManager.pending_scene_path
    if _path == "":
        GameManager.goto_menu()
        return
    ResourceLoader.load_threaded_request(_path)

func _process(_delta: float) -> void:
    if _path == "":
        return
    var progress: Array = []
    var status := ResourceLoader.load_threaded_get_status(_path, progress)
    match status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            if progress.size() > 0:
                progress_bar.value = progress[0] * 100.0
        ResourceLoader.THREAD_LOAD_LOADED:
            var packed: PackedScene = ResourceLoader.load_threaded_get(_path)
            GameManager.pending_scene_path = ""
            _path = ""
            get_tree().change_scene_to_packed(packed)
        ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            push_error("Loading failed: " + _path)
            _path = ""
            GameManager.goto_menu()
