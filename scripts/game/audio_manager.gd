extends Node

const MIX_RATE := 22050
const DEFAULT_COOLDOWN := 0.03

@export_range(0.0, 1.0, 0.01) var master_volume: float = 1.0
@export_range(0.0, 1.0, 0.01) var sfx_volume: float = 0.75

var _streams: Dictionary = {}
var _last_played: Dictionary = {}
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_streams()
	_load_settings_values()


func _process(delta: float) -> void:
	_time += delta


func play_shoot() -> void:
	_play("shoot", -15.0, _random_pitch(0.96, 1.04), 0.08)


func play_chain_cast(jump_count: int = 1) -> void:
	var pitch := 1.0 + clampf(float(jump_count - 1) * 0.035, 0.0, 0.16)
	_play("chain_cast", -12.0, pitch, 0.08)


func play_area_cast() -> void:
	_play("area_cast", -13.0, _random_pitch(0.96, 1.04), 0.12)


func play_enemy_hit() -> void:
	_play("enemy_hit", -17.0, _random_pitch(0.9, 1.12), 0.035)


func play_enemy_death() -> void:
	_play("enemy_death", -12.0, _random_pitch(0.94, 1.06), 0.04)


func play_player_hit() -> void:
	_play("player_hit", -7.0, _random_pitch(0.95, 1.02), 0.12)


func play_upgrade_pick() -> void:
	_play("upgrade_pick", -8.0, 1.0, 0.08)


func play_button_click() -> void:
	_play("button_click", -18.0, _random_pitch(0.96, 1.08), 0.025)


func play_wave_start() -> void:
	_play("wave_start", -11.0, 1.0, 0.2)


func play_wave_complete() -> void:
	_play("wave_complete", -10.0, 1.0, 0.18)


func play_boss_spawn() -> void:
	_play("boss_spawn", -6.0, 1.0, 0.5)


func play_explosion() -> void:
	_play("explosion", -8.0, _random_pitch(0.92, 1.04), 0.08)


func play_laser() -> void:
	_play("laser", -10.0, _random_pitch(0.97, 1.04), 0.08)


func play_unlock() -> void:
	_play("unlock", -7.0, 1.0, 0.12)


func play_error() -> void:
	_play("error", -13.0, 1.0, 0.12)


func play_victory() -> void:
	_play("victory", -7.0, 1.0, 0.8)


func play_defeat() -> void:
	_play("defeat", -7.0, 1.0, 0.8)


func play_menu_music() -> void:
	pass


func play_run_music() -> void:
	pass


func stop_music() -> void:
	pass


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)


func get_master_volume() -> float:
	return master_volume


func get_sfx_volume() -> float:
	return sfx_volume


func test_all_sounds() -> void:
	var sound_ids := [
		"button_click",
		"shoot",
		"enemy_hit",
		"enemy_death",
		"player_hit",
		"upgrade_pick",
		"wave_start",
		"boss_spawn",
		"victory",
		"defeat",
	]

	for index in range(sound_ids.size()):
		get_tree().create_timer(float(index) * 0.22).timeout.connect(_play.bind(sound_ids[index]))


func _build_streams() -> void:
	_streams = {
		"shoot": _make_tone(880.0, 0.055, 0.42, "square", 220.0),
		"chain_cast": _make_sequence([620.0, 930.0, 1340.0], 0.04, 0.32, "sine"),
		"area_cast": _make_sequence([280.0, 420.0, 560.0], 0.055, 0.3, "sine"),
		"enemy_hit": _make_noise(0.055, 0.34),
		"enemy_death": _make_tone(440.0, 0.18, 0.42, "saw", -260.0),
		"player_hit": _make_tone(145.0, 0.16, 0.52, "square", -55.0),
		"upgrade_pick": _make_sequence([660.0, 880.0, 1320.0], 0.08, 0.42, "sine"),
		"button_click": _make_tone(920.0, 0.035, 0.25, "square", -180.0),
		"wave_start": _make_sequence([330.0, 495.0], 0.09, 0.38, "sine"),
		"wave_complete": _make_sequence([520.0, 700.0, 920.0], 0.055, 0.35, "sine"),
		"boss_spawn": _make_sequence([170.0, 120.0, 90.0], 0.12, 0.58, "saw"),
		"explosion": _make_noise(0.18, 0.55),
		"laser": _make_tone(1180.0, 0.11, 0.36, "saw", -280.0),
		"unlock": _make_sequence([520.0, 780.0, 1040.0, 1560.0], 0.06, 0.42, "sine"),
		"error": _make_sequence([220.0, 180.0], 0.08, 0.38, "square"),
		"victory": _make_sequence([440.0, 660.0, 880.0, 1320.0], 0.12, 0.45, "sine"),
		"defeat": _make_sequence([420.0, 300.0, 190.0], 0.15, 0.5, "saw"),
	}


