extends Control

signal closed
signal book_purchased(rarity: String, book_data: Dictionary)

@onready var gems_label: Label = %GemsLabel
@onready var book_options: Array[VBoxContainer] = [%BookOption1, %BookOption2, %BookOption3]
@onready var close_button: Button = %CloseButton
@onready var complete_label: Label = %CompleteLabel

var shop_config: ShopConfig = null
var bookshelf: Control = null
var current_offers: Array[Dictionary] = []
var books_data: Dictionary = {}

# Book colors from bookshelf
const BOOK_COLORS: Array[Color] = [
	Color(0.6, 0.2, 0.2, 1),   # Dark red
	Color(0.2, 0.4, 0.6, 1),   # Blue
	Color(0.2, 0.5, 0.3, 1),   # Green
	Color(0.5, 0.3, 0.5, 1),   # Purple
	Color(0.6, 0.5, 0.2, 1),   # Gold
	Color(0.4, 0.25, 0.15, 1), # Brown
	Color(0.3, 0.3, 0.5, 1),   # Navy
	Color(0.5, 0.2, 0.3, 1),   # Maroon
	Color(0.2, 0.4, 0.4, 1),   # Teal
]


func _ready() -> void:
	_load_shop_config()
	_load_books_data()
	close_button.pressed.connect(_on_close_pressed)

	# Connect buy buttons for each option
	for i in range(book_options.size()):
		var buy_button: Button = book_options[i].get_node("BuyButton")
		buy_button.pressed.connect(_on_buy_pressed.bind(i))

	visible = false


func _load_shop_config() -> void:
	var res_path := "res://data/shop.res"
	if ResourceLoader.exists(res_path):
		shop_config = load(res_path)
		if shop_config:
			return

	push_warning("Could not load shop.res - using default shop config")
	shop_config = ShopConfig.new()


func _load_books_data() -> void:
	var json_path := "res://data/books.json"
	if FileAccess.file_exists(json_path):
		var file := FileAccess.open(json_path, FileAccess.READ)
		var json_text := file.get_as_text()
		file.close()
		var json := JSON.new()
		var error := json.parse(json_text)
		if error == OK:
			books_data = json.data.get("books", {})
		else:
			push_warning("Failed to parse books.json")
	else:
		push_warning("books.json not found")


func open(bookshelf_ref: Control) -> void:
	bookshelf = bookshelf_ref

	# Check if bookshelf is complete
	if bookshelf.is_all_complete():
		_show_complete_state()
	else:
		_generate_offers()
		_update_display()

	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _show_complete_state() -> void:
	complete_label.visible = true
	for option in book_options:
		option.visible = false


func _get_random_book(rarity: String) -> Dictionary:
	var rarity_books: Array = books_data.get(rarity, [])
	if rarity_books.is_empty():
		return {"name": "Unknown Book", "description": "", "gem_modifier": {"type": "+", "value": 0}, "point_modifier": {"type": "+", "value": 0}}
	return rarity_books[randi() % rarity_books.size()]


func _generate_offers() -> void:
	current_offers.clear()
	complete_label.visible = false

	# Get next book index that will be collected (row by row order)
	var next_book_index := -1
	for i in range(9):
		if not bookshelf.collected_books[i]:
			next_book_index = i
			break

	if next_book_index == -1:
		_show_complete_state()
		return

	# Generate 3 random offers with different rarities
	for i in range(3):
		var rarity := shop_config.roll_rarity()
		var price := shop_config.get_price(rarity)
		var rarity_color := shop_config.get_color(rarity)
		var book_data := _get_random_book(rarity)

		# Use the next book's color for preview
		var book_color := BOOK_COLORS[next_book_index % BOOK_COLORS.size()]

		current_offers.append({
			"rarity": rarity,
			"price": price,
			"rarity_color": rarity_color,
			"book_color": book_color,
			"book_data": book_data
		})


func _update_display() -> void:
	gems_label.text = "Your Gems: %d" % GameManager.currency

	for i in range(book_options.size()):
		var option := book_options[i]
		option.visible = true

		if i < current_offers.size():
			var offer := current_offers[i]

			var rarity_label: Label = option.get_node("RarityLabel")
			var book_name_label: Label = option.get_node("BookNameLabel")
			var book_preview: ColorRect = option.get_node("BookPreview")
			var price_label: Label = option.get_node("PriceLabel")
			var buy_button: Button = option.get_node("BuyButton")

			rarity_label.text = offer["rarity"].to_upper()
			rarity_label.add_theme_color_override("font_color", offer["rarity_color"])

			var book_data: Dictionary = offer["book_data"]
			book_name_label.text = book_data.get("name", "Unknown")

			book_preview.color = offer["book_color"]

			var price: int = offer["price"]
			price_label.text = "%d gems" % price

			# Enable/disable based on affordability
			var can_afford: bool = GameManager.currency >= price
			buy_button.disabled = not can_afford
			if can_afford:
				buy_button.text = "Buy"
			else:
				buy_button.text = "Can't Afford"
		else:
			option.visible = false


func _on_buy_pressed(index: int) -> void:
	if index >= current_offers.size():
		return

	var offer := current_offers[index]
	var price: int = offer["price"]
	var rarity: String = offer["rarity"]
	var book_data: Dictionary = offer["book_data"]

	if GameManager.spend_currency(price):
		# Add book to bookshelf with its data
		bookshelf.collect_next_book_with_data(book_data, rarity)
		book_purchased.emit(rarity, book_data)
		close()


func _on_close_pressed() -> void:
	close()
