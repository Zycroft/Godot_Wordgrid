extends Control

@onready var word_grid: WordGrid = %WordGrid
@onready var bottom_panel: Control = %BottomPanel
@onready var title_label: Label = %Title
@onready var debug_label: Label = %DebugLabel
@onready var message_label: Label = %MessageLabel
@onready var shop_overlay: Control = %ShopOverlay
@onready var bookshelf: Control = %Bookshelf
@onready var sub_game_selector: Control = %SubGameSelector
@onready var word_search_game: Control = %WordSearchGame
@onready var crossword_game: Control = %CrosswordGame

var waiting_for_continue: bool = false
var debug_mode: bool = false
var message_tween: Tween
var in_sub_game: bool = false
var sub_game_cost: int = 5

# Settings data for sub-games
var _sub_game_settings: Dictionary = {}


func _ready() -> void:
	# Connect keyboard signals
	bottom_panel.key_pressed.connect(_on_key_pressed)
	bottom_panel.backspace_pressed.connect(_on_backspace_pressed)
	bottom_panel.continue_pressed.connect(_on_continue_pressed)
	bottom_panel.shop_pressed.connect(_on_shop_pressed)
	bottom_panel.sub_game_requested.connect(_on_sub_game_requested)

	# Connect word grid signals
	word_grid.word_solved.connect(_on_word_solved)
	word_grid.word_failed.connect(_on_word_failed)
	word_grid.invalid_word.connect(_on_invalid_word)

	# Connect game manager signals
	GameManager.word_completed.connect(_on_game_word_completed)
	GameManager.word_failed.connect(_on_game_word_failed)

	# Connect title click for debug toggle
	title_label.gui_input.connect(_on_title_gui_input)

	# Connect sub-game signals
	sub_game_selector.game_selected.connect(_on_sub_game_selected)
	sub_game_selector.cancelled.connect(_on_sub_game_cancelled)
	word_search_game.word_found.connect(_on_word_search_found)
	word_search_game.game_closed.connect(_on_sub_game_closed)
	crossword_game.puzzle_completed.connect(_on_crossword_completed)
	crossword_game.game_closed.connect(_on_sub_game_closed)

	# Load sub-game cost from settings
	_load_sub_game_settings()

	# Start the game
	_start_new_word()


func _load_sub_game_settings() -> void:
	var json_path := "res://data/settings.json"
	if FileAccess.file_exists(json_path):
		var file := FileAccess.open(json_path, FileAccess.READ)
		var json_text := file.get_as_text()
		file.close()
		var json := JSON.new()
		var error := json.parse(json_text)
		if error == OK:
			var data: Dictionary = json.data
			_sub_game_settings = data.get("sub_games", {})
			# Set initial cost from default
			var default_config: Dictionary = _sub_game_settings.get("default", {})
			sub_game_cost = default_config.get("cost", 5)


func _get_sub_game_cost_for_round(round_num: int) -> int:
	var rounds_config: Dictionary = _sub_game_settings.get("rounds", {})
	var default_config: Dictionary = _sub_game_settings.get("default", {})

	var round_key := str(round_num)
	if rounds_config.has(round_key):
		return rounds_config[round_key].get("cost", default_config.get("cost", 5))
	return default_config.get("cost", 5)


func _start_new_word() -> void:
	waiting_for_continue = false
	var word := GameManager.start_new_word()
	word_grid.set_target_word(word)
	_update_debug_label()


func _on_title_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.ctrl_pressed:
				_toggle_debug_mode()


func _toggle_debug_mode() -> void:
	debug_mode = not debug_mode
	debug_label.visible = debug_mode
	_update_debug_label()


func _update_debug_label() -> void:
	if debug_mode:
		debug_label.text = "Target: %s" % GameManager.current_word


func _on_key_pressed(key: String) -> void:
	if waiting_for_continue:
		return

	# Check for Enter key to submit
	if key == "ENTER" or key == "\n":
		_submit_guess()
	else:
		word_grid.enter_letter(key)


