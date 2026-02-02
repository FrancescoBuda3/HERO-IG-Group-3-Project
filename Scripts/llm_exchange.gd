extends Node3D

@onready var llmrequest = $LLMRequest
signal llm_response_received

enum EndPoint {
	OpenWebUI,
	Ollama
}

@export var url = "http://127.0.0.1"
@export var port = "11434"
@export var endPoint = EndPoint.Ollama # api/chat
@export var modelName = "llama3.2:latest"
@export var APIkey = ""
@export var preprompt = ""

@export var piperPort = 5000
@export var speakerID = 1

@export var numberOfTurn = 10
@export var conversationList = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	llmrequest.request_completed.connect(_on_llmrequest_completed)
	
func nextturn():
	var jsonpreprompt = {"role":"system","content":preprompt}
	var jsonfullconv = [jsonpreprompt]
	jsonfullconv.append_array(conversationList)
	var jsondata = {"model":modelName,"messages":jsonfullconv,"stream":false}
	var endpoint = ""
	if endPoint == EndPoint.OpenWebUI:
		endpoint = "/api/chat/completions"
	elif endPoint == EndPoint.Ollama:
		endpoint = "/api/chat"
	var finalurl = ""
	if port != "":
		finalurl = url+":"+port+endpoint
	else:
		finalurl = url+endpoint
	send_LLM_request(finalurl,JSON.stringify(jsondata))
	

func send_LLM_request(finalurl:String,json: String) -> void:
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % APIkey
	]
	var error = llmrequest.request(
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
	var response_text = body.get_string_from_utf8()
	print("Received:", response_text)
	var response_data = JSON.parse_string(response_text)
	var response
	if endPoint == EndPoint.Ollama:
		response = response_data["message"]["content"]
	elif endPoint == EndPoint.OpenWebUI:
		response = response_data["choices"][0]["message"]["content"]
	add_to_conversation("assistant",response)
	emit_signal("llm_response_received",response)
	
func add_to_conversation(role:String,content:String):
	var jsonMessage = {"role":role,"content":content}
	conversationList.append(jsonMessage)
	if conversationList.size() > numberOfTurn:
		conversationList.pop_back()
	
