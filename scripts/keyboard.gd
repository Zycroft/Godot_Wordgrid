extends PanelContainer

signal key_pressed(key: String)
signal backspace_pressed
signal shift_toggled(is_shifted: bool)
signal sub_game_requested

@onready var shift_button: Button = %Shift
@onready var backspace_button: Button = %Backspace

var is_shifted: bool = false

# Shift glow settings (loaded from settings.json)
var shift_glow_enabled: bool = true
var shift_glow_threshold: int = 5
var shift_glow_color: Color = Color("#4488FF")
var _original_shift_modulate: Color = Color.WHITE
var _is_glowing: bool = false


func _ready() -> void:
	_load_settings()
	_connect_key_buttons()
	shift_button.toggled.connect(_on_shift_toggled)
	backspace_button.pressed.connect(_on_backspace_pressed)
	_original_shift_modulate = shift_button.modulate

	# Connect to GameManager currency changes
	if GameManager:
		GameManager.currency_changed.connect(_on_currency_changed)
		_update_shift_glow(GameManager.currency)


func _load_settings() -> void:
	var json_path := "res://data/settings.json"
	if FileAccess.file_exists(json_path):
		var file := FileAccess.open(json_path, FileAccess.READ)
		var json_text := file.get_as_text()
		file.close()
		var json := JSON.new()
		var error := json.parse(json_text)
		if error == OK:
			var data: Dictionary = json.data
			var keyboard_settings: Dictionary = data.get("keyboard", {})
			shift_glow_enabled = keyboard_settings.get("shift_glow_enabled", true)
			shift_glow_threshold = keyboard_settings.get("shift_glow_threshold", 5)
			var color_hex: String = keyboard_settings.get("shift_glow_color", "#4488FF")
			shift_glow_color = Color(color_hex)
			return
	push_warning("Could not load settings.json - using default shift glow settings")


func _on_currency_changed(new_currency: int) -> void:
	_update_shift_glow(new_currency)


func _update_shift_glow(gem_count: int) -> void:
	if not shift_glow_enabled:
		shift_button.modulate = _original_shift_modulate
		_is_glowing = false
		return

	if gem_count > shift_glow_threshold:
		shift_button.modulate = shift_glow_color
		_is_glowing = true
	else:
		shift_button.modulate = _original_shift_modulate
		_is_glowing = false


func is_shift_glowing() -> bool:
	return _is_glowing


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
	# If glowing, emit sub_game_requested instead of normal shift behavior
	if _is_glowing:
		# Reset the button state (don't actually toggle)
		shift_button.set_pressed_no_signal(false)
		sub_game_requested.emit()
		return

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
