extends AudioStreamPlayer3D

@onready var playbackAudioStream = $"../AudioStreamPlayer3D"
@onready var whisper = $"../Whisper"

signal recording_started
signal transcription_finished

var effect
var recording

func downsample_48k_to_16k(pcm_48k: PackedByteArray) -> PackedByteArray:
	var pcm_16k := PackedByteArray()

	# 2 bytes par sample (int16)
	var sample_size := 2
	var total_samples := pcm_48k.size() / sample_size

	for i in range(0, total_samples, 3):
		var byte_index := i * sample_size

		# copie les 2 bytes du sample
		pcm_16k.append(pcm_48k[byte_index])
		pcm_16k.append(pcm_48k[byte_index + 1])

	return pcm_16k

func _ready():
	# We get the index of the "Record" bus.
	var idx = AudioServer.get_bus_index("Micro")
	# And use it to retrieve its first effect, which has been defined
	# as an "AudioEffectRecord" resource.
	effect = AudioServer.get_bus_effect(idx, 0)

func _on_record_button_pressed():
	if effect.is_recording_active():
		recording = effect.get_recording()
		effect.set_recording_active(false)
		var data = recording.get_data()
		if recording.stereo and recording.format == AudioStreamWAV.FORMAT_16_BITS:
			var newData = PackedByteArray()
			newData.resize(data.size() / 2)
			for i in range(0, data.size(), 4):
				var left = data.decode_u16(i)
				var right = data.decode_u16(i + 2)
				newData.encode_u16(i / 2, (left + right) / 2)
			recording.data = newData
			recording.set_stereo(false)
		var transcription = whisper.get_text(downsample_48k_to_16k(recording.data),recording.format)
		emit_signal("transcription_finished",transcription)
	else:
		effect.set_recording_active(true)
		emit_signal("recording_started")
	
func _on_play_button_pressed():
	print(recording)
	print(recording.format)
	print(recording.mix_rate)
	print(recording.stereo)
	var data = recording.get_data()
	print(data.size())
	
	playbackAudioStream.stream = recording
	playbackAudioStream.play()

func _on_save_button_pressed():
	var save_path = $SaveButton/Filename.text
	recording.save_to_wav(save_path)
	$Status.text = "Saved WAV file to: %s\n(%s)" % [save_path, ProjectSettings.globalize_path(save_path)]
