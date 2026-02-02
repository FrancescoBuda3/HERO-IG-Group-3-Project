extends Node3D

@onready var audio_player: AudioStreamPlayer3D = $"../AudioStreamPlayer3D"
@onready var facial_animator:FacialAnimation = $"../FacialAnimation"
@onready var llmexchange:LLMExchange = $"../LLMExchange"
@onready var microphone:Microphone = $"../Microphone"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# charger le MP3
	audio_player.stream = load("res://Sounds/Bienvenue.mp3") # chemin relatif au projet


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_released("Smile"):
		facial_animator.setFacialAUs([6,12],[1,1],2000)
	if Input.is_action_just_released("Record"):
		microphone._on_record_button_pressed()
	if Input.is_action_just_released("Play"):
		microphone._on_play_button_pressed()
