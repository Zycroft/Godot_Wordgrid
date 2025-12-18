extends Control

signal key_pressed(key: String)
signal backspace_pressed
signal shift_toggled(is_shifted: bool)
signal continue_pressed
signal shop_pressed

@onready var keyboard: PanelContainer = %Keyboard
@onready var stage_score: PanelContainer = %StageScore

const SLIDE_DURATION: float = 0.3

var _tween: Tween


func _ready() -> void:
	# Connect keyboard signals
	keyboard.key_pressed.connect(func(key): key_pressed.emit(key))
	keyboard.backspace_pressed.connect(func(): backspace_pressed.emit())
	keyboard.shift_toggled.connect(func(shifted): shift_toggled.emit(shifted))

	# Connect stage score signals
	stage_score.continue_pressed.connect(_on_continue_pressed)
	stage_score.shop_pressed.connect(_on_shop_pressed)

	# Initial state
	keyboard.visible = true
	keyboard.position.y = 0
	stage_score.visible = false


func show_keyboard() -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BACK)

	# Slide stage score down if visible
	if stage_score.visible:
		_tween.tween_property(stage_score, "position:y", size.y, SLIDE_DURATION)
		_tween.tween_callback(func(): stage_score.visible = false)

	# Reset keyboard position and show
	keyboard.position.y = size.y
	keyboard.visible = true
	_tween.tween_property(keyboard, "position:y", 0.0, SLIDE_DURATION)


func show_stage_score(word_solved: int, points: int, gems: int) -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BACK)

	# Slide keyboard down
	_tween.tween_property(keyboard, "position:y", size.y, SLIDE_DURATION)
	_tween.tween_callback(func(): keyboard.visible = false)

	# Setup and show stage score
	stage_score.show_score(word_solved, points, gems)
	stage_score.position.y = size.y
	stage_score.visible = true
	_tween.tween_property(stage_score, "position:y", 0.0, SLIDE_DURATION)


func show_round_complete(word_solved: int, points: int, gems: int) -> void:
	stage_score.set_title("Round Complete!")
	show_stage_score(word_solved, points, gems)


func _on_continue_pressed() -> void:
	continue_pressed.emit()
	show_keyboard()


func _on_shop_pressed() -> void:
	shop_pressed.emit()
