extends Node
# One-time steps.
# Pick a voice. Here, we arbitrarily pick the first English voice.
var voices = DisplayServer.tts_get_voices_for_language("en")
var voice_id = voices[0]

func speak(text):
	# Say "Hello, world!".
	DisplayServer.tts_speak(text, voice_id)


func _on_llm_exchange_llm_response_received(response) -> void:
	speak(response) # Replace with function body.
