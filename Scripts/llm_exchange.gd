extends Node
class_name LLMExchange

@onready var llmrequest:HTTPRequest = $LLMRequest
@onready var facial_animator:FacialAnimation = $"../FacialAnimation"

signal llm_response_received

enum EndPoint {
	OpenWebUI,
	Ollama
}

@export var url:String = "http://127.0.0.1"
@export var port:String = "11434"
@export var endPoint:EndPoint = EndPoint.Ollama # api/chat
@export var modelName:String = "llama3.2:latest"
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
	var endpoint:String = ""
	if endPoint == EndPoint.OpenWebUI:
		endpoint = "/api/chat/completions"
	elif endPoint == EndPoint.Ollama:
		endpoint = "/api/chat"
	var finalurl:String = ""
	if port != "":
		finalurl = url+":"+port+endpoint
	else:
		finalurl = url+endpoint
	send_LLM_request(finalurl,JSON.stringify(jsondata))
	

func send_LLM_request(finalurl:String,json: String) -> void:
	var headers:Array = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % APIkey
	]
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
	var response_data:Dictionary = JSON.parse_string(response_text)
	var response:String
	if endPoint == EndPoint.Ollama:
		response = response_data["message"]["content"]
	elif endPoint == EndPoint.OpenWebUI:
		response = response_data["choices"][0]["message"]["content"]
	add_to_conversation("assistant",response)
	emit_signal("llm_response_received",response)
	
func add_to_conversation(role:String,content:String):
	var jsonMessage:Dictionary = {"role":role,"content":content}
	conversationList.append(jsonMessage)
	if conversationList.size() > numberOfTurn:
		conversationList.pop_back()
	
