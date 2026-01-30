extends AudioStreamPlayer3D

@onready var playbackAudioStream = $"../AudioStreamPlayer3D"

var effect
var recording


func _ready():
	# We get the index of the "Record" bus.
	var idx = AudioServer.get_bus_index("Micro")
	# And use it to retrieve its first effect, which has been defined
	# as an "AudioEffectRecord" resource.
	effect = AudioServer.get_bus_effect(idx, 0)

func _on_record_button_pressed():
	if effect.is_recording_active():
		recording = effect.get_recording()
		#$PlayButton.disabled = false
		#$SaveButton.disabled = false
		effect.set_recording_active(false)
		#$RecordButton.text = "Record"
		#$Status.text = ""
	else:
		#$PlayButton.disabled = true
		#$SaveButton.disabled = true
		effect.set_recording_active(true)
		#$RecordButton.text = "Stop"
		#$Status.text = "Recording..."
	
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
