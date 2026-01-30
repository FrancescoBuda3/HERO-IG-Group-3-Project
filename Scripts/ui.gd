extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_agent_recording_started() -> void:
	$HBoxContainer/MarginContainer/TextureRect.texture = load("res://Icons/micon.jpg")


func _on_agent_transcription_finished(str) -> void:
	$HBoxContainer/MarginContainer/TextureRect.texture = load("res://Icons/micoff.jpg")
	print(str)
