extends Node3D

const Agent = preload("res://Scripts/agent.gd")

@onready var anim: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var agent: Node3D = get_node_or_null("../mike")

func _ready() -> void:
	for anim_name in ["Idle", "Talk", "Think"]:
		anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	anim.play("Idle")

func _process(_delta: float) -> void:
	var wanted := "Idle"
	if agent != null:
		match agent.get_voice_state():
			Agent.VoiceState.SPEAKING:
				wanted = "Talk"
			Agent.VoiceState.THINKING:
				wanted = "Think"
	if anim.current_animation != wanted:
		anim.play(wanted, 0.3) # 0.3 s of blending between animations
