extends Control

func _on_agent_recording_started() -> void:
	$HBoxContainer/PanelUser/UserContainer/HBoxContainer/UserMessage.text = "Press Space to stop recording now..."

func _on_agent_transcription_finished(transcription) -> void:
	$HBoxContainer/PanelUser/UserContainer/HBoxContainer/UserMessage.text = transcription


func _on_agent_recording_ended() -> void:
	$HBoxContainer/PanelUser/UserContainer/HBoxContainer/UserMessage.text = "Waiting for Whisper's transcription..."



func _on_agent_llmresponse_received(response) -> void:
	$HBoxContainer/PanelAgent/AgentContainer/HBoxContainer/AgentMessage.text = response
