class_name WordGrid
extends CenterContainer

signal guess_submitted(guess: String, is_correct: bool)
signal word_solved(word: String, attempts: int)
signal word_failed(word: String)
signal invalid_word(guess: String)

const DEFAULT_CELL_SIZE: int = 40
const MIN_CELL_SIZE: int = 24
const CELL_SPACING: int = 4
const ROW_SPACING: int = 6
const MAX_GRID_WIDTH: int = 600  # Maximum width before scaling

@onready var grid_container: VBoxContainer = %GridContainer

var letter_cell_scene: PackedScene = preload("res://scenes/ui/letter_cell.tscn")
var target_word: String = ""
var cells: Array = []  # 2D array: cells[row][col]
var current_row: int = 0
var current_col: int = 0
var max_rows: int = 6
var word_length: int = 0
var is_locked: bool = false
var cell_size: int = DEFAULT_CELL_SIZE
var space_positions: Array[int] = []  # Indices of space characters in the phrase

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

	# Find space positions
	space_positions.clear()
	for i in range(word_length):
		if target_word[i] == " ":
			space_positions.append(i)

	# Get try_rows from config - use phrase_try_rows for phrases
	if space_positions.size() > 0:
		max_rows = GameManager.phrase_try_rows
	else:
		max_rows = GameManager.get_try_rows_for_word(GameManager.current_round, word_length)

	# Calculate cell size for scaling
	_calculate_cell_size()
	_build_grid()


func _calculate_cell_size() -> void:
	# Calculate cell size based on word length to fit within max width
	var total_spacing := (word_length - 1) * CELL_SPACING
	var available_width := MAX_GRID_WIDTH - total_spacing
	var calculated_size := available_width / word_length

	# Clamp between min and default size
	cell_size = clampi(calculated_size, MIN_CELL_SIZE, DEFAULT_CELL_SIZE)


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
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
			row_container.add_child(cell)
			row_cells.append(cell)

			# Mark space positions
			if col_idx in space_positions:
				cell.set_as_space()

		cells.append(row_cells)

	current_row = 0
	current_col = 0
	is_locked = false
	_skip_spaces_forward()
	_update_selection()


func _skip_spaces_forward() -> void:
	# Skip over any space positions when moving forward
	while current_col < word_length and current_col in space_positions:
		current_col += 1


func _skip_spaces_backward() -> void:
	# Skip over any space positions when moving backward
	while current_col > 0 and (current_col - 1) in space_positions:
		current_col -= 1


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

	# Skip if current position is a space
	if current_col in space_positions:
		_skip_spaces_forward()
		if current_col >= word_length:
			return

	var cell: LetterCell = cells[current_row][current_col]
	cell.set_display_letter(letter)

	# Move to next cell and skip any spaces
	current_col += 1
	_skip_spaces_forward()
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
		# Skip over any spaces when going backward
		while current_col > 0 and current_col in space_positions:
			current_col -= 1

	# Don't clear if it's a space
	if current_col in space_positions:
		_update_selection()
		return

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

	# Check if all non-space cells are filled
	if not _is_row_filled():
		return 0  # Not enough letters

	# Get the guessed word/phrase
	var guess := ""
	for cell in cells[current_row]:
		guess += cell.letter

	# Only validate against dictionary for single words (no spaces)
	if space_positions.is_empty():
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
		_skip_spaces_forward()

		if current_row >= max_rows:
			# Out of attempts
			is_locked = true
			word_failed.emit(target_word)
		else:
			_update_selection()

		return 1


func _is_row_filled() -> bool:
	# Check if all non-space cells in the current row are filled
	if current_row >= cells.size():
		return false

	for i in range(word_length):
		if i in space_positions:
			continue  # Skip space positions
		var cell: LetterCell = cells[current_row][i]
		if cell.letter.is_empty() or cell.letter == " ":
			return false
	return true


func _clear_current_row() -> void:
	if current_row >= cells.size():
		return

	for i in range(word_length):
		if i in space_positions:
			continue  # Don't clear space cells
		cells[current_row][i].clear()

	current_col = 0
	_skip_spaces_forward()
	_update_selection()


func _evaluate_guess(guess: String) -> bool:
	var guess_upper := guess.to_upper()
	var target_upper := target_word.to_upper()

	if guess_upper == target_upper:
		# All correct - mark non-space cells as correct
		for i in range(word_length):
			if i in space_positions:
				continue  # Keep space state
			cells[current_row][i].set_state(LetterCell.State.CORRECT)
		return true

	# Count letter occurrences in target (excluding spaces)
	var target_letter_counts: Dictionary = {}
	for c in target_upper:
		if c != " ":
			target_letter_counts[c] = target_letter_counts.get(c, 0) + 1

	# First pass: mark correct positions (green), skip spaces
	var cell_states: Array[LetterCell.State] = []
	cell_states.resize(word_length)

	for i in range(word_length):
		if i in space_positions:
			cell_states[i] = LetterCell.State.EMPTY  # Placeholder, won't be applied
		elif guess_upper[i] == target_upper[i]:
			cell_states[i] = LetterCell.State.CORRECT
			target_letter_counts[guess_upper[i]] -= 1
		else:
			cell_states[i] = LetterCell.State.INCORRECT

	# Second pass: mark wrong positions (yellow), skip spaces
	for i in range(word_length):
		if i in space_positions:
			continue
		if cell_states[i] == LetterCell.State.INCORRECT:
			var letter := guess_upper[i]
			if target_letter_counts.get(letter, 0) > 0:
				cell_states[i] = LetterCell.State.WRONG_POSITION
				target_letter_counts[letter] -= 1

	# Apply states to cells (skip spaces to preserve their state)
	for i in range(word_length):
		if i not in space_positions:
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
			if i in space_positions:
				continue  # Skip spaces
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
## States: 0=INCORRECT, 1=WRONG_POSITION, 2=CORRECT (spaces are skipped)
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
		for col_idx in range(cells[row_idx].size()):
			# Skip space positions - they don't count for scoring
			if col_idx in space_positions:
				continue

			var cell: LetterCell = cells[row_idx][col_idx]
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
