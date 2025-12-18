@tool
extends EditorScript

func _run() -> void:
	print("Converting JSON files to binary resources...")

	# Convert dictionary files (dictionary_2.json through dictionary_10.json)
	for length in range(2, 11):
		var json_path := "res://data/dictionary_%d.json" % length
		var res_path := "res://data/dictionary_%d.res" % length
		convert_word_list(json_path, res_path)

	# Convert words.json (has different structure - dictionary with length keys)
	convert_words_json()

	print("Conversion complete!")


func convert_word_list(json_path: String, res_path: String) -> void:
	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Could not open: " + json_path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in %s: %s" % [json_path, json.get_error_message()])
		return

	var words_array: Array = json.data

	var word_list := WordList.new()
	word_list.words = PackedStringArray(words_array)

	var save_error := ResourceSaver.save(word_list, res_path)
	if save_error != OK:
		push_error("Could not save: " + res_path)
		return

	print("Created %s with %d words" % [res_path, word_list.words.size()])


func convert_words_json() -> void:
	var json_path := "res://data/words.json"
	var res_path := "res://data/words.res"

	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Could not open: " + json_path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in %s: %s" % [json_path, json.get_error_message()])
		return

	var data: Dictionary = json.data

	var word_dict := WordDictionary.new()
	word_dict.words_by_length = {}

	for key in data.keys():
		var length := int(key)
		var words_array: Array = data[key]
		word_dict.words_by_length[length] = PackedStringArray(words_array)

	var save_error := ResourceSaver.save(word_dict, res_path)
	if save_error != OK:
		push_error("Could not save: " + res_path)
		return

	print("Created %s with %d length categories" % [res_path, word_dict.words_by_length.size()])
