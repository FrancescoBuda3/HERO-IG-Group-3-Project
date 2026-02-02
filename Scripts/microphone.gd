extends AudioStreamPlayer3D
class_name Microphone

@onready var playbackAudioStream:AudioStreamPlayer3D = $"../AudioStreamPlayer3D"
@onready var whisper:Whisper = $"../Whisper"

signal recording_started
signal recording_ended
signal transcription_finished

var effect:AudioEffect
var recording:AudioStream

var is_transcribing:bool = false

var thread : Thread

func downsample_48k_to_16k(pcm_48k: PackedByteArray) -> PackedByteArray:
	var pcm_16k:PackedByteArray = PackedByteArray()

	# 2 bytes par sample (int16)
	var sample_size:int = 2
	var total_samples:int = pcm_48k.size() / sample_size

	for i in range(0, total_samples, 3):
		var byte_index:int = i * sample_size

		# copie les 2 bytes du sample
		pcm_16k.append(pcm_48k[byte_index])
		pcm_16k.append(pcm_48k[byte_index + 1])

	return pcm_16k

func _ready()->void:
	var idx:int = AudioServer.get_bus_index("Micro")
	effect = AudioServer.get_bus_effect(idx, 0)

func _on_record_button_pressed()->void:
	if effect.is_recording_active():
		recording = effect.get_recording()
		effect.set_recording_active(false)
		var data:PackedByteArray = recording.get_data()
		if recording.stereo and recording.format == AudioStreamWAV.FORMAT_16_BITS:
			var newData:PackedByteArray = PackedByteArray()
			newData.resize(data.size() / 2)
			for i in range(0, data.size(), 4):
				var left:int = data.decode_u16(i)
				var right:int = data.decode_u16(i + 2)
				newData.encode_u16(i / 2, (left + right) / 2)
			recording.data = newData
			recording.set_stereo(false)
		emit_signal("recording_ended")
		is_transcribing = true
		if thread != null and not thread.is_alive():
			thread.wait_to_finish()
		thread = Thread.new()
		thread.start(transcribe_thread.bind(recording.format).bind(recording.data).bind(self))
		
	elif not is_transcribing:
		effect.set_recording_active(true)
		emit_signal("recording_started")

func transcribe_thread(wspr,data,format)->void:
	var transcription:String = whisper.get_text(downsample_48k_to_16k(data),format)
	wspr.call_deferred("transcr_finished",transcription)

func transcr_finished(transcription)->void:
	emit_signal("transcription_finished",transcription)
	is_transcribing = false

func _on_play_button_pressed()->void:
	print(recording)
	print(recording.format)
	print(recording.mix_rate)
	print(recording.stereo)
	var data:PackedByteArray = recording.get_data()
	print(data.size())
	
	playbackAudioStream.stream = recording
	playbackAudioStream.play()

func _on_save_button_pressed()->void:
	var save_path:String = $SaveButton/Filename.text
	recording.save_to_wav(save_path)
	$Status.text = "Saved WAV file to: %s\n(%s)" % [save_path, ProjectSettings.globalize_path(save_path)]
