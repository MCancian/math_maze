extends SceneTree

func _init() -> void:
    var am = load("res://autoload/audio_manager.gd").new()
    get_root().add_child(am)
    await process_frame
    var out := "user://music_dump"
    DirAccess.make_dir_recursive_absolute(out)
    for track in ["menu", "explore", "spooky", "dread", "victory"]:
        var wav: AudioStreamWAV = am.get_music(track)
        var path := "%s/%s.wav" % [out, track]
        wav.save_to_wav(path)
        print("wrote ", ProjectSettings.globalize_path(path), " len=", wav.get_length())
    quit()
