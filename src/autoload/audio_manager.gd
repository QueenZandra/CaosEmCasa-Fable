extends Node
## Autoload: tiny procedural sound effects (square/noise bursts generated
## at startup) so the game has feedback sounds without any audio assets.

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE := 8


func _ready() -> void:
	_streams = {
		"bark": _tone([[160.0, 0.08], [120.0, 0.1]], 0.5, true),
		"meow": _tone([[520.0, 0.1], [700.0, 0.12], [430.0, 0.1]], 0.3, false),
		"pop": _tone([[300.0, 0.05]], 0.4, false),
		"ding": _tone([[880.0, 0.12], [1320.0, 0.1]], 0.25, false),
		"angry": _tone([[110.0, 0.2], [90.0, 0.2]], 0.45, true),
		"sweep": _tone([[240.0, 0.06], [260.0, 0.06], [280.0, 0.06]], 0.2, true),
		"cute": _tone([[660.0, 0.08], [880.0, 0.08], [990.0, 0.12]], 0.3, false),
		"thud": _tone([[70.0, 0.1]], 0.6, true),
		"chirp": _tone([[1400.0, 0.05], [1800.0, 0.05]], 0.2, false),
	}
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play_sfx(name: String, volume_db := 0.0) -> void:
	if not _streams.has(name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[name]
			p.volume_db = volume_db
			p.play()
			return


## Build a small AudioStreamWAV from [freq, duration] segments.
func _tone(segments: Array, volume: float, noisy: bool) -> AudioStreamWAV:
	var rate := 22050
	var data := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var phase := 0.0
	for seg in segments:
		var freq: float = seg[0]
		var dur: float = seg[1]
		var samples := int(rate * dur)
		for i in samples:
			var env := 1.0 - float(i) / float(samples)
			var s: float
			if noisy:
				var square := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
				s = lerpf(square, rng.randf_range(-1.0, 1.0), 0.35)
			else:
				s = sin(phase * TAU)
			phase += freq / rate
			var value := int(clampf(s * env * volume, -1.0, 1.0) * 32767.0)
			data.append(value & 0xFF)
			data.append((value >> 8) & 0xFF)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav
