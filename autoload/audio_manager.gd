extends Node
## Procedural audio. Every sound is synthesised into an AudioStreamWAV, so there
## are no audio assets. play_sfx(name) for one-shots; get_stream(name) for
## positional players (monster growl); set_heartbeat(intensity) for the
## non-positional pulse that speeds up as the monster closes in.
##
## Music is a second layer: TRACKS describes each tune as notes, which
## _render_music turns into a seamless loop. Tracks render on first use (not at
## boot) because they are ~100x longer than an sfx. play_music(name) is a no-op
## if that track is already playing, so it rides across scene changes.

const RATE := 22050
const POOL_SIZE := 8

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _heartbeat: AudioStreamPlayer
var _heartbeat_intensity := 0.0
var _heartbeat_timer := 0.0

## Music sits well under the sfx so problem prompts stay audible.
const MUSIC_DB := -11.0
const UserDir := preload("res://autoload/user_dir.gd")
## user://settings.cfg, or MM_USER_DIR/settings.cfg when that variable is set (the gate, review sandboxes).
var settings_path: String = UserDir.file("settings.cfg")

var music_muted := false
var _music: AudioStreamPlayer
var _music_cache: Dictionary = {}
var _current_track: StringName = &""
var _tracks: Dictionary = {}
var _pending_track: StringName = &""
var _pending_stream: AudioStreamWAV
var _pending_task: int = -1

func _ready() -> void:
    _streams = {
        "correct": _render(0.32, _sfx_correct),
        "wrong": _render(0.4, _sfx_wrong),
        "key": _render(0.6, _sfx_key),
        "door": _render(1.2, _sfx_door),
        "flashlight_on": _render(0.08, _sfx_click.bind(1.0)),
        "flashlight_off": _render(0.08, _sfx_click.bind(0.6)),
        "flashlight_dead": _render(0.3, _sfx_dead_click),
        "monster_catch": _render(1.0, _sfx_stinger),
        "heartbeat": _render(0.5, _sfx_heartbeat),
        "growl": _render(2.0, _sfx_growl, true),
    }
    for i in POOL_SIZE:
        var p := AudioStreamPlayer.new()
        add_child(p)
        _pool.append(p)
    _heartbeat = AudioStreamPlayer.new()
    _heartbeat.stream = _streams["heartbeat"]
    add_child(_heartbeat)
    _music = AudioStreamPlayer.new()
    _music.volume_db = MUSIC_DB
    add_child(_music)
    _tracks = _build_tracks()
    _load_settings()

func get_stream(sfx_name: StringName) -> AudioStream:
    return _streams.get(sfx_name)

func play_sfx(sfx_name: StringName, volume_db: float = 0.0) -> void:
    var stream: AudioStream = _streams.get(sfx_name)
    if stream == null:
        push_warning("AudioManager: unknown sfx '%s'" % sfx_name)
        return
    var player := _free_player()
    player.stream = stream
    player.volume_db = volume_db
    player.play()

## --- music ---------------------------------------------------------------

## Sets the wanted track. If it is not rendered yet the work happens on a
## worker thread and _process starts playback when it lands, so switching
## scenes never blocks on a 1-second render.
func play_music(track_name: StringName) -> void:
    if not _tracks.has(track_name):
        push_warning("AudioManager: unknown music track '%s'" % track_name)
        return
    if track_name == _current_track:
        return
    _current_track = track_name
    _music.stop()
    if _music_cache.has(track_name) and not music_muted:
        _start_music()

func stop_music() -> void:
    _current_track = &""
    _music.stop()

func _start_music() -> void:
    _music.stream = _music_cache[_current_track]
    _music.play()

func _process_music() -> void:
    if _pending_task != -1:
        if not WorkerThreadPool.is_task_completed(_pending_task):
            return
        WorkerThreadPool.wait_for_task_completion(_pending_task)
        _pending_task = -1
        if _pending_stream:
            _music_cache[_pending_track] = _pending_stream
        _pending_stream = null
        _pending_track = &""
    if _current_track == &"" or music_muted or _music.playing:
        return
    if _music_cache.has(_current_track):
        _start_music()
    else:
        _pending_track = _current_track
        _pending_task = WorkerThreadPool.add_task(_render_pending)

