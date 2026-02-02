extends Node3D

@export var gazetarget:Node3D
@onready var llmexchange = $LLMExchange

signal recording_started
signal recording_ended
signal transcription_finished
signal llmresponse_received

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


func _on_microphone_recording_ended() -> void:
	emit_signal("recording_ended")

func _on_llm_exchange_llm_response_received(response) -> void:
	emit_signal("llmresponse_received",response)
