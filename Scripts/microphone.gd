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

var recording_rate:int = 48000

# Resamples mono 16-bit PCM from src_rate (the real recording rate, usually 44100
# or 48000 depending on the system) to the 16000 Hz that Whisper expects.
func downsample_to_16k(pcm: PackedByteArray, src_rate: int) -> PackedByteArray:
	var pcm_16k:PackedByteArray = PackedByteArray()
	var total_samples:int = pcm.size() / 2
	if total_samples == 0 or src_rate <= 0:
		return pcm_16k
	var ratio:float = float(src_rate) / 16000.0
	var out_count:int = int(total_samples / ratio)
	pcm_16k.resize(out_count * 2)
	for i in out_count:
		var pos:float = i * ratio
		var i0:int = int(pos)
		var i1:int = mini(i0 + 1, total_samples - 1)
		var frac:float = pos - i0
		var s0:int = pcm.decode_s16(i0 * 2)
		var s1:int = pcm.decode_s16(i1 * 2)
		pcm_16k.encode_s16(i * 2, int(s0 + (s1 - s0) * frac))
	return pcm_16k

func peak_level(pcm: PackedByteArray) -> float:
	var peak:int = 0
	for i in range(0, pcm.size() / 2):
		peak = maxi(peak, absi(pcm.decode_s16(i * 2)))
	return peak / 32768.0

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
				var left:int = data.decode_s16(i)
				var right:int = data.decode_s16(i + 2)
				newData.encode_s16(i / 2, (left + right) / 2)
			recording.data = newData
			recording.set_stereo(false)
		recording_rate = recording.mix_rate
		print("[Mic] rate=%d Hz, bytes=%d, duration=%.1f s, peak level=%.3f" % [
			recording_rate, recording.data.size(),
			recording.data.size() / 2.0 / maxf(recording_rate, 1), peak_level(recording.data)])
		if peak_level(recording.data) < 0.01:
			push_warning("[Mic] the recording is almost silent: check the macOS microphone permission for Godot and the input device")
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
	var transcription:String = whisper.get_text(downsample_to_16k(data, recording_rate),format)
	wspr.call_deferred("transcr_finished",transcription)

func transcr_finished(transcription)->void:
	print("[Whisper] ", transcription)
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