## Runs on a worker thread; only reads _tracks and writes thread-local buffers.
func _render_pending() -> void:
    _pending_stream = _render_music(_tracks[_pending_track])

## A quit while a render is in flight would free this node under the worker
## ("Nonexistent function '_write_note' in base 'previously freed'"); wait for it.
func _exit_tree() -> void:
    if _pending_task != -1:
        WorkerThreadPool.wait_for_task_completion(_pending_task)
        _pending_task = -1

## Renders on first request and caches; null if the name is unknown.
func get_music(track_name: StringName) -> AudioStreamWAV:
    if _music_cache.has(track_name):
        return _music_cache[track_name]
    if not _tracks.has(track_name):
        return null
    var stream := _render_music(_tracks[track_name])
    _music_cache[track_name] = stream
    return stream

func current_music() -> StringName:
    return _current_track

func is_music_playing() -> bool:
    return _music.playing

func set_music_muted(muted: bool) -> void:
    music_muted = muted
    if muted:
        _music.stop()
    elif _current_track != &"" and _music_cache.has(_current_track):
        _start_music()
    _save_settings()

func toggle_music() -> void:
    set_music_muted(not music_muted)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("music_toggle"):
        toggle_music()

## 0 = silent, 1 = monster on top of you. Interval and volume follow it.
func set_heartbeat(intensity: float) -> void:
    _heartbeat_intensity = clampf(intensity, 0.0, 1.0)
    if _heartbeat_intensity <= 0.0:
        _heartbeat_timer = 0.0

func heartbeat_interval(intensity: float) -> float:
    return lerpf(1.3, 0.42, clampf(intensity, 0.0, 1.0))

func _process(delta: float) -> void:
    _process_music()
    _process_heartbeat(delta)

func _process_heartbeat(delta: float) -> void:
    if _heartbeat_intensity <= 0.0:
        return
    _heartbeat_timer -= delta
    if _heartbeat_timer <= 0.0:
        _heartbeat_timer = heartbeat_interval(_heartbeat_intensity)
        _heartbeat.volume_db = lerpf(-16.0, 2.0, _heartbeat_intensity)
        _heartbeat.pitch_scale = lerpf(0.9, 1.15, _heartbeat_intensity)
        _heartbeat.play()

func _free_player() -> AudioStreamPlayer:
    for p in _pool:
        if not p.playing:
            return p
    return _pool[0]

## --- synthesis -----------------------------------------------------------

## Renders fn(t, seconds) -> sample in [-1, 1] into a 16-bit mono WAV.
func _render(seconds: float, fn: Callable, loop: bool = false) -> AudioStreamWAV:
    var frames := int(seconds * RATE)
    var samples := PackedFloat32Array()
    samples.resize(frames)
    for i in frames:
        samples[i] = fn.call(float(i) / RATE, seconds)
    return _pack_wav(samples, loop)

## Packs samples in [-1, 1] into a 16-bit mono WAV, looping over the whole
## buffer when asked. The single place the loop points are set.
func _pack_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
    var frames := samples.size()
    var data := PackedByteArray()
    data.resize(frames * 2)
    for i in frames:
        data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = RATE
    wav.stereo = false
    wav.data = data
    if loop:
        wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
        wav.loop_begin = 0
        wav.loop_end = frames
    return wav

static func _env(t: float, attack: float, length: float) -> float:
    if t < attack:
        return t / attack
    return clampf(1.0 - (t - attack) / maxf(length - attack, 0.001), 0.0, 1.0)

static func _noise(t: float) -> float:
    return fmod(sin(t * 12345.678) * 43758.5453, 1.0) * 2.0 - 1.0

func _sfx_correct(t: float, _len: float) -> float:
    var f := 660.0 if t < 0.14 else 990.0
    var local := t if t < 0.14 else t - 0.14
    return sin(TAU * f * t) * _env(local, 0.005, 0.16) * 0.45

func _sfx_wrong(t: float, len: float) -> float:
    var f := lerpf(220.0, 150.0, t / len)
    var sq := signf(sin(TAU * f * t)) * 0.6 + sin(TAU * f * t) * 0.4
    return sq * _env(t, 0.01, len) * 0.35

