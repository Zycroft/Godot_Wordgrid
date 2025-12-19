extends Control

signal puzzle_completed
signal game_closed

const CELL_SIZE: int = 35

# Common short words for crossword filler (grouped by starting letter)
const FILLER_WORDS: Dictionary = {
	"A": ["ACE", "ADD", "AGE", "AID", "AIM", "AIR", "ALL", "AND", "ANT", "APE", "ARC", "ARE", "ARK", "ARM", "ART", "ASH", "ASK", "ATE", "AWE"],
	"B": ["BAD", "BAG", "BAN", "BAR", "BAT", "BED", "BEE", "BIG", "BIT", "BOW", "BOX", "BOY", "BUD", "BUG", "BUS", "BUT", "BUY"],
	"C": ["CAB", "CAN", "CAP", "CAR", "CAT", "COB", "COD", "COG", "COP", "COT", "COW", "CRY", "CUB", "CUD", "CUP", "CUR", "CUT"],
	"D": ["DAD", "DAM", "DAY", "DEN", "DEW", "DID", "DIE", "DIG", "DIM", "DIP", "DOC", "DOE", "DOG", "DOT", "DRY", "DUB", "DUD", "DUE", "DUG"],
	"E": ["EAR", "EAT", "EEL", "EGG", "ELF", "ELK", "ELM", "EMU", "END", "ERA", "EVE", "EWE", "EYE"],
	"F": ["FAD", "FAN", "FAR", "FAT", "FAX", "FED", "FEE", "FEW", "FIG", "FIN", "FIR", "FIT", "FIX", "FLY", "FOB", "FOE", "FOG", "FOR", "FOX", "FRY", "FUN", "FUR"],
	"G": ["GAB", "GAG", "GAP", "GAS", "GAY", "GEL", "GEM", "GET", "GIG", "GIN", "GNU", "GOB", "GOD", "GOT", "GUM", "GUN", "GUT", "GUY", "GYM"],
	"H": ["HAD", "HAM", "HAS", "HAT", "HAY", "HEM", "HEN", "HER", "HEW", "HID", "HIM", "HIP", "HIS", "HIT", "HOB", "HOG", "HOP", "HOT", "HOW", "HUB", "HUE", "HUG", "HUM", "HUT"],
	"I": ["ICE", "ICY", "ILL", "IMP", "INK", "INN", "ION", "IRE", "IRK", "ITS", "IVY"],
	"J": ["JAB", "JAM", "JAR", "JAW", "JAY", "JET", "JIG", "JOB", "JOG", "JOT", "JOY", "JUG", "JUT"],
	"K": ["KEG", "KEN", "KEY", "KID", "KIN", "KIT"],
	"L": ["LAB", "LAD", "LAG", "LAP", "LAW", "LAY", "LEA", "LED", "LEG", "LET", "LID", "LIE", "LIP", "LIT", "LOG", "LOT", "LOW", "LUG"],
	"M": ["MAD", "MAN", "MAP", "MAR", "MAT", "MAW", "MAY", "MEN", "MET", "MID", "MIX", "MOB", "MOM", "MOP", "MOW", "MUD", "MUG", "MUM"],
	"N": ["NAB", "NAG", "NAP", "NAY", "NET", "NEW", "NIL", "NIT", "NOB", "NOD", "NOR", "NOT", "NOW", "NUB", "NUN", "NUT"],
	"O": ["OAK", "OAR", "OAT", "ODD", "ODE", "OFF", "OFT", "OHM", "OIL", "OLD", "ONE", "OPT", "ORB", "ORE", "OUR", "OUT", "OWE", "OWL", "OWN"],
	"P": ["PAD", "PAL", "PAN", "PAT", "PAW", "PAY", "PEA", "PEG", "PEN", "PEP", "PER", "PET", "PEW", "PIE", "PIG", "PIN", "PIT", "PLY", "POD", "POP", "POT", "PRY", "PUB", "PUG", "PUN", "PUP", "PUS", "PUT"],
	"Q": ["QUA"],
	"R": ["RAG", "RAM", "RAN", "RAP", "RAT", "RAW", "RAY", "RED", "REF", "REP", "RIB", "RID", "RIG", "RIM", "RIP", "ROB", "ROD", "ROE", "ROT", "ROW", "RUB", "RUG", "RUM", "RUN", "RUT", "RYE"],
	"S": ["SAC", "SAD", "SAG", "SAP", "SAT", "SAW", "SAY", "SEA", "SET", "SEW", "SHE", "SHY", "SIN", "SIP", "SIR", "SIS", "SIT", "SIX", "SKI", "SKY", "SLY", "SOB", "SOD", "SON", "SOP", "SOT", "SOW", "SOY", "SPA", "SPY", "STY", "SUB", "SUM", "SUN", "SUP"],
	"T": ["TAB", "TAD", "TAG", "TAN", "TAP", "TAR", "TAT", "TAX", "TEA", "TEN", "THE", "THY", "TIC", "TIE", "TIN", "TIP", "TOE", "TON", "TOO", "TOP", "TOT", "TOW", "TOY", "TUB", "TUG", "TWO"],
	"U": ["UGH", "UMP", "UNS", "UPS", "URN", "USE"],
	"V": ["VAN", "VAT", "VET", "VIA", "VIE", "VOW"],
	"W": ["WAD", "WAG", "WAR", "WAS", "WAX", "WAY", "WEB", "WED", "WEE", "WET", "WHO", "WHY", "WIG", "WIN", "WIT", "WOE", "WOK", "WON", "WOO", "WOW"],
	"X": ["WAX"],
	"Y": ["YAK", "YAM", "YAP", "YAW", "YEA", "YEP", "YES", "YET", "YEW", "YIN", "YIP", "YOU", "YOW"],
	"Z": ["ZAP", "ZED", "ZEN", "ZIP", "ZIT", "ZOO"]
}

