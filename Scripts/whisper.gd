class_name Whisper
extends SpeechToText
@export var initial_prompt: String

func _ready() -> void:
	pass#language_model = load("res://addons/godot_whisper/models/gglm-tiny.en.bin")

func _get_configuration_warnings():
	if language_model == null:
		return ["You need a language model."]
	else:
		return []

func get_text(data,format)->String:
	var data_float : PackedFloat32Array
	match format:
		AudioStreamWAV.FORMAT_8_BITS:
			for i in data.size() / 2:
				data_float.append((data.decode_s8(i * 2) * 1.0/128.0))
		AudioStreamWAV.FORMAT_16_BITS:
			for i in data.size() / 2:
				data_float.append((data.decode_s16(i * 2) / 32768.0))
	var tokens = transcribe(data_float, initial_prompt, 0)
	if tokens.is_empty():
		return ""
	else:
		var full_text : String = tokens.pop_front()
		var text = ""
		for token in tokens:
			if token["plog"] > 0:
				continue
			text += token["text"]
		text = full_text
		return _remove_special_characters(text)

func _remove_special_characters(message: String)->String:
	var special_characters := [ \
		{ "start": "[", "end": "]" }, \
		{ "start": "<", "end": ">" }]
	for special_character in special_characters:
		while(message.find(special_character["start"]) != -1):
			var begin_character := message.find(special_character["start"])
			var end_character := message.find(special_character["end"])
			if end_character != -1:
				message = message.substr(0, begin_character) + message.substr(end_character + 1)

	var hallucinatory_character := [". you."]
	for special_character in hallucinatory_character:
		while(message.find(special_character) != -1):
			var begin_character := message.find(special_character)
			var end_character := begin_character + len(special_character)
			message = message.substr(0, begin_character) + message.substr(end_character + 1)
	return message
