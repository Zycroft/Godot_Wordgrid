extends PanelContainer

signal continue_pressed
signal shop_pressed

@onready var title_label: Label = %Title
@onready var words_found_label: Label = %WordsFound
@onready var points_label: Label = %BasePoints
@onready var gems_label: Label = %BonusPoints
@onready var total_points_label: Label = %TotalPoints
@onready var continue_button: Button = %ContinueButton
@onready var shop_button: Button = %ShopButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_continue_pressed()


func show_score(words_found: int, points: int, gems: int) -> void:
	set_process_unhandled_input(true)
	if words_found > 0:
		words_found_label.text = "Word Solved!"
		words_found_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3))
	else:
		words_found_label.text = "Word Failed"
		words_found_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

	points_label.text = "Points: +%d" % points
	points_label.visible = true

	if gems > 0:
		gems_label.text = "Gems: +%d" % gems
		gems_label.visible = true
	else:
		gems_label.visible = false

	total_points_label.text = "Total Points: %d" % GameManager.points


func set_title(text: String) -> void:
	title_label.text = text


func _on_continue_pressed() -> void:
	set_process_unhandled_input(false)
	continue_pressed.emit()


func _on_shop_pressed() -> void:
	set_process_unhandled_input(false)
	shop_pressed.emit()
