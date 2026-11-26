extends Control

const Agent = preload("res://Scripts/agent.gd")

# The agent whose voice state is shown (set to ../mike in main.tscn)
@export var agent: Node3D

@onready var subtitles: PanelContainer = $Subtitles
@onready var subtitles_text: RichTextLabel = $Subtitles/Text
@onready var pill_style: StyleBoxFlat = $VoiceStatePill.get_theme_stylebox("panel").duplicate()
@onready var pill_icon: TextureRect = $VoiceStatePill/Row/Icon
@onready var pill_label: Label = $VoiceStatePill/Row/Label

# Look of the voice pill for each state, colors taken from the UI concept
var pill_states := {
	Agent.VoiceState.IDLE: {"text": "Press Space to talk", "bg": Color("FBF0E1"), "border": Color("E7B9A9"), "icon": preload("res://Textures/ui/mic.svg")},
	Agent.VoiceState.LISTENING: {"text": "Listening", "bg": Color("DDE8E1"), "border": Color("A9C2B4"), "icon": preload("res://Textures/ui/wave.svg")},
	Agent.VoiceState.THINKING: {"text": "Thinking", "bg": Color("EBD9E6"), "border": Color("C9A5BF"), "icon": preload("res://Textures/ui/dots.svg")},
	Agent.VoiceState.SPEAKING: {"text": "Speaking", "bg": Color("F6C9B6"), "border": Color("E39A80"), "icon": preload("res://Textures/ui/speaker.svg")},
}

var current_state: int = -1
var pending_reply: String = ""

func _ready() -> void:
	$VoiceStatePill.add_theme_stylebox_override("panel", pill_style)
	set_voice_state(Agent.VoiceState.IDLE)

func _process(_delta: float) -> void:
	if agent == null or not agent.has_method("get_voice_state"):
		return
	var state: int = agent.get_voice_state()
	if state != current_state:
		set_voice_state(state)

func set_voice_state(state: int) -> void:
	current_state = state
	var look: Dictionary = pill_states[state]
	pill_label.text = look["text"]
	pill_icon.texture = look["icon"]
	pill_style.bg_color = look["bg"]
	pill_style.border_color = look["border"]
	# The reply appears together with the voice, not when the text arrives
	if state == Agent.VoiceState.SPEAKING and pending_reply != "":
		show_subtitle(pending_reply)
		pending_reply = ""

func show_subtitle(bbcode: String) -> void:
	subtitles_text.text = bbcode
	subtitles.visible = bbcode != ""

func clean(text: String) -> String:
	return text.replace("*", "").replace("[", "(").replace("]", ")").strip_edges()

func _on_agent_recording_started() -> void:
	pending_reply = ""
	show_subtitle("")

func _on_agent_recording_ended() -> void:
	pass

func _on_agent_transcription_finished(transcription) -> void:
	var said := clean(str(transcription))
	if said == "":
		show_subtitle("[color=#8a8494]I didn't catch that. Press Space and try again.[/color]")
	else:
		show_subtitle("[color=#8a8494][i]You: %s[/i][/color]" % said)

func _on_agent_llmresponse_received(response) -> void:
	pending_reply = clean(str(response))
