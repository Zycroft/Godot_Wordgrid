extends Node

signal round_changed(round_number: int)
signal stage_changed(stage_number: int)
signal points_changed(points: int)
signal currency_changed(currency: int)
signal round_points_changed(round_points: int)
signal new_word_ready(word: String)
signal word_completed(word: String, attempts: int, points_earned: int, currency_earned: int)
signal word_failed(word: String, points_earned: int, currency_earned: int)
signal game_over

const STAGES_PER_ROUND: int = 4
const MIN_WORD_LENGTH: int = 2
const MAX_WORD_LENGTH: int = 10

# Word length progression by round
# Round 1: 2-3 letter words
# Round 2: 3-4 letter words
# etc.
const ROUND_WORD_LENGTHS: Dictionary = {
	1: [2, 3],
	2: [3, 4],
	3: [4, 5],
	4: [5, 6],
	5: [6, 7],
	6: [7, 8],
	7: [8, 9],
	8: [9, 10],
	9: [10],
	10: [10]
}

# Points based on word length and attempts used
const BASE_POINTS_BY_LENGTH: Dictionary = {
	2: 10,
	3: 15,
	4: 25,
	5: 40,
	6: 60,
	7: 85,
	8: 115,
	9: 150,
	10: 200
}

var current_round: int = 1:
	set(value):
		current_round = value
		round_changed.emit(current_round)

var current_stage: int = 1:
	set(value):
		current_stage = value
		stage_changed.emit(current_stage)

var points: int = 0:
	set(value):
		points = value
		points_changed.emit(points)

var round_points_needed: int = 100:
	set(value):
		round_points_needed = value
		round_points_changed.emit(round_points_needed)

var current_word: String = ""
var words_by_length: Dictionary = {}
var used_words: Array[String] = []

# Currency (game coins)
var currency: int = 0:
	set(value):
		currency = value
		currency_changed.emit(currency)

# Scoring configuration
var scoring_config: ScoringConfig = null


func _ready() -> void:
	_load_scoring_config()
	_load_word_lists()
	reset_game()


func _load_scoring_config() -> void:
	var res_path := "res://data/scoring.res"
	if ResourceLoader.exists(res_path):
		scoring_config = load(res_path)
		if scoring_config:
			return

	# Use defaults if no config found
	push_warning("Could not load scoring.res - using default scoring")
	scoring_config = ScoringConfig.new()


func _load_word_lists() -> void:
	# Load curated word list from words.res
	var res_path := "res://data/words.res"
	if ResourceLoader.exists(res_path):
		var word_dict: WordDictionary = load(res_path)
		if word_dict:
			words_by_length = word_dict.words_by_length.duplicate()
			for length in words_by_length.keys():
				print("Loaded %d words of length %d" % [words_by_length[length].size(), length])
			return

	push_error("Could not find words.res - falling back to dictionary files")
	# Fallback to dictionary files
	for length in range(MIN_WORD_LENGTH, MAX_WORD_LENGTH + 1):
		var dict_path := "res://data/dictionary_%d.res" % length
		if ResourceLoader.exists(dict_path):
			var word_list: WordList = load(dict_path)
			if word_list:
				words_by_length[length] = word_list.words
				print("Loaded %d words of length %d from dictionary" % [word_list.words.size(), length])


func reset_game() -> void:
	current_round = 1
	current_stage = 1
	points = 0
	currency = 0
	round_points_needed = calculate_round_points(current_round)
	used_words.clear()
	current_word = ""


func calculate_round_points(round_num: int) -> int:
	# Points needed increases each round
	return 100 + (round_num - 1) * 50


func get_word_lengths_for_round(round_num: int) -> Array:
	var clamped_round := clampi(round_num, 1, 10)
	return ROUND_WORD_LENGTHS.get(clamped_round, [10])


func pick_random_word() -> String:
	var available_lengths := get_word_lengths_for_round(current_round)

	# Pick a random length from available lengths
	var length: int = available_lengths[randi() % available_lengths.size()]

	if not words_by_length.has(length):
		push_error("No words loaded for length %d" % length)
		return ""

	var word_pool: PackedStringArray = words_by_length[length]
	if word_pool.is_empty():
		push_error("Empty word pool for length %d" % length)
		return ""

	# Try to find a word we haven't used yet
	var attempts := 0
	var max_attempts := 100
	var word := ""

	while attempts < max_attempts:
		var index := randi() % word_pool.size()
		word = word_pool[index].to_upper()

		if word not in used_words:
			break
		attempts += 1

	# If we couldn't find an unused word, just use any word
	if word.is_empty() or (attempts >= max_attempts and word in used_words):
		word = word_pool[randi() % word_pool.size()].to_upper()

	return word


