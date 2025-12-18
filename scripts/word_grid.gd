class_name WordGrid
extends CenterContainer

signal guess_submitted(guess: String, is_correct: bool)
signal word_solved(word: String, attempts: int)
signal word_failed(word: String)
signal invalid_word(guess: String)

const CELL_SIZE: int = 40
const CELL_SPACING: int = 4
const ROW_SPACING: int = 6

# Rows based on word length: 2-letter=3 rows, 6-letter=10 rows
const ROWS_BY_LENGTH: Dictionary = {
	2: 3,
	3: 4,
	4: 5,
	5: 6,
	6: 10,
	7: 10,
	8: 10,
	9: 10,
	10: 10
}

@onready var grid_container: VBoxContainer = %GridContainer

var letter_cell_scene: PackedScene = preload("res://scenes/ui/letter_cell.tscn")
var target_word: String = ""
var cells: Array = []  # 2D array: cells[row][col]
var current_row: int = 0
var current_col: int = 0
var max_rows: int = 6
var word_length: int = 0
var is_locked: bool = false

# Word validation
var valid_words: ValidWords = null


func _ready() -> void:
	_load_valid_words()


func _load_valid_words() -> void:
	var res_path := "res://data/valid_words.res"
	if ResourceLoader.exists(res_path):
		valid_words = load(res_path)
		if valid_words:
			print("Loaded valid words dictionary with %d words" % valid_words.word_set.size())
	else:
		push_error("Could not load valid_words.res")


func is_valid_word(word: String) -> bool:
	if valid_words == null:
		return true  # If no dictionary loaded, accept all words
	return valid_words.word_set.has(word.to_upper())


func set_target_word(word: String) -> void:
	target_word = word.to_upper()
	word_length = target_word.length()
	max_rows = ROWS_BY_LENGTH.get(word_length, 6)
	_build_grid()


func _build_grid() -> void:
	# Clear existing grid
	for child in grid_container.get_children():
		child.queue_free()
	cells.clear()

	if target_word.is_empty():
		return

	# Create rows
	for row_idx in range(max_rows):
		var row_container := HBoxContainer.new()
		row_container.add_theme_constant_override("separation", CELL_SPACING)
		row_container.alignment = BoxContainer.ALIGNMENT_CENTER
		grid_container.add_child(row_container)

		var row_cells: Array[LetterCell] = []

		# Create cells for each letter
		for col_idx in range(word_length):
			var cell: LetterCell = letter_cell_scene.instantiate()
			cell.row = row_idx
			cell.col = col_idx
			cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			row_container.add_child(cell)
			row_cells.append(cell)

		cells.append(row_cells)

	current_row = 0
	current_col = 0
	is_locked = false
	_update_selection()


func _update_selection() -> void:
	# Clear all selections
	for row in cells:
		for cell in row:
			cell.set_selected(false)

	# Highlight current cell if not locked
	if not is_locked and current_row < cells.size() and current_col < cells[current_row].size():
		cells[current_row][current_col].set_selected(true)


func enter_letter(letter: String) -> void:
	if is_locked:
		return
	if current_row >= cells.size():
		return
	if current_col >= word_length:
		return

	var cell: LetterCell = cells[current_row][current_col]
	cell.set_display_letter(letter)

	# Move to next cell
	current_col += 1
	if current_col > word_length:
		current_col = word_length

	_update_selection()


func backspace() -> void:
	if is_locked:
		return
	if current_row >= cells.size():
		return

	# If at the end of a filled row, move back first
	if current_col > 0:
		current_col -= 1

	# Clear the current cell
	var cell: LetterCell = cells[current_row][current_col]
	cell.clear()

	_update_selection()