func _sfx_key(t: float, _len: float) -> float:
    var notes := [880.0, 1108.0, 1318.0, 1760.0]
    var step := 0.11
    var idx := mini(int(t / step), notes.size() - 1)
    var local := t - idx * step
    var s := sin(TAU * notes[idx] * t) * _env(local, 0.004, 0.3)
    s += sin(TAU * notes[idx] * 2.0 * t) * _env(local, 0.004, 0.12) * 0.3
    return s * 0.4

func _sfx_door(t: float, len: float) -> float:
    var f := lerpf(70.0, 130.0, t / len)
    var rumble := sin(TAU * f * t) * 0.5 + sin(TAU * f * 2.01 * t) * 0.25
    var creak := sin(TAU * lerpf(900.0, 1400.0, t / len) * t + sin(t * 40.0) * 3.0) * 0.12
    var grit := _noise(t) * 0.18
    return (rumble + creak + grit) * _env(t, 0.05, len) * 0.7

func _sfx_click(t: float, len: float, gain: float) -> float:
    return (_noise(t) * 0.7 + sin(TAU * 1800.0 * t) * 0.3) * _env(t, 0.001, len) * 0.5 * gain

func _sfx_dead_click(t: float, _len: float) -> float:
    var local := t if t < 0.15 else t - 0.15
    return (_noise(t) * 0.4 + sin(TAU * 500.0 * t) * 0.4) * _env(local, 0.001, 0.05) * 0.5

func _sfx_stinger(t: float, len: float) -> float:
    var a := sin(TAU * 196.0 * t) + sin(TAU * 277.0 * t) + sin(TAU * 415.0 * t) * 0.6
    var shriek := sin(TAU * lerpf(2400.0, 900.0, t / len) * t) * 0.35
    var hiss := _noise(t) * 0.5 * _env(t, 0.002, 0.25)
    return (a * 0.3 + shriek + hiss) * _env(t, 0.005, len) * 0.9

func _sfx_heartbeat(t: float, _len: float) -> float:
    return _thump(t) + _thump(t - 0.18) * 0.8

## One heart thump: low body plus a mid-frequency knock so small speakers carry it.
static func _thump(t: float) -> float:
    if t < 0.0:
        return 0.0
    var body := sin(TAU * 80.0 * t) * _env(t, 0.005, 0.12) * 0.55
    var knock := sin(TAU * 230.0 * t) * _env(t, 0.002, 0.05) * 0.5
    var tick := _noise(t) * _env(t, 0.001, 0.015) * 0.3
    return (body + knock + tick) * 0.75

func _sfx_growl(t: float, len: float) -> float:
    var f := 85.0 + sin(TAU * t / len) * 6.0
    var s := 0.0
    for h in range(1, 7):
        s += sin(TAU * f * h * t + sin(t * 3.0) * 0.5) / (h * 0.9)
    var rasp := _noise(t) * 0.35
    var pulse := 0.55 + 0.45 * pow(maxf(sin(TAU * 4.0 * t), 0.0), 2.0)
    var breath := 0.6 + 0.4 * sin(TAU * t / len)
    return (s * 0.28 + rasp) * pulse * breath * 0.7

## --- settings ------------------------------------------------------------

func _load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(settings_path) != OK:
        return
    music_muted = bool(cfg.get_value("audio", "music_muted", false))

func _save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.load(settings_path)
    cfg.set_value("audio", "music_muted", music_muted)
    cfg.save(settings_path)

## --- music synthesis -----------------------------------------------------
##
## A track is {bpm, beats, parts:[{voice, gain, notes}]} where a note is
## [start_beat, midi, length_beats]. Parts are summed into one buffer and
## normalised, then looped end-to-end, so `beats` must be a whole number of bars
## and no note may run past it or the loop will click.

const BEATS_PER_BAR := 4
const MUSIC_PEAK := 0.82

func _render_music(spec: Dictionary) -> AudioStreamWAV:
    var beat: float = 60.0 / float(spec["bpm"])
    var frames := int(float(spec["beats"]) * beat * RATE)
    var buf := PackedFloat32Array()
    buf.resize(frames)
    for part in spec["parts"]:
        for note in part["notes"]:
            _write_note(buf, part["voice"], float(part["gain"]),
                _note_hz(int(note[1])), float(note[0]) * beat, float(note[2]) * beat)

    var peak := 0.0
    for v in buf:
        peak = maxf(peak, absf(v))
    var scale: float = (MUSIC_PEAK / peak) if peak > 0.0 else 0.0
    for i in frames:
        buf[i] *= scale
    return _pack_wav(buf, true)