@onready var grid_container: GridContainer = %GridContainer
@onready var title_label: Label = %TitleLabel
@onready var clues_label: Label = %CluesLabel
@onready var status_label: Label = %StatusLabel

var num_questions: int = 5
var target_word: String = ""
var grid_width: int = 15
var grid_height: int = 15
var grid: Array = []  # 2D array of letters (empty string = blocked cell)
var cells: Array = []  # 2D array of UI elements
var words_data: Array = []  # Array of {word, start_pos, direction, clue_num, is_target}
var input_cells: Dictionary = {}  # Vector2i -> LineEdit mapping
var completed_words: int = 0

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
	var crossword_config: Dictionary = config.get("crossword", {})
	num_questions = crossword_config.get("num_questions", 5)

	target_word = word.to_upper().replace(" ", "")
	completed_words = 0
	title_label.text = "CROSSWORD"
	status_label.text = "Fill in the words!"
	_generate_puzzle()
	_create_grid_ui()
	_update_clues()
	visible = true


func close_game() -> void:
	visible = false
	game_closed.emit()


func _generate_puzzle() -> void:
	# Initialize empty grid
	grid.clear()
	words_data.clear()

	# Size grid based on target word
	grid_width = maxi(target_word.length() + 4, 12)
	grid_height = maxi(num_questions + 2, 8)

	for y in range(grid_height):
		var row: Array = []
		for x in range(grid_width):
			row.append("")  # Empty = blocked
		grid.append(row)

	# Place target word horizontally in center
	var start_y := grid_height / 2
	var start_x := (grid_width - target_word.length()) / 2

	for i in range(target_word.length()):
		grid[start_y][start_x + i] = target_word[i]

	words_data.append({
		"word": target_word,
		"start": Vector2i(start_x, start_y),
		"direction": "across",
		"clue_num": 1,
		"is_target": true
	})

	# Add intersecting words
	var clue_num := 2
	var added_words := 1

	for i in range(target_word.length()):
		if added_words >= num_questions:
			break

		var letter := target_word[i]
		var x := start_x + i
		var y := start_y

		# Try to find a word containing this letter to place vertically
		var cross_word := _find_word_with_letter(letter)
		if cross_word.is_empty():
			continue

		# Find where the letter appears in the cross word
		var letter_index := cross_word.find(letter)
		if letter_index == -1:
			continue

		# Calculate vertical placement
		var word_start_y := y - letter_index
		var word_end_y := word_start_y + cross_word.length() - 1

		# Check if it fits
		if word_start_y < 0 or word_end_y >= grid_height:
			continue

		# Check for conflicts (except at intersection)
		var can_place := true
		for j in range(cross_word.length()):
			var check_y := word_start_y + j
			if check_y == y:
				continue  # Skip intersection point
			if grid[check_y][x] != "":
				can_place = false
				break

		if not can_place:
			continue

		# Place the word
		for j in range(cross_word.length()):
			var place_y := word_start_y + j
			grid[place_y][x] = cross_word[j]

		words_data.append({
			"word": cross_word,
			"start": Vector2i(x, word_start_y),
			"direction": "down",
			"clue_num": clue_num,
			"is_target": false
		})

		clue_num += 1
		added_words += 1


