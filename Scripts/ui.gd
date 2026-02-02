extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_agent_recording_started() -> void:
	$HBoxContainer/MarginContainer/TextureRect.texture = load("res://Icons/micon.jpg")


func _on_agent_transcription_finished(transcription) -> void:
	$HBoxContainer/MarginContainer/TextureRect.texture = load("res://Icons/micoff.jpg")
	print(transcription)