func _write_note(buf: PackedFloat32Array, voice: String, gain: float, hz: float, start_s: float, length_s: float) -> void:
    var start := int(start_s * RATE)
    var count := mini(int(length_s * RATE), buf.size() - start)
    for i in count:
        var t := float(i) / RATE
        buf[start + i] += _voice(voice, hz, t, length_s) * gain

static func _note_hz(midi: int) -> float:
    return 440.0 * pow(2.0, (midi - 69) / 12.0)

## Short attack, quick release: nothing rings past its slot, so the loop is clean.
static func _note_env(t: float, length: float) -> float:
    var attack := 0.012
    var release := minf(0.09, length * 0.3)
    if t < attack:
        return t / attack
    if t > length - release:
        return maxf((length - t) / release, 0.0)
    return 1.0

static func _voice(voice: String, hz: float, t: float, length: float) -> float:
    var phase := TAU * hz * t
    var env := _note_env(t, length)
    match voice:
        "pluck":
            var decay: float = exp(-t * 4.5)
            return (sin(phase) + sin(phase * 2.0) * 0.35 + sin(phase * 3.0) * 0.12) * decay * env
        "bell":
            return (sin(phase) + sin(phase * 2.01) * 0.5 + sin(phase * 3.02) * 0.2) * exp(-t * 2.2) * env
        "bass":
            return (sin(phase) + sin(phase * 2.0) * 0.25) * env
        "pad":
            return (sin(phase) * 0.7 + sin(phase * 1.005) * 0.3) * env
        "drone":
            # Two detuned saw-ish tones beating against each other, plus a slow
            # swell: the unsettling bed under the dark-maze tracks.
            var beat_tone: float = sin(phase) * 0.5 + sin(phase * 1.014) * 0.4 + sin(phase * 2.0) * 0.12
            return beat_tone * (0.7 + 0.3 * sin(TAU * 0.23 * t)) * env
        "glass":
            # Inharmonic partials (2.76, 5.4) read as a music box gone wrong.
            return (sin(phase) + sin(phase * 2.76) * 0.3 + sin(phase * 5.4) * 0.1) * exp(-t * 2.6) * env
        "hiss":
            # Pitchless breath; hz only tilts how much tone bleeds through.
            return (_noise(t) * 0.8 + sin(phase) * 0.2) * (0.4 + 0.6 * sin(TAU * t / maxf(length, 0.001))) * env
        _:
            return sin(phase) * env

## --- tracks --------------------------------------------------------------

## Turns a bar of [midi, beats] steps into absolute-beat notes. midi -1 = rest.
static func _bar(index: int, pattern: Array) -> Array:
    var out: Array = []
    var cursor := float(index * BEATS_PER_BAR)
    for step in pattern:
        if int(step[0]) >= 0:
            out.append([cursor, int(step[0]), float(step[1])])
        cursor += float(step[1])
    return out

## Calls fn(bar_index, first_beat_of_bar, root) once per bar and concatenates
## the note arrays it returns, so a track builder states what it plays instead
## of re-counting beats.
static func _per_bar(roots: Array, fn: Callable) -> Array:
    var out: Array = []
    for bar in roots.size():
        out += fn.call(bar, float(bar * BEATS_PER_BAR), int(roots[bar])) as Array
    return out

static func _chord(beat: float, root: int, minor: bool, length: float) -> Array:
    var third := 3 if minor else 4
    return [[beat, root, length], [beat, root + third, length], [beat, root + 7, length]]

func _build_tracks() -> Dictionary:
    return {
        &"menu": _track_menu(),
        &"explore": _track_explore(),
        &"spooky": _track_spooky(),
        &"dread": _track_dread(),
        &"victory": _track_victory(),
    }

