extends Node3D

@onready var llmrequest = $LLMRequest
@onready var ttsrequest = $TTSRequest
@onready var audioplayer = $"../AudioStreamPlayer3D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	llmrequest.request_completed.connect(_on_llmrequest_completed)
	ttsrequest.request_completed.connect(_on_ttsrequest_completed)

func sanitize_text(text: String) -> String:
	var regex_quotes := RegEx.new()
	regex_quotes.compile("[\"']")
	text = regex_quotes.sub(text, "", true)

	var regex_space := RegEx.new()
	regex_space.compile("\\s+")
	text = regex_space.sub(text, " ", true)

	return text

func send_LLM_request(url: String, json: String, api_key: String) -> void:
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % api_key
	]
	var error = llmrequest.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json
	)
	if error != OK:
		push_error("Error while sending request: %s" % error)
	
func _on_llmrequest_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Error while sending:", result)
		return
	var response_text = body.get_string_from_utf8()
	print("Received:", response_text)
	# Parsing JSON (ton parser custom ou Godot natif)
	var response_data = JSON.parse_string(response_text)
	
	
func request_tts(text: String, piper_port: int, speaker_id: int):
	text = sanitize_text(text)

	var json_body := {
		"text": text,
		"speaker_id": speaker_id
	}

	var json_string := JSON.stringify(json_body)

	var headers = [
        "Content-Type: application/json"
	]

	var url = "http://localhost:%d" % piper_port

	var err = ttsrequest.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_string
	)

	if err != OK:
		push_error("TTS request error: %s" % err)

func _on_ttsrequest_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("TTS HTTP error: %s" % result)
		return

	# body = wav bytes
	var wav := AudioStreamWAV.new()
	wav.data = body
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	#wav.mix_rate = 22050  # ⚠ dépend de Piper (souvent 22050 ou 16000)
	wav.mix_rate = 16000  # ⚠ dépend de Piper (souvent 22050 ou 16000)
	wav.stereo = false

	audioplayer.stream = wav
	audioplayer.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
