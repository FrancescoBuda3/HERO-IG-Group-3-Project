extends Node
class_name LLMExchange

@onready var llmrequest:HTTPRequest = $LLMRequest
@onready var facial_animator:FacialAnimation = $"../FacialAnimation"

signal llm_response_received

enum EndPoint {
	OpenWebUI,
	Ollama,
	OpenRouter
}

const OPENROUTER_URL:String = "https://openrouter.ai/api/v1/chat/completions"
const OPENROUTER_KEY_FILE:String = "user://openrouter_key.txt"

# Key lookup order: OPENROUTER_API_KEY env var, then the key file in user://
# (never inside the project, so it can't end up in git), then the APIkey export.
func get_api_key() -> String:
	if endPoint == EndPoint.OpenRouter:
		var env_key:String = OS.get_environment("OPENROUTER_API_KEY").strip_edges()
		if env_key != "":
			return env_key
		if FileAccess.file_exists(OPENROUTER_KEY_FILE):
			var file_key:String = FileAccess.get_file_as_string(OPENROUTER_KEY_FILE).strip_edges()
			if file_key != "":
				return file_key
	return APIkey

@export var url:String = "http://127.0.0.1"
@export var port:String = "11434"
@export var endPoint:EndPoint = EndPoint.Ollama # api/chat
@export var modelName:String = "smollm:135m"
# OpenRouter only: models tried in order if modelName is rate-limited or fails
@export var fallbackModels:PackedStringArray = []
@export var APIkey:String = ""
@export_multiline var preprompt:String = ""

@export var numberOfTurn = 10
@export var conversationList = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	llmrequest.request_completed.connect(_on_llmrequest_completed)
	
func nextturn()->void:
	var jsonpreprompt:Dictionary = {"role":"system","content":preprompt}
	var jsonfullconv:Array = [jsonpreprompt]
	jsonfullconv.append_array(conversationList)
	var jsondata:Dictionary = {"model":modelName,"messages":jsonfullconv,"stream":false}
	if endPoint == EndPoint.OpenRouter and not fallbackModels.is_empty():
		var models:Array = [modelName]
		models.append_array(fallbackModels)
		if models.size() > 3:
			push_warning("OpenRouter accepts at most 3 models, ignoring: %s" % str(models.slice(3)))
			models = models.slice(0, 3)
		jsondata = {"models":models,"messages":jsonfullconv,"stream":false}
	var endpoint:String = ""
	if endPoint == EndPoint.OpenWebUI:
		endpoint = "/api/chat/completions"
	elif endPoint == EndPoint.Ollama:
		endpoint = "/api/chat"
	var finalurl:String = ""
	if endPoint == EndPoint.OpenRouter:
		finalurl = OPENROUTER_URL
	elif port != "":
		finalurl = url+":"+port+endpoint
	else:
		finalurl = url+endpoint
	send_LLM_request(finalurl,JSON.stringify(jsondata))
	

func send_LLM_request(finalurl:String,json: String) -> void:
	var headers:Array = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % get_api_key()
	]
	if endPoint == EndPoint.OpenRouter and get_api_key() == "":
		push_error("OpenRouter: no API key found (env OPENROUTER_API_KEY or %s)" % OPENROUTER_KEY_FILE)
		return
	var error:Error = llmrequest.request(
		finalurl,
		headers,
		HTTPClient.METHOD_POST,
		json
	)
	if error != OK:
		push_error("Error while sending request: %s" % error)
	
func _on_llmrequest_completed(
	result: int,
	_response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Error while sending:", result)
		return
	var response_text:String = body.get_string_from_utf8()
	print("Received:", response_text)
	var response_data = JSON.parse_string(response_text)
	if typeof(response_data) != TYPE_DICTIONARY:
		push_error("Invalid LLM response: %s" % response_text)
		return
	if response_data.has("error"):
		push_error("LLM error: %s" % str(response_data["error"]))
		return
	var response:String
	if endPoint == EndPoint.Ollama:
		response = response_data["message"]["content"]
	elif endPoint == EndPoint.OpenWebUI or endPoint == EndPoint.OpenRouter:
		if not response_data.has("choices") or response_data["choices"].is_empty():
			push_error("LLM response without choices: %s" % response_text)
			return
		# Some free/reasoning models can return a null content
		response = str(response_data["choices"][0]["message"].get("content", ""))
		if response.strip_edges() == "":
			push_warning("LLM returned an empty answer")
			return
	add_to_conversation("assistant",response)
	emit_signal("llm_response_received",response)
	
func add_to_conversation(role:String,content:String):
	var jsonMessage:Dictionary = {"role":role,"content":content}
	conversationList.append(jsonMessage)
	if conversationList.size() > numberOfTurn:
		conversationList.pop_back()
	