## Calm C-Am-F-G music box for menus and between-level screens.
func _track_menu() -> Dictionary:
    var roots := [36, 33, 29, 31, 36, 33, 29, 31]
    var minors := [false, true, false, false, false, true, false, false]
    var bass: Array = _per_bar(roots, func(_i: int, b: float, root: int) -> Array:
        return [[b, root, 1.8], [b + 2.0, root + 7, 1.8]])
    var pad: Array = _per_bar(roots, func(i: int, b: float, root: int) -> Array:
        return _chord(b, root + 24, minors[i], 3.7))
    var melody: Array = (
        _bar(0, [[72, 2], [76, 1], [74, 1]])
        + _bar(1, [[72, 2], [69, 2]])
        + _bar(2, [[65, 1], [69, 1], [72, 2]])
        + _bar(3, [[74, 2], [71, 2]])
        + _bar(4, [[72, 2], [76, 1], [79, 1]])
        + _bar(5, [[77, 2], [74, 2]])
        + _bar(6, [[72, 1], [74, 1], [76, 2]])
        + _bar(7, [[74, 2], [72, 2]])
    )
    return {
        "bpm": 96, "beats": 32,
        "parts": [
            {"voice": "bass", "gain": 0.34, "notes": bass},
            {"voice": "pad", "gain": 0.09, "notes": pad},
            {"voice": "bell", "gain": 0.42, "notes": melody},
        ],
    }

## Bouncy major-key march for lit mazes.
func _track_explore() -> Dictionary:
    var roots := [36, 41, 43, 36, 36, 41, 43, 36]
    var bass: Array = _per_bar(roots, func(_i: int, b: float, root: int) -> Array:
        return [[b, root, 0.45], [b + 1.0, root, 0.45],
                [b + 2.0, root + 7, 0.45], [b + 3.0, root, 0.45]])
    var stabs: Array = _per_bar(roots, func(_i: int, b: float, root: int) -> Array:
        return _chord(b + 1.5, root + 24, false, 0.35) + _chord(b + 3.5, root + 24, false, 0.35))
    var melody: Array = (
        _bar(0, [[72, 0.5], [76, 0.5], [79, 1], [76, 0.5], [72, 0.5], [74, 1]])
        + _bar(1, [[74, 0.5], [77, 0.5], [81, 1], [79, 0.5], [76, 0.5], [72, 1]])
        + _bar(2, [[79, 0.5], [76, 0.5], [74, 1], [72, 0.5], [69, 0.5], [67, 1]])
        + _bar(3, [[72, 1], [-1, 0.5], [72, 0.5], [76, 2]])
        + _bar(4, [[72, 0.5], [76, 0.5], [79, 1], [81, 0.5], [79, 0.5], [76, 1]])
        + _bar(5, [[77, 0.5], [81, 0.5], [84, 1], [81, 0.5], [77, 0.5], [74, 1]])
        + _bar(6, [[79, 0.5], [76, 0.5], [72, 1], [74, 0.5], [76, 0.5], [77, 1]])
        + _bar(7, [[76, 1], [74, 1], [72, 2]])
    )
    return {
        "bpm": 132, "beats": 32,
        "parts": [
            {"voice": "bass", "gain": 0.36, "notes": bass},
            {"voice": "pluck", "gain": 0.2, "notes": stabs},
            {"voice": "pluck", "gain": 0.5, "notes": melody},
        ],
    }

## Eerie A-minor theme for the medium dark maze. A detuned drone holds under a
## sparse music-box line that keeps leaning on the flat second (Bb) and the
## tritone (Eb) so the harmony never quite settles.
func _track_spooky() -> Dictionary:
    var roots := [33, 33, 32, 32, 33, 33, 28, 33]
    var drone: Array = [[0.0, 33, 7.7], [8.0, 32, 7.7], [16.0, 33, 7.7], [24.0, 28, 7.7]]
    var bass: Array = _per_bar(roots, func(_i: int, b: float, root: int) -> Array:
        return [[b, root, 1.2], [b + 2.5, root + 12, 0.8]])
    # Root, minor third, tritone: a diminished colour instead of a triad.
    var pad: Array = _per_bar(roots, func(_i: int, b: float, root: int) -> Array:
        return [[b, root + 24, 3.6], [b, root + 27, 3.6], [b, root + 30, 3.6]])
    var melody: Array = (
        _bar(0, [[69, 1], [-1, 1], [72, 1], [-1, 1]])
        + _bar(1, [[70, 1.5], [69, 0.5], [-1, 2]])
        + _bar(2, [[76, 1], [75, 1], [-1, 2]])
        + _bar(3, [[72, 1], [70, 1], [69, 2]])
        + _bar(4, [[81, 1], [-1, 1], [80, 1], [-1, 1]])
        + _bar(5, [[77, 1.5], [76, 0.5], [-1, 2]])
        + _bar(6, [[75, 1], [74, 1], [72, 1], [70, 1]])
        + _bar(7, [[69, 2], [-1, 2]])
    )
    return {
        "bpm": 84, "beats": 32,
        "parts": [
            {"voice": "drone", "gain": 0.30, "notes": drone},
            {"voice": "bass", "gain": 0.26, "notes": bass},
            {"voice": "pad", "gain": 0.07, "notes": pad},
            {"voice": "glass", "gain": 0.46, "notes": melody},
        ],
    }