func _load_settings_values() -> void:
	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager == null:
		return

	if settings_manager.has_method("get_master_volume"):
		master_volume = clampf(float(settings_manager.call("get_master_volume")), 0.0, 1.0)
	if settings_manager.has_method("get_sfx_volume"):
		sfx_volume = clampf(float(settings_manager.call("get_sfx_volume")), 0.0, 1.0)


func _play(sound_id: String, volume_db: float = 0.0, pitch: float = 1.0, cooldown: float = DEFAULT_COOLDOWN) -> void:
	if not _streams.has(sound_id):
		return
	if _time - float(_last_played.get(sound_id, -999.0)) < cooldown:
		return

	_last_played[sound_id] = _time
	var player := AudioStreamPlayer.new()
	player.stream = _streams[sound_id]
	player.volume_db = _get_volume_db() + volume_db
	player.pitch_scale = pitch
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _get_volume_db() -> float:
	var volume := clampf(master_volume * sfx_volume, 0.0, 1.0)
	if volume <= 0.001:
		return -80.0

	return linear_to_db(volume)


func _random_pitch(min_pitch: float, max_pitch: float) -> float:
	return _rng.randf_range(min_pitch, max_pitch)


func _make_sequence(frequencies: Array, segment_duration: float, amplitude: float, wave: String) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	for frequency in frequencies:
		_append_tone_samples(samples, float(frequency), segment_duration, amplitude, wave, 0.0)

	return _samples_to_wav(samples)


func _make_tone(frequency: float, duration: float, amplitude: float, wave: String, slide: float = 0.0) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	_append_tone_samples(samples, frequency, duration, amplitude, wave, slide)
	return _samples_to_wav(samples)


func _make_noise(duration: float, amplitude: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var sample_count := int(duration * float(MIX_RATE))
	for index in range(sample_count):
		var progress := float(index) / float(maxi(sample_count - 1, 1))
		var envelope := _envelope(progress)
		samples.append(_rng.randf_range(-1.0, 1.0) * amplitude * envelope)

	return _samples_to_wav(samples)


func _append_tone_samples(samples: PackedFloat32Array, frequency: float, duration: float, amplitude: float, wave: String, slide: float) -> void:
	var sample_count := int(duration * float(MIX_RATE))
	for index in range(sample_count):
		var progress := float(index) / float(maxi(sample_count - 1, 1))
		var current_frequency := maxf(20.0, frequency + slide * progress)
		var phase := TAU * current_frequency * float(index) / float(MIX_RATE)
		var raw := _wave_value(phase, wave)
		samples.append(raw * amplitude * _envelope(progress))


func _wave_value(phase: float, wave: String) -> float:
	match wave:
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"saw":
			return 2.0 * (phase / TAU - floor(phase / TAU + 0.5))
		_:
			return sin(phase)


func _envelope(progress: float) -> float:
	var attack := smoothstep(0.0, 0.12, progress)
	var release := 1.0 - smoothstep(0.55, 1.0, progress)
	return clampf(attack * release, 0.0, 1.0)


func _samples_to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	for sample in samples:
		var sample_value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		if sample_value < 0:
			sample_value += 65536
		data.append(sample_value & 0xff)
		data.append((sample_value >> 8) & 0xff)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
