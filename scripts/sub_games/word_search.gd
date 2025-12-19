extends Control

signal word_found(word: String)
signal game_closed

const CELL_SIZE: int = 35
const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

@onready var grid_container: GridContainer = %GridContainer
@onready var title_label: Label = %TitleLabel
@onready var hint_label: Label = %HintLabel
@onready var found_label: Label = %FoundLabel

var grid_width: int = 10
var grid_height: int = 10
var target_word: String = ""
var grid: Array = []  # 2D array of letters
var cells: Array = []  # 2D array of Button nodes
var target_positions: Array = []  # Array of Vector2i for target word cells

var is_selecting: bool = false
var selected_cells: Array = []  # Array of Vector2i
var selection_start: Vector2i = Vector2i(-1, -1)
var word_found_flag: bool = false

# Settings data
var _settings_data: Dictionary = {}


func _ready() -> void:
	_load_settings()
	visible = false


func _load_settings() -> void:
	var json_path := "res://data/settings.json"
	if FileAccess.file_exists(json_path):
		var file := FileAccess.open(json_path, FileAccess.READ)
		var json_text := file.get_as_text()
		file.close()
		var json := JSON.new()
		var error := json.parse(json_text)
		if error == OK:
			_settings_data = json.data


func _get_config_for_round(round_num: int) -> Dictionary:
	var sub_games: Dictionary = _settings_data.get("sub_games", {})
	var default_config: Dictionary = sub_games.get("default", {})
	var rounds_config: Dictionary = sub_games.get("rounds", {})

	var round_key := str(round_num)
	if rounds_config.has(round_key):
		return rounds_config[round_key]
	return default_config


func start_game(word: String, round_num: int = 1) -> void:
	# Load round-specific settings
	var config := _get_config_for_round(round_num)
	var word_search_config: Dictionary = config.get("word_search", {})
	grid_width = word_search_config.get("grid_width", 10)
	grid_height = word_search_config.get("grid_height", 10)

	target_word = word.to_upper().replace(" ", "")
	word_found_flag = false
	title_label.text = "WORD SEARCH"
	hint_label.text = "Find the %d-letter word!" % target_word.length()
	found_label.text = ""
	found_label.visible = false
	_generate_grid()
	_create_grid_ui()
	visible = true


func close_game() -> void:
	visible = false
	game_closed.emit()


func _generate_grid() -> void:
	# Initialize empty grid
	grid.clear()
	target_positions.clear()
	for y in range(grid_height):
		var row: Array = []
		for x in range(grid_width):
			row.append("")
		grid.append(row)

	# Place target word
	_place_target_word()

	# Fill remaining cells with random letters
	for y in range(grid_height):
		for x in range(grid_width):
			if grid[y][x] == "":
				grid[y][x] = LETTERS[randi() % LETTERS.length()]


func _place_target_word() -> void:
	var word_len := target_word.length()
	var directions := [
		Vector2i(1, 0),   # Horizontal right
		Vector2i(0, 1),   # Vertical down
		Vector2i(1, 1),   # Diagonal down-right
		Vector2i(-1, 0),  # Horizontal left
		Vector2i(0, -1),  # Vertical up
		Vector2i(-1, -1), # Diagonal up-left
		Vector2i(1, -1),  # Diagonal up-right
		Vector2i(-1, 1),  # Diagonal down-left
	]

	# Try random positions and directions
	var attempts := 0
	var max_attempts := 1000

	while attempts < max_attempts:
		var dir: Vector2i = directions[randi() % directions.size()]
		var start_x := randi() % grid_width
		var start_y := randi() % grid_height

		# Check if word fits
		var end_x := start_x + dir.x * (word_len - 1)
		var end_y := start_y + dir.y * (word_len - 1)

		if end_x >= 0 and end_x < grid_width and end_y >= 0 and end_y < grid_height:
			# Check if cells are empty or match the letter we need
			var can_place := true
			var positions: Array = []

			for i in range(word_len):
				var x := start_x + dir.x * i
				var y := start_y + dir.y * i
				var letter := target_word[i]

				if grid[y][x] != "" and grid[y][x] != letter:
					can_place = false
					break
				positions.append(Vector2i(x, y))

			if can_place:
				# Place the word
				for i in range(word_len):
					var pos: Vector2i = positions[i]
					grid[pos.y][pos.x] = target_word[i]
				target_positions = positions
				return

		attempts += 1

	# Fallback: force place horizontally at top
	push_warning("Word search: Could not place word randomly, forcing placement")
	for i in range(mini(word_len, grid_width)):
		grid[0][i] = target_word[i]
		target_positions.append(Vector2i(i, 0))


