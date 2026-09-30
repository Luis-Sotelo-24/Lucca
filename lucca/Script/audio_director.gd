extends Node

const SAMPLE_RATE := 22050
const LEVEL_PATH_PREFIX := "res://Escenas/Niveles/"

var music_player: AudioStreamPlayer
var music_playback: AudioStreamGeneratorPlayback
var music_time := 0.0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -15.0
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.5
	music_player.stream = stream
	add_child(music_player)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var should_play_music := scene != null and scene.scene_file_path.begins_with(LEVEL_PATH_PREFIX)
	if should_play_music and not music_player.playing:
		music_player.play()
		music_playback = music_player.get_stream_playback()
	elif not should_play_music and music_player.playing:
		music_player.stop()
		music_playback = null

	if music_playback:
		_fill_music_buffer()

func play_jump() -> void:
	_play_sweep(260.0, 520.0, 0.12, 0.18)

func play_cat_attack() -> void:
	_play_sweep(420.0, 160.0, 0.16, 0.22, true)

func play_dog_attack() -> void:
	_play_sweep(130.0, 85.0, 0.22, 0.28, true)

func play_fall_damage() -> void:
	_play_sweep(170.0, 55.0, 0.25, 0.25)

func play_super_strength() -> void:
	_play_sweep(90.0, 280.0, 0.3, 0.32, true)

func _fill_music_buffer() -> void:
	var notes: Array[float] = [110.0, 130.81, 146.83, 164.81, 146.83, 130.81]
	var frames := music_playback.get_frames_available()
	for _frame in range(frames):
		var note: float = notes[int(music_time * 0.7) % notes.size()]
		var drone := sin(TAU * 55.0 * music_time) * 0.16
		var melody := sin(TAU * note * music_time) * 0.06
		var shimmer := sin(TAU * note * 2.0 * music_time) * 0.025
		music_playback.push_frame(Vector2.ONE * (drone + melody + shimmer))
		music_time += 1.0 / SAMPLE_RATE

func _play_sweep(start_hz: float, end_hz: float, duration: float, volume: float, square_wave := false) -> void:
	var sample_count := int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var time := float(i) / SAMPLE_RATE
		var progress := time / duration
		var phase := TAU * (start_hz * time + (end_hz - start_hz) * time * time / (2.0 * duration))
		var wave: float = sign(sin(phase)) if square_wave else sin(phase)
		var sample := int(wave * (1.0 - progress) * volume * 32767.0)
		data.encode_s16(i * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data

	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
