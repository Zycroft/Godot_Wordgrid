extends Control

signal game_selected(game_type: String)
signal cancelled

@onready var word_search_button: Button = %WordSearchButton
@onready var crossword_button: Button = %CrosswordButton
@onready var cancel_button: Button = %CancelButton


func _ready() -> void:
	word_search_button.pressed.connect(_on_word_search_pressed)
	crossword_button.pressed.connect(_on_crossword_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	visible = false


func open() -> void:
	visible = true


func close() -> void:
	visible = false


func _on_word_search_pressed() -> void:
	close()
	game_selected.emit("word_search")


func _on_crossword_pressed() -> void:
	close()
	game_selected.emit("crossword")


func _on_cancel_pressed() -> void:
	close()
	cancelled.emit()
