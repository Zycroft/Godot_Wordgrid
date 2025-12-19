class_name LetterCell
extends PanelContainer

signal cell_clicked(cell: LetterCell)

enum State { EMPTY, FILLED, CORRECT, WRONG_POSITION, INCORRECT, SPACE }

const COLOR_EMPTY := Color(0.2, 0.2, 0.25, 0.9)
const COLOR_FILLED := Color(0.3, 0.3, 0.35, 0.9)
const COLOR_CORRECT := Color(0.18, 0.55, 0.34, 0.95)  # Green
const COLOR_WRONG_POSITION := Color(0.71, 0.62, 0.26, 0.95)  # Yellow
const COLOR_INCORRECT := Color(0.35, 0.35, 0.38, 0.95)  # Grey
const COLOR_SELECTED := Color(0.4, 0.4, 0.45, 0.95)
const COLOR_SPACE := Color(0.85, 0.85, 0.82, 0.9)  # Off-white for spaces

@onready var label: Label = %Label

var letter: String = ""
var row: int = 0
var col: int = 0
var state: State = State.EMPTY
var is_selected: bool = false
var style_box: StyleBoxFlat


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	# Get reference to the style box so we can modify it
	style_box = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", style_box)
	_update_appearance()


func set_display_letter(value: String) -> void:
	letter = value.to_upper()
	label.text = letter
	if letter.is_empty():
		state = State.EMPTY
	else:
		state = State.FILLED
	_update_appearance()


func clear() -> void:
	letter = ""
	label.text = ""
	state = State.EMPTY
	is_selected = false
	_update_appearance()


func set_state(new_state: State) -> void:
	state = new_state
	_update_appearance()


func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_appearance()


func set_as_space() -> void:
	letter = " "
	label.text = ""
	state = State.SPACE
	_update_appearance()


func is_space() -> bool:
	return state == State.SPACE


func _update_appearance() -> void:
	if not style_box:
		return

	var color: Color
	if is_selected and state in [State.EMPTY, State.FILLED]:
		color = COLOR_SELECTED
	else:
		match state:
			State.EMPTY:
				color = COLOR_EMPTY
			State.FILLED:
				color = COLOR_FILLED
			State.CORRECT:
				color = COLOR_CORRECT
			State.WRONG_POSITION:
				color = COLOR_WRONG_POSITION
			State.INCORRECT:
				color = COLOR_INCORRECT
			State.SPACE:
				color = COLOR_SPACE

	style_box.bg_color = color


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cell_clicked.emit(self)
