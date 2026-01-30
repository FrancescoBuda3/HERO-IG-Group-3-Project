extends Node3D

@export var gazetarget:Node3D
@onready var llmexchange = $LLMExchange

signal recording_started
signal transcription_finished

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if gazetarget != null:
		$Gaze.target = gazetarget


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_microphone_recording_started() -> void:
	emit_signal("recording_started")


func _on_microphone_transcription_finished(str) -> void:
	emit_signal("transcription_finished",str)
	llmexchange.add_to_conversation("user",str)
	llmexchange.nextturn()