func _find_word_with_letter(letter: String) -> String:
	var letter_upper := letter.to_upper()
	if FILLER_WORDS.has(letter_upper):
		var candidates: Array = FILLER_WORDS[letter_upper]
		if candidates.size() > 0:
			# Find a word where the letter is not at the start (so it can intersect properly)
			var shuffled: Array = candidates.duplicate()
			shuffled.shuffle()
			for i in range(shuffled.size()):
				var word: String = shuffled[i]
				var idx: int = word.find(letter_upper)
				if idx > 0 and idx < word.length() - 1:
					return word
			# Fallback to any word with the letter
			return shuffled[0]

	# Try to find in other letter lists
	for key in FILLER_WORDS.keys():
		var word_list: Array = FILLER_WORDS[key]
		for i in range(word_list.size()):
			var word: String = word_list[i]
			if word.find(letter_upper) > 0:
				return word

	return ""


func _create_grid_ui() -> void:
	# Clear existing - use free() instead of queue_free() for immediate removal
	for child in grid_container.get_children():
		child.free()
	cells.clear()
	input_cells.clear()

	grid_container.columns = grid_width

	# Create cells that belong to words
	var word_cells: Dictionary = {}  # Vector2i -> true
	for word_data in words_data:
		var start: Vector2i = word_data["start"]
		var word: String = word_data["word"]
		var dir: String = word_data["direction"]

		for i in range(word.length()):
			var pos: Vector2i
			if dir == "across":
				pos = Vector2i(start.x + i, start.y)
			else:
				pos = Vector2i(start.x, start.y + i)
			word_cells[pos] = true

	for y in range(grid_height):
		var row: Array = []
		for x in range(grid_width):
			var pos := Vector2i(x, y)

			if word_cells.has(pos):
				# Create input cell
				var container := PanelContainer.new()
				container.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)

				var style := StyleBoxFlat.new()
				style.bg_color = Color(0.95, 0.95, 0.95)
				style.set_corner_radius_all(2)
				container.add_theme_stylebox_override("panel", style)

				var input := LineEdit.new()
				input.custom_minimum_size = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
				input.max_length = 1
				input.alignment = HORIZONTAL_ALIGNMENT_CENTER
				input.add_theme_font_size_override("font_size", 18)
				input.add_theme_color_override("font_color", Color.BLACK)
				input.text_changed.connect(_on_cell_text_changed.bind(pos))

				container.add_child(input)
				grid_container.add_child(container)
				row.append(container)
				input_cells[pos] = input
			else:
				# Create blocked cell
				var blocked := ColorRect.new()
				blocked.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
				blocked.color = Color(0.15, 0.15, 0.2)
				grid_container.add_child(blocked)
				row.append(blocked)

		cells.append(row)


func _update_clues() -> void:
	var clue_text := ""

	# Across clues
	clue_text += "ACROSS:\n"
	for word_data in words_data:
		if word_data["direction"] == "across":
			var num: int = word_data["clue_num"]
			var word: String = word_data["word"]
			var hint := _generate_hint(word, word_data["is_target"])
			clue_text += "%d. %s\n" % [num, hint]

	clue_text += "\nDOWN:\n"
	for word_data in words_data:
		if word_data["direction"] == "down":
			var num: int = word_data["clue_num"]
			var word: String = word_data["word"]
			var hint := _generate_hint(word, false)
			clue_text += "%d. %s\n" % [num, hint]

	clues_label.text = clue_text


func _generate_hint(word: String, is_target: bool) -> String:
	if is_target:
		# Give partial reveal for target word
		var hint := ""
		for i in range(word.length()):
			if i == 0 or i == word.length() - 1:
				hint += word[i]
			else:
				hint += "_"
			hint += " "
		return "??? (%s)" % hint.strip_edges()
	else:
		# Simple letter count hint
		return "%d letters, starts with '%s'" % [word.length(), word[0]]


func _on_cell_text_changed(new_text: String, pos: Vector2i) -> void:
	if new_text.length() > 0:
		var input: LineEdit = input_cells[pos]
		input.text = new_text.to_upper()[0]

	_check_completion()


func _check_completion() -> void:
	var all_correct := true
	var filled_count := 0
	var total_cells := input_cells.size()

	for pos in input_cells.keys():
		var input: LineEdit = input_cells[pos]
		var expected: String = grid[pos.y][pos.x]

		if input.text.is_empty():
			all_correct = false
		elif input.text.to_upper() != expected:
			all_correct = false
		else:
			filled_count += 1

	status_label.text = "Filled: %d/%d" % [filled_count, total_cells]

	if all_correct and filled_count == total_cells:
		_on_puzzle_completed()


func _on_puzzle_completed() -> void:
	status_label.text = "Completed! Press SHIFT to return"

	# Highlight all cells green
	for pos in input_cells.keys():
		var input: LineEdit = input_cells[pos]
		var container := input.get_parent() as PanelContainer
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.7, 1.0, 0.7)
		style.set_corner_radius_all(2)
		container.add_theme_stylebox_override("panel", style)

	puzzle_completed.emit()