func submit_guess() -> int:
	# Returns: 0 = invalid/not ready, 1 = valid but wrong, 2 = correct
	if is_locked:
		return 0
	if current_row >= cells.size():
		return 0

	# Check if row is fully filled
	if current_col < word_length:
		return 0  # Not enough letters

	# Get the guessed word
	var guess := ""
	for cell in cells[current_row]:
		guess += cell.letter

	# Validate the word against dictionary
	if not is_valid_word(guess):
		invalid_word.emit(guess)
		_clear_current_row()
		return 0

	# Evaluate the guess
	var is_correct := _evaluate_guess(guess)

	if is_correct:
		is_locked = true
		word_solved.emit(target_word, current_row + 1)
		guess_submitted.emit(guess, true)
		return 2
	else:
		guess_submitted.emit(guess, false)
		# Move to next row
		current_row += 1
		current_col = 0

		if current_row >= max_rows:
			# Out of attempts
			is_locked = true
			word_failed.emit(target_word)
		else:
			_update_selection()

		return 1


func _clear_current_row() -> void:
	if current_row >= cells.size():
		return

	for cell in cells[current_row]:
		cell.clear()

	current_col = 0
	_update_selection()


func _evaluate_guess(guess: String) -> bool:
	var guess_upper := guess.to_upper()
	var target_upper := target_word.to_upper()

	if guess_upper == target_upper:
		# All correct
		for cell in cells[current_row]:
			cell.set_state(LetterCell.State.CORRECT)
		return true

	# Count letter occurrences in target
	var target_letter_counts: Dictionary = {}
	for c in target_upper:
		target_letter_counts[c] = target_letter_counts.get(c, 0) + 1

	# First pass: mark correct positions (green)
	var cell_states: Array[LetterCell.State] = []
	cell_states.resize(word_length)

	for i in range(word_length):
		if guess_upper[i] == target_upper[i]:
			cell_states[i] = LetterCell.State.CORRECT
			target_letter_counts[guess_upper[i]] -= 1
		else:
			cell_states[i] = LetterCell.State.INCORRECT

	# Second pass: mark wrong positions (yellow)
	for i in range(word_length):
		if cell_states[i] == LetterCell.State.INCORRECT:
			var letter := guess_upper[i]
			if target_letter_counts.get(letter, 0) > 0:
				cell_states[i] = LetterCell.State.WRONG_POSITION
				target_letter_counts[letter] -= 1

	# Apply states to cells
	for i in range(word_length):
		cells[current_row][i].set_state(cell_states[i])

	return false


func get_current_guess() -> String:
	if current_row >= cells.size():
		return ""

	var guess := ""
	for cell in cells[current_row]:
		guess += cell.letter
	return guess


func is_row_complete() -> bool:
	return current_col >= word_length


func reveal_answer() -> void:
	# Show the correct answer in the current row
	if current_row < cells.size():
		for i in range(word_length):
			cells[current_row][i].set_display_letter(target_word[i])
			cells[current_row][i].set_state(LetterCell.State.CORRECT)


func get_attempts_used() -> int:
	return current_row + 1


func reset() -> void:
	for row in cells:
		for cell in row:
			cell.clear()
	current_row = 0
	current_col = 0
	is_locked = false
	_update_selection()


## Get all letter states for scoring calculation
## Returns an Array of Arrays, where each inner array contains integer states for one row
## States: 0=INCORRECT, 1=WRONG_POSITION, 2=CORRECT
func get_all_letter_states() -> Array:
	var all_states: Array = []

	# Only include rows that have been submitted (up to current_row)
	var rows_to_check := current_row
	if is_locked:
		rows_to_check = current_row + 1  # Include the last submitted row

	for row_idx in range(rows_to_check):
		if row_idx >= cells.size():
			break

		var row_states: Array[int] = []
		for cell in cells[row_idx]:
			# Convert LetterCell.State to integer for GameManager
			match cell.state:
				LetterCell.State.INCORRECT:
					row_states.append(0)
				LetterCell.State.WRONG_POSITION:
					row_states.append(1)
				LetterCell.State.CORRECT:
					row_states.append(2)
				_:
					# EMPTY or FILLED states shouldn't be in submitted rows
					row_states.append(0)

		all_states.append(row_states)

	return all_states
