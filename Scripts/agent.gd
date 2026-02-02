extends Node3D

@export var gazetarget:Node3D
@onready var llmexchange = $LLMExchange

signal recording_started
signal transcription_finished

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if gazetarget != null:
		$Gaze.target = gazetarget

func _on_microphone_recording_started() -> void:
	emit_signal("recording_started")


func _on_microphone_transcription_finished(transcription) -> void:
	emit_signal("transcription_finished",transcription)
	llmexchange.add_to_conversation("user",transcription)
	llmexchange.nextturn()
