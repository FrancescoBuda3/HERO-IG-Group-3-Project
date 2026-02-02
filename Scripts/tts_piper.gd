extends Node3D
@onready var ttsrequest:HTTPRequest = $TTSRequest
@onready var audioplayer:AudioStreamPlayer3D = $"../AudioStreamPlayer3D"

@export var piper_port:int = 5000
@export var speaker_id:int = 1


func _ready() -> void:
	ttsrequest.request_completed.connect(_on_ttsrequest_completed)

func sanitize_text(text: String) -> String:
	var regex_quotes:RegEx = RegEx.new()
	regex_quotes.compile("[\"']")
	text = regex_quotes.sub(text, "", true)

	var regex_space:RegEx = RegEx.new()
	regex_space.compile("\\s+")
	text = regex_space.sub(text, " ", true)

	return text


func request_tts(text: String) -> void:
	text = sanitize_text(text)

	var json_body:Dictionary = {
		"text": text,
		"speaker_id": speaker_id
	}

	var json_string:String = JSON.stringify(json_body)

	var headers = [
        "Content-Type: application/json"
	]

	var url:String = "http://localhost:%d" % piper_port

	var err:Error = ttsrequest.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_string
	)

	if err != OK:
		push_error("TTS request error: %s" % err)

func _on_ttsrequest_completed(
	result: int,
	_response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("TTS HTTP error: %s" % result)
		return

	# body = wav bytes
	var wav:AudioStreamWAV = AudioStreamWAV.new()
	wav.data = body
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	#wav.mix_rate = 22050  # ⚠ dépend de Piper (souvent 22050 ou 16000)
	wav.mix_rate = 16000  # ⚠ dépend de Piper (souvent 22050 ou 16000)
	wav.stereo = false

	audioplayer.stream = wav
	audioplayer.play()


func _on_llm_exchange_llm_response_received(response) -> void:
	request_tts(response)