func start_new_word() -> String:
	current_word = pick_random_word()
	used_words.append(current_word)
	new_word_ready.emit(current_word)
	print("New word: %s (Round %d, Stage %d)" % [current_word, current_round, current_stage])
	return current_word


func calculate_points(word_length: int, attempts: int, max_attempts: int) -> int:
	var base_points: int = BASE_POINTS_BY_LENGTH.get(word_length, 50)

	# Bonus for fewer attempts (percentage of max possible bonus)
	var attempt_bonus_percent := 1.0 - (float(attempts - 1) / float(max_attempts - 1))
	var bonus := int(base_points * 0.5 * attempt_bonus_percent)

	return base_points + bonus


## Calculate score based on letter states from all guesses
## letter_states is an Array of arrays, where each inner array contains the states for one row
## States: 0=INCORRECT, 1=WRONG_POSITION, 2=CORRECT
func calculate_letter_score(letter_states: Array, word_solved: bool, attempts: int, max_attempts: int) -> Dictionary:
	var total_points := 0
	var total_currency := 0

	# Calculate points/currency for each letter in each row
	for row_states in letter_states:
		for state in row_states:
			match state:
				0:  # INCORRECT (grey)
					total_points += scoring_config.points_incorrect_letter
					total_currency += scoring_config.currency_incorrect_letter
				1:  # WRONG_POSITION (yellow)
					total_points += scoring_config.points_wrong_position_letter
					total_currency += scoring_config.currency_wrong_position_letter
				2:  # CORRECT (green)
					total_points += scoring_config.points_correct_letter
					total_currency += scoring_config.currency_correct_letter

	# Add bonuses if word was solved
	if word_solved:
		total_points += scoring_config.points_word_solved_bonus
		total_currency += scoring_config.currency_word_solved_bonus

		# Perfect guess bonus (first attempt)
		if attempts == 1:
			total_points += scoring_config.points_perfect_guess_bonus
			total_currency += scoring_config.currency_perfect_guess_bonus

		# Early solve multiplier (solved before using half the attempts)
		@warning_ignore("integer_division")
		if attempts <= max_attempts / 2:
			total_points = int(total_points * scoring_config.points_early_solve_multiplier)
			total_currency = int(total_currency * scoring_config.currency_early_solve_multiplier)

	return {
		"points": total_points,
		"currency": total_currency
	}


func on_word_solved(word: String, attempts: int, max_attempts: int, letter_states: Array) -> void:
	var score := calculate_letter_score(letter_states, true, attempts, max_attempts)
	var points_earned: int = score["points"]
	var currency_earned: int = score["currency"]

	add_points(points_earned)
	add_currency(currency_earned)
	word_completed.emit(word, attempts, points_earned, currency_earned)


func on_word_failed(word: String, letter_states: Array, max_attempts: int) -> void:
	# Still earn points/currency for letters guessed, but no solve bonus
	var score := calculate_letter_score(letter_states, false, max_attempts, max_attempts)
	var points_earned: int = score["points"]
	var currency_earned: int = score["currency"]

	add_points(points_earned)
	add_currency(currency_earned)
	word_failed.emit(word, points_earned, currency_earned)
	advance_stage()


func add_points(amount: int) -> void:
	points += amount


func add_currency(amount: int) -> void:
	currency += amount


func spend_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		return true
	return false


func check_progression() -> void:
	if points >= round_points_needed:
		advance_stage()


func advance_stage() -> void:
	if current_stage < STAGES_PER_ROUND:
		current_stage += 1
	else:
		advance_round()


func advance_round() -> void:
	current_round += 1
	current_stage = 1
	points = 0
	round_points_needed = calculate_round_points(current_round)

	# Check if game is complete (optional max round)
	if current_round > 10:
		game_over.emit()


func get_progress_percentage() -> float:
	if round_points_needed == 0:
		return 0.0
	return float(points) / float(round_points_needed) * 100.0


func get_current_difficulty_description() -> String:
	var lengths := get_word_lengths_for_round(current_round)
	if lengths.size() == 1:
		return "%d-letter words" % lengths[0]
	else:
		return "%d-%d letter words" % [lengths[0], lengths[lengths.size() - 1]]
