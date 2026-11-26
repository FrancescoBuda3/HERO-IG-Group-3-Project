extends Node3D

@export var gazetarget:Node3D
@onready var llmexchange:LLMExchange = $LLMExchange

signal recording_started
signal recording_ended
signal transcription_finished
signal llmresponse_received

enum VoiceState { IDLE, LISTENING, THINKING, SPEAKING }

@onready var microphone:Node = $Microphone
@onready var voice:AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var llm_request:HTTPRequest = $LLMExchange/LLMRequest
@onready var tts_request:HTTPRequest = $TTSPiper/TTSRequest

# Single source of truth for what the agent is doing, used by the UI and animations.
# THINKING lasts from the end of the recording until the voice starts; if a request
# fails it is no longer pending, so the state falls back to IDLE by itself.
func get_voice_state() -> VoiceState:
	if microphone.effect != null and microphone.effect.is_recording_active():
		return VoiceState.LISTENING
	if voice.playing:
		return VoiceState.SPEAKING
	if microphone.is_transcribing:
		return VoiceState.THINKING
	for request in [llm_request, tts_request]:
		if request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
			return VoiceState.THINKING
	return VoiceState.IDLE

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
