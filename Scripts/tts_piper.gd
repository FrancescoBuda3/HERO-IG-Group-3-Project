extends Node
@onready var ttsrequest:HTTPRequest = $TTSRequest
@onready var audioplayer:AudioStreamPlayer3D = $"../AudioStreamPlayer3D"

@export var piper_port:int = 5001 # 5000 is used by AirPlay Receiver on macOS
@export var speaker_id:int = 3 # semaine voice: 0 prudence (F), 1 spike (M), 2 obadiah (M), 3 poppy (F)

@export var use_local_tts_instead:bool = false
@export var local_tts_language:String = "en"
@export var local_tts_voice_id = 0
var voices:PackedStringArray
var voice_id:String = "None"

func _ready() -> void:
	ttsrequest.request_completed.connect(_on_ttsrequest_completed)
	if use_local_tts_instead:
		voices = DisplayServer.tts_get_voices_for_language(local_tts_language)
		voice_id = voices[local_tts_voice_id]

func sanitize_text(text: String) -> String:
	# LLMs sometimes add markdown asterisks, which must not reach the TTS
	text = text.replace("*", "")

	var regex_quotes:RegEx = RegEx.new()
	regex_quotes.compile("[\"']")
	text = regex_quotes.sub(text, "", true)

	var regex_space:RegEx = RegEx.new()
	regex_space.compile("\\s+")
	text = regex_space.sub(text, " ", true)

	return text


func request_tts(text: String) -> void:
	text = sanitize_text(text)
	if not use_local_tts_instead:
		var json_body:Dictionary = {
			"text": text,
			"speaker_id": speaker_id
		}

		var json_string:String = JSON.stringify(json_body)

		var headers = [
	        "Content-Type: application/json"
		]

		var url:String = "http://localhost:%d/synthesize" % piper_port

		var err:Error = ttsrequest.request(
			url,
			headers,
			HTTPClient.METHOD_POST,
			json_string
		)

		if err != OK:
			push_error("TTS request error: %s" % err)
	else:
		DisplayServer.tts_speak(text, voice_id)
		
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
	wav.mix_rate = 22050  # ⚠ dépend de Piper (souvent 22050 ou 16000)
	#wav.mix_rate = 16000  # ⚠ dépend de Piper (souvent 22050 ou 16000)
	wav.stereo = false

	audioplayer.stream = wav
	audioplayer.play()


func _on_llm_exchange_llm_response_received(response) -> void:
	request_tts(response)
