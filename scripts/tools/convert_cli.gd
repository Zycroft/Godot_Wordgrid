extends SceneTree

func _init() -> void:
	print("Converting JSON files to binary resources...")

	# Convert words.json (curated word list for gameplay)
	convert_words_json()

	# Convert phrases.json
	convert_phrases_json()

	# Create combined valid words lookup dictionary from dictionary.json
	convert_valid_words_lookup()

	# Convert scoring.json
	convert_scoring_json()

	# Convert shop.json
	convert_shop_json()

	print("Conversion complete!")
	quit()


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


func convert_phrases_json() -> void:
	var json_path := "res://data/phrases.json"
	var res_path := "res://data/phrases.res"

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

	var data: Array = json.data

	var phrase_list := PhraseList.new()
	phrase_list.phrases = []
	for item in data:
		phrase_list.phrases.append(item)

	var save_error := ResourceSaver.save(phrase_list, res_path)
	if save_error != OK:
		push_error("Could not save: " + res_path)
		return

	print("Created %s with %d phrases" % [res_path, phrase_list.phrases.size()])


func convert_valid_words_lookup() -> void:
	var json_path := "res://data/dictionary.json"
	var res_path := "res://data/valid_words.res"

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

	var valid_words := ValidWords.new()
	valid_words.word_set = {}

	var total_words := 0

	# Iterate through all word lengths in the dictionary
	for length_key in data.keys():
		var words_array: Array = data[length_key]
		for word in words_array:
			valid_words.word_set[word.to_upper()] = true
			total_words += 1

	var save_error := ResourceSaver.save(valid_words, res_path)
	if save_error != OK:
		push_error("Could not save: " + res_path)
		return

	print("Created %s with %d valid words for lookup" % [res_path, total_words])


func convert_scoring_json() -> void:
	var json_path := "res://data/scoring.json"
	var res_path := "res://data/scoring.res"

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

	var scoring := ScoringConfig.new()

	# Load points configuration
	if data.has("points"):
		var points: Dictionary = data["points"]
		scoring.points_incorrect_letter = int(points.get("incorrect_letter", 0))
		scoring.points_wrong_position_letter = int(points.get("wrong_position_letter", 5))
		scoring.points_correct_letter = int(points.get("correct_letter", 10))
		scoring.points_word_solved_bonus = int(points.get("word_solved_bonus", 20))
		scoring.points_perfect_guess_bonus = int(points.get("perfect_guess_bonus", 50))
		scoring.points_early_solve_multiplier = float(points.get("early_solve_multiplier", 1.5))

	# Load currency configuration
	if data.has("currency"):
		var currency: Dictionary = data["currency"]
		scoring.currency_incorrect_letter = int(currency.get("incorrect_letter", 0))
		scoring.currency_wrong_position_letter = int(currency.get("wrong_position_letter", 1))
		scoring.currency_correct_letter = int(currency.get("correct_letter", 2))
		scoring.currency_word_solved_bonus = int(currency.get("word_solved_bonus", 5))
		scoring.currency_perfect_guess_bonus = int(currency.get("perfect_guess_bonus", 10))
		scoring.currency_early_solve_multiplier = float(currency.get("early_solve_multiplier", 1.25))

	var save_error := ResourceSaver.save(scoring, res_path)
	if save_error != OK:
		push_error("Could not save: " + res_path)
		return

	print("Created %s with scoring configuration" % res_path)


func convert_shop_json() -> void:
	var json_path := "res://data/shop.json"
	var res_path := "res://data/shop.res"

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

	var shop := ShopConfig.new()

	if data.has("rarities"):
		var rarities: Dictionary = data["rarities"]

		if rarities.has("common"):
			var common: Dictionary = rarities["common"]
			shop.common_price = int(common.get("price", 5))
			shop.common_weight = int(common.get("weight", 50))
			var color_arr: Array = common.get("color", [0.7, 0.7, 0.7])
			shop.common_color = Color(color_arr[0], color_arr[1], color_arr[2])

		if rarities.has("uncommon"):
			var uncommon: Dictionary = rarities["uncommon"]
			shop.uncommon_price = int(uncommon.get("price", 10))
			shop.uncommon_weight = int(uncommon.get("weight", 30))
			var color_arr: Array = uncommon.get("color", [0.3, 0.8, 0.3])
			shop.uncommon_color = Color(color_arr[0], color_arr[1], color_arr[2])

		if rarities.has("rare"):
			var rare: Dictionary = rarities["rare"]
			shop.rare_price = int(rare.get("price", 20))
			shop.rare_weight = int(rare.get("weight", 15))
			var color_arr: Array = rare.get("color", [0.3, 0.5, 0.9])
			shop.rare_color = Color(color_arr[0], color_arr[1], color_arr[2])

		if rarities.has("epic"):
			var epic: Dictionary = rarities["epic"]
			shop.epic_price = int(epic.get("price", 40))
			shop.epic_weight = int(epic.get("weight", 5))
			var color_arr: Array = epic.get("color", [0.7, 0.3, 0.9])
			shop.epic_color = Color(color_arr[0], color_arr[1], color_arr[2])

	var save_error := ResourceSaver.save(shop, res_path)
	if save_error != OK:
		push_error("Could not save: " + res_path)
		return

	print("Created %s with shop configuration" % res_path)
