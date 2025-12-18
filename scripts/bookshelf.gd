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


func _ready() -> void:
	collected_books.resize(TOTAL_BOOKS)
	collected_books.fill(false)
	_update_display()


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
	for i in range(TOTAL_BOOKS):
		if not collected_books[i]:
			collect_book(i)
			return i
	return -1


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
	_update_display()


func _update_display() -> void:
	for shelf_idx in range(NUM_SHELVES):
		var container := books_containers[shelf_idx]
		var books := container.get_children()

		for book_idx in range(books.size()):
			var book := books[book_idx] as ColorRect
			var global_idx := shelf_idx * BOOKS_PER_SHELF + book_idx

			# Show collected books, hide uncollected ones
			if collected_books[global_idx]:
				var base_color := BOOK_COLORS[global_idx % BOOK_COLORS.size()]
				book.color = Color(base_color.r, base_color.g, base_color.b, COLLECTED_ALPHA)
				book.visible = true
			else:
				book.visible = false
