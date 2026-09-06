extends Node
## Procedural SFX. Every sound is synthesised into an AudioStreamWAV at boot,
## so there are no audio assets. play_sfx(name) for one-shots; get_stream(name)
## for positional players (monster growl); set_heartbeat(intensity) for the
## non-positional pulse that speeds up as the monster closes in.

const RATE := 22050
const POOL_SIZE := 8

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _heartbeat: AudioStreamPlayer
var _heartbeat_intensity := 0.0
var _heartbeat_timer := 0.0

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

func has_sfx(sfx_name: StringName) -> bool:
    return _streams.has(sfx_name)

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

func play_music(_name: StringName) -> void:
    pass

## 0 = silent, 1 = monster on top of you. Interval and volume follow it.
func set_heartbeat(intensity: float) -> void:
    _heartbeat_intensity = clampf(intensity, 0.0, 1.0)
    if _heartbeat_intensity <= 0.0:
        _heartbeat_timer = 0.0

func heartbeat_interval(intensity: float) -> float:
    return lerpf(1.3, 0.42, clampf(intensity, 0.0, 1.0))

func _process(delta: float) -> void:
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
    var data := PackedByteArray()
    data.resize(frames * 2)
    for i in frames:
        var t := float(i) / RATE
        var s: float = clampf(fn.call(t, seconds), -1.0, 1.0)
        data.encode_s16(i * 2, int(s * 32767.0))
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
