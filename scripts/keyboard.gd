extends PanelContainer

signal key_pressed(key: String)
signal backspace_pressed
signal shift_toggled(is_shifted: bool)

@onready var shift_button: Button = %Shift
@onready var backspace_button: Button = %Backspace

var is_shifted: bool = false


func _ready() -> void:
	_connect_key_buttons()
	shift_button.toggled.connect(_on_shift_toggled)
	backspace_button.pressed.connect(_on_backspace_pressed)


func _connect_key_buttons() -> void:
	var rows := $MarginContainer/VBoxContainer.get_children()
	for row in rows:
		if row is HBoxContainer:
			for button in row.get_children():
				if button is Button and button != shift_button and button != backspace_button:
					button.pressed.connect(_on_key_pressed.bind(button.text))


func _on_key_pressed(key: String) -> void:
	var output_key := key.to_upper() if is_shifted else key.to_lower()
	key_pressed.emit(output_key)

	# Auto-disable shift after a key press (like mobile keyboards)
	if is_shifted:
		is_shifted = false
		shift_button.button_pressed = false


func _on_shift_toggled(pressed: bool) -> void:
	is_shifted = pressed
	shift_toggled.emit(is_shifted)
	_update_key_display()


func _on_backspace_pressed() -> void:
	backspace_pressed.emit()


func _update_key_display() -> void:
	var rows := $MarginContainer/VBoxContainer.get_children()
	for row in rows:
		if row is HBoxContainer:
			for button in row.get_children():
				if button is Button and button != shift_button and button != backspace_button:
					if is_shifted:
						button.text = button.text.to_upper()
					else:
						button.text = button.text.to_upper()  # Keep uppercase for display


func set_shift(enabled: bool) -> void:
	is_shifted = enabled
	shift_button.button_pressed = enabled
	_update_key_display()