## The hard maze: slower, lower and openly menacing. The bass crawls in
## half-steps, the melody walks a whole-tone scale (no home note to land on) and
## a breath of noise swells once a bar.
func _track_dread() -> Dictionary:
    var roots := [28, 28, 29, 28, 27, 27, 28, 22]
    var drone: Array = [[0.0, 28, 11.7], [12.0, 27, 11.7], [24.0, 28, 7.7]]
    var bass: Array = _per_bar(roots, func(_i: int, b: float, root: int) -> Array:
        return [[b, root, 1.6], [b + 3.0, root + 6, 0.8]])
    # Root plus its tritone only: hollow, unresolved.
    var pad: Array = _per_bar(roots, func(_i: int, b: float, root: int) -> Array:
        return [[b, root + 24, 3.7], [b, root + 30, 3.7]])
    var breath: Array = _per_bar(roots, func(_i: int, b: float, _root: int) -> Array:
        return [[b + 1.0, 300, 2.5]])
    var melody: Array = (
        _bar(0, [[-1, 2], [76, 2]])
        + _bar(1, [[74, 1.5], [72, 2.5]])
        + _bar(2, [[-1, 1], [70, 1], [68, 2]])
        + _bar(3, [[66, 3], [-1, 1]])
        + _bar(4, [[-1, 2], [78, 2]])
        + _bar(5, [[76, 1], [74, 1], [72, 2]])
        + _bar(6, [[70, 2], [68, 1], [66, 1]])
        + _bar(7, [[64, 3], [-1, 1]])
    )
    return {
        "bpm": 58, "beats": 32,
        "parts": [
            {"voice": "drone", "gain": 0.34, "notes": drone},
            {"voice": "bass", "gain": 0.30, "notes": bass},
            {"voice": "pad", "gain": 0.08, "notes": pad},
            {"voice": "hiss", "gain": 0.06, "notes": breath},
            {"voice": "glass", "gain": 0.40, "notes": melody},
        ],
    }

## Short fanfare loop for the win screen.
func _track_victory() -> Dictionary:
    var bass: Array = [[0.0, 36, 1.8], [2.0, 43, 1.8], [4.0, 36, 1.8], [6.0, 36, 1.8],
                       [8.0, 41, 1.8], [10.0, 43, 1.8], [12.0, 36, 3.8]]
    var stabs: Array = _chord(0.0, 60, false, 0.4) + _chord(4.0, 60, false, 0.4) \
        + _chord(8.0, 65, false, 0.4) + _chord(12.0, 60, false, 3.6)
    var melody: Array = (
        _bar(0, [[72, 0.5], [76, 0.5], [79, 1], [84, 2]])
        + _bar(1, [[81, 0.5], [79, 0.5], [76, 1], [79, 2]])
        + _bar(2, [[77, 0.5], [81, 0.5], [84, 1], [81, 2]])
        + _bar(3, [[79, 1], [83, 1], [84, 2]])
    )
    return {
        "bpm": 144, "beats": 16,
        "parts": [
            {"voice": "bass", "gain": 0.34, "notes": bass},
            {"voice": "pluck", "gain": 0.22, "notes": stabs},
            {"voice": "pluck", "gain": 0.5, "notes": melody},
        ],
    }
