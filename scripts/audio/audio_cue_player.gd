class_name AudioCuePlayer
extends Node

const SAMPLE_RATE := 8000
const CUE_DURATION := 0.085

var _player: AudioStreamPlayer
var _cooldown := 0.0
var played_cues := 0


func _ready() -> void:
	name = "AudioCuePlayer"
	_player = AudioStreamPlayer.new()
	_player.name = "CueOutput"
	add_child(_player)
	EventBus.attack_started.connect(func(_payload: Dictionary) -> void: play_cue(&"attack"))
	EventBus.combat_feedback.connect(_on_combat_feedback)
	EventBus.interaction_feedback.connect(func(_message: String, successful: bool) -> void: play_cue(&"success" if successful else &"blocked"))
	EventBus.milestone_state_changed.connect(_on_milestone_changed)


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


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
