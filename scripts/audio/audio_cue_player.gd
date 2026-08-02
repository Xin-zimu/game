class_name AudioCuePlayer
extends Node

const SAMPLE_RATE := 8000
const CUE_DURATION := 0.085

var _player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _cooldown := 0.0
var played_cues := 0
var ambient_weather: StringName = &"CLEAR"


func _ready() -> void:
	name = "AudioCuePlayer"
	_player = AudioStreamPlayer.new()
	_player.name = "CueOutput"
	add_child(_player)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "WeatherAmbienceOutput"
	_ambient_player.volume_db = -20.0
	add_child(_ambient_player)
	EventBus.attack_started.connect(func(_payload: Dictionary) -> void: play_cue(&"attack"))
	EventBus.combat_feedback.connect(_on_combat_feedback)
	EventBus.interaction_feedback.connect(func(_message: String, successful: bool) -> void: play_cue(&"success" if successful else &"blocked"))
	EventBus.milestone_state_changed.connect(_on_milestone_changed)
	EventBus.weather_state_changed.connect(_on_weather_changed)


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


func _exit_tree() -> void:
	if _player != null:
		_player.stop()
		_player.stream = null
	if _ambient_player != null:
		_ambient_player.stop()
		_ambient_player.stream = null


func play_cue(cue: StringName) -> bool:
	if _player == null or _cooldown > 0.0:
		return false
	var frequency := 440.0
	match cue:
		&"attack": frequency = 230.0
		&"blocked": frequency = 145.0
		&"boss": frequency = 110.0
		&"milestone": frequency = 660.0
		&"success": frequency = 520.0
	_player.stream = synthesize_tone(frequency)
	_player.play()
	played_cues += 1
	_cooldown = 0.045
	return true


static func synthesize_tone(frequency: float, duration := CUE_DURATION) -> AudioStreamWAV:
	var sample_count := maxi(1, roundi(SAMPLE_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var envelope := 1.0 - float(index) / float(sample_count)
		var sample := roundi(sin(TAU * frequency * float(index) / SAMPLE_RATE) * envelope * 10500.0)
		bytes.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


static func synthesize_ambience(frequency: float, weather_id: StringName) -> AudioStreamWAV:
	var duration := 1.0
	var sample_count := SAMPLE_RATE
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var stable_phase := float(WorldSeed.from_text("weather-audio|%s" % weather_id) & 0xffff) / 65535.0 * TAU
	for index in sample_count:
		var sample_time := float(index) / SAMPLE_RATE
		var noise := sin(sample_time * 1733.0 + stable_phase) * 0.62 \
			+ sin(sample_time * 2711.0 + stable_phase * 1.7) * 0.38
		var wave := sin(TAU * frequency * float(index) / SAMPLE_RATE) if frequency > 0.0 else 0.0
		var mix := noise * (0.48 if weather_id == &"RAIN" else 0.26) + wave * 0.18
		bytes.encode_s16(index * 2, roundi(clampf(mix, -1.0, 1.0) * 7200.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = bytes
	return stream


func _on_combat_feedback(message: String, successful: bool) -> void:
	if "守卫" in message:
		play_cue(&"boss")
	elif successful:
		play_cue(&"success")
	else:
		play_cue(&"blocked")


func _on_milestone_changed(snapshot: Dictionary) -> void:
	if bool(snapshot.get("reward_claimed", false)) or bool(snapshot.get("boss_defeated", false)):
		play_cue(&"milestone")


func _on_weather_changed(snapshot: Dictionary) -> void:
	var weather_id := StringName(snapshot.get("weather_id", &"CLEAR"))
	if weather_id == ambient_weather:
		return
	ambient_weather = weather_id
	if weather_id == &"CLEAR":
		_ambient_player.stop()
		return
	_ambient_player.stream = synthesize_ambience(float(snapshot.get("ambient_frequency", 90.0)), weather_id)
	_ambient_player.play()