func _on_backspace_pressed() -> void:
	if waiting_for_continue:
		return
	word_grid.backspace()


func _submit_guess() -> void:
	if word_grid.is_row_complete():
		word_grid.submit_guess()


func _on_word_solved(word: String, attempts: int) -> void:
	waiting_for_continue = true
	var letter_states := word_grid.get_all_letter_states()
	GameManager.on_word_solved(word, attempts, word_grid.max_rows, letter_states)


func _on_word_failed(word: String) -> void:
	waiting_for_continue = true
	word_grid.reveal_answer()
	var letter_states := word_grid.get_all_letter_states()
	GameManager.on_word_failed(word, letter_states, word_grid.max_rows)


func _on_invalid_word(_guess: String) -> void:
	_show_message("Not a valid word")


func _show_message(text: String) -> void:
	# Cancel any existing tween
	if message_tween:
		message_tween.kill()

	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0

	# Fade out after 2 seconds
	message_tween = create_tween()
	message_tween.tween_interval(1.5)
	message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	message_tween.tween_callback(func(): message_label.visible = false)


func _on_game_word_completed(_word: String, _attempts: int, points: int, currency: int) -> void:
	# Show stage score with points and currency earned
	bottom_panel.show_stage_score(1, points, currency)


func _on_game_word_failed(_word: String, points: int, currency: int) -> void:
	# Show failed state with any points/currency earned from letters
	bottom_panel.show_stage_score(0, points, currency)


func _on_continue_pressed() -> void:
	if waiting_for_continue:
		_start_new_word()


func _on_shop_pressed() -> void:
	shop_overlay.open(bookshelf)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Handle shift key for sub-games
		if event.keycode == KEY_SHIFT:
			if in_sub_game:
				_close_sub_game()
			elif bottom_panel.is_shift_glowing() and not waiting_for_continue:
				_on_sub_game_requested()
			get_viewport().set_input_as_handled()
			return

		# Don't capture other keyboard input when in a sub-game (let LineEdits receive input)
		if in_sub_game:
			return

		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if waiting_for_continue:
				_on_continue_pressed()
			else:
				_submit_guess()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BACKSPACE:
			_on_backspace_pressed()
			get_viewport().set_input_as_handled()
		elif event.unicode > 0:
			var key_char := String.chr(event.unicode).to_upper()
			if key_char >= "A" and key_char <= "Z":
				_on_key_pressed(key_char)
				get_viewport().set_input_as_handled()


# Sub-game functions
func _on_sub_game_requested() -> void:
	if waiting_for_continue or in_sub_game:
		return

	# Get cost for current round
	var current_cost := _get_sub_game_cost_for_round(GameManager.current_round)

	# Check if player has enough gems
	if GameManager.currency < current_cost:
		_show_message("Need %d gems!" % current_cost)
		return

	# Show the selector
	sub_game_selector.open()


func _on_sub_game_selected(game_type: String) -> void:
	# Get cost for current round
	var current_cost := _get_sub_game_cost_for_round(GameManager.current_round)

	# Deduct gems
	if not GameManager.spend_currency(current_cost):
		_show_message("Not enough gems!")
		return

	in_sub_game = true
	word_grid.visible = false

	# Start the selected game with current round number
	var current_round := GameManager.current_round
	if game_type == "word_search":
		word_search_game.start_game(GameManager.current_word, current_round)
	elif game_type == "crossword":
		crossword_game.start_game(GameManager.current_word, current_round)


func _on_sub_game_cancelled() -> void:
	# Just close the selector, no gems spent
	pass


func _close_sub_game() -> void:
	in_sub_game = false
	word_search_game.close_game()
	crossword_game.close_game()
	word_grid.visible = true


func _on_sub_game_closed() -> void:
	in_sub_game = false
	word_grid.visible = true


func _on_word_search_found(_word: String) -> void:
	_show_message("Word found! Press SHIFT to return")


func _on_crossword_completed() -> void:
	_show_message("Puzzle complete! Press SHIFT to return")