func _create_grid_ui() -> void:
	# Clear existing cells
	for child in grid_container.get_children():
		child.queue_free()
	cells.clear()

	grid_container.columns = grid_width

	for y in range(grid_height):
		var row: Array = []
		for x in range(grid_width):
			var button := Button.new()
			button.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			button.text = grid[y][x]
			button.toggle_mode = false
			button.flat = true

			# Style the button
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.2, 0.2)
			style.set_corner_radius_all(4)
			button.add_theme_stylebox_override("normal", style)

			var hover_style := StyleBoxFlat.new()
			hover_style.bg_color = Color(0.3, 0.3, 0.4)
			hover_style.set_corner_radius_all(4)
			button.add_theme_stylebox_override("hover", hover_style)

			button.add_theme_font_size_override("font_size", 16)

			# Connect signals
			button.gui_input.connect(_on_cell_input.bind(Vector2i(x, y)))

			grid_container.add_child(button)
			row.append(button)
		cells.append(row)


func _on_cell_input(event: InputEvent, pos: Vector2i) -> void:
	if word_found_flag:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_selection(pos)
			else:
				_end_selection()
	elif event is InputEventMouseMotion:
		if is_selecting:
			_update_selection(pos)


func _start_selection(pos: Vector2i) -> void:
	is_selecting = true
	selection_start = pos
	selected_cells = [pos]
	_highlight_selected()


func _update_selection(pos: Vector2i) -> void:
	if not is_selecting or selection_start == Vector2i(-1, -1):
		return

	# Calculate direction from start to current
	var dx := pos.x - selection_start.x
	var dy := pos.y - selection_start.y

	# Normalize to get direction
	var dir := Vector2i(signi(dx), signi(dy))

	# Only allow straight lines (horizontal, vertical, diagonal)
	if dir.x != 0 and dir.y != 0 and absi(dx) != absi(dy):
		return  # Not a valid diagonal

	# Build selection line
	selected_cells.clear()
	var steps := maxi(absi(dx), absi(dy))

	for i in range(steps + 1):
		var x := selection_start.x + dir.x * i
		var y := selection_start.y + dir.y * i
		if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
			selected_cells.append(Vector2i(x, y))

	_highlight_selected()


func _end_selection() -> void:
	is_selecting = false

	# Check if selected word matches target
	var selected_word := ""
	for pos in selected_cells:
		selected_word += grid[pos.y][pos.x]

	# Check both forward and reverse
	if selected_word == target_word or selected_word.reverse() == target_word:
		_on_word_found()
	else:
		_clear_selection()

	selection_start = Vector2i(-1, -1)


func _highlight_selected() -> void:
	# Reset all cells
	for y in range(grid_height):
		for x in range(grid_width):
			var button: Button = cells[y][x]
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.2, 0.2)
			style.set_corner_radius_all(4)
			button.add_theme_stylebox_override("normal", style)

	# Highlight selected cells
	for pos in selected_cells:
		var button: Button = cells[pos.y][pos.x]
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.5, 0.8)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override("normal", style)


func _clear_selection() -> void:
	selected_cells.clear()
	_highlight_selected()


func _on_word_found() -> void:
	word_found_flag = true

	# Highlight found word in green
	for pos in selected_cells:
		var button: Button = cells[pos.y][pos.x]
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.7, 0.3)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override("normal", style)

	found_label.text = "Found: %s" % target_word
	found_label.visible = true
	hint_label.text = "Press SHIFT to return"

	word_found.emit(target_word)
