extends Control

signal book_collected(shelf_index: int, book_index: int)

const BOOKS_PER_SHELF: int = 3
const NUM_SHELVES: int = 3
const TOTAL_BOOKS: int = BOOKS_PER_SHELF * NUM_SHELVES

# Book colors - always visible
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

# Rarity colors for book borders/effects
const RARITY_COLORS: Dictionary = {
	"common": Color(0.7, 0.7, 0.7, 1),
	"uncommon": Color(0.2, 0.8, 0.2, 1),
	"rare": Color(0.2, 0.4, 1.0, 1),
	"epic": Color(0.8, 0.2, 0.8, 1)
}

# Collected books are visible, uncollected are hidden
const COLLECTED_ALPHA: float = 1.0

@onready var books_containers: Array[HBoxContainer] = [
	%Books1,
	%Books2,
	%Books3,
]

@onready var shelf1: VBoxContainer = $Shelf1
@onready var shelf2: VBoxContainer = $Shelf2
@onready var shelf3: VBoxContainer = $Shelf3

var collected_books: Array[bool] = []
var book_data_list: Array[Dictionary] = []  # Stores book data for each slot


func _ready() -> void:
	collected_books.resize(TOTAL_BOOKS)
	collected_books.fill(false)
	book_data_list.resize(TOTAL_BOOKS)
	for i in range(TOTAL_BOOKS):
		book_data_list[i] = {}
	_update_display()
	_setup_book_tooltips()


func collect_book(index: int) -> bool:
	if index < 0 or index >= TOTAL_BOOKS:
		return false
	if collected_books[index]:
		return false

	collected_books[index] = true
	var shelf_index := index / BOOKS_PER_SHELF
	var book_index := index % BOOKS_PER_SHELF
	book_collected.emit(shelf_index, book_index)
	_update_display()
	return true


func collect_next_book() -> int:
	# Fill row by row (left to right, top to bottom)
	for i in range(TOTAL_BOOKS):
		if not collected_books[i]:
			collect_book(i)
			return i
	return -1


func collect_next_book_with_data(data: Dictionary, rarity: String) -> int:
	# Fill row by row (left to right, top to bottom)
	for i in range(TOTAL_BOOKS):
		if not collected_books[i]:
			var full_data := data.duplicate()
			full_data["rarity"] = rarity
			book_data_list[i] = full_data
			collect_book(i)
			return i
	return -1


func get_book_data(index: int) -> Dictionary:
	if index < 0 or index >= TOTAL_BOOKS:
		return {}
	return book_data_list[index]


func get_collected_count() -> int:
	var count := 0
	for collected in collected_books:
		if collected:
			count += 1
	return count


func is_shelf_complete(shelf_index: int) -> bool:
	if shelf_index < 0 or shelf_index >= NUM_SHELVES:
		return false

	var start := shelf_index * BOOKS_PER_SHELF
	for i in range(BOOKS_PER_SHELF):
		if not collected_books[start + i]:
			return false
	return true


func is_all_complete() -> bool:
	for collected in collected_books:
		if not collected:
			return false
	return true


func reset() -> void:
	collected_books.fill(false)
	for i in range(TOTAL_BOOKS):
		book_data_list[i] = {}
	_update_display()


func _update_display() -> void:
	for shelf_idx in range(NUM_SHELVES):
		var container := books_containers[shelf_idx]
		var books := container.get_children()

		for book_idx in range(books.size()):
			var book := books[book_idx] as ColorRect
			var global_idx := shelf_idx * BOOKS_PER_SHELF + book_idx

			# Show collected books, make uncollected ones transparent (but keep space)
			var base_color := BOOK_COLORS[global_idx % BOOK_COLORS.size()]
			if collected_books[global_idx]:
				book.color = Color(base_color.r, base_color.g, base_color.b, COLLECTED_ALPHA)
				# Update tooltip with book name
				var data := book_data_list[global_idx]
				if data.has("name"):
					book.tooltip_text = data["name"]
			else:
				book.color = Color(base_color.r, base_color.g, base_color.b, 0.0)
				book.tooltip_text = ""


func _setup_book_tooltips() -> void:
	# Connect mouse signals for each book to show tooltips
	for shelf_idx in range(NUM_SHELVES):
		var container := books_containers[shelf_idx]
		var books := container.get_children()

		for book_idx in range(books.size()):
			var book := books[book_idx] as ColorRect
			book.mouse_filter = Control.MOUSE_FILTER_PASS
