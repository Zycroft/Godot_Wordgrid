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

# Drag and drop state
var dragging: bool = false
var drag_index: int = -1
var drag_offset: Vector2 = Vector2.ZERO
var drag_preview: ColorRect = null


func _ready() -> void:
	collected_books.resize(TOTAL_BOOKS)
	collected_books.fill(false)
	book_data_list.resize(TOTAL_BOOKS)
	for i in range(TOTAL_BOOKS):
		book_data_list[i] = {}
	_update_display()
	_setup_book_interactions()


func collect_book(index: int) -> bool:
	if index < 0 or index >= TOTAL_BOOKS:
		return false
	if collected_books[index]:
		return false

	collected_books[index] = true
	@warning_ignore("integer_division")
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
			# Store the color index so it follows the book when swapped
			full_data["color_index"] = i % BOOK_COLORS.size()
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

			if collected_books[global_idx]:
				# Use stored color index from book data, or fall back to slot position
				var data := book_data_list[global_idx]
				var color_idx: int = data.get("color_index", global_idx) % BOOK_COLORS.size()
				var base_color := BOOK_COLORS[color_idx]
				book.color = Color(base_color.r, base_color.g, base_color.b, COLLECTED_ALPHA)
				# Update tooltip with book name
				if data.has("name"):
					book.tooltip_text = data["name"]
			else:
				# Uncollected: use slot position color but transparent
				var base_color := BOOK_COLORS[global_idx % BOOK_COLORS.size()]
				book.color = Color(base_color.r, base_color.g, base_color.b, 0.0)
				book.tooltip_text = ""


func _setup_book_interactions() -> void:
	# Connect mouse signals for each book for tooltips and drag-drop
	for shelf_idx in range(NUM_SHELVES):
		var container := books_containers[shelf_idx]
		var books := container.get_children()

		for book_idx in range(books.size()):
			var book := books[book_idx] as ColorRect
			var global_idx := shelf_idx * BOOKS_PER_SHELF + book_idx
			book.mouse_filter = Control.MOUSE_FILTER_STOP
			book.gui_input.connect(_on_book_gui_input.bind(global_idx))


func _on_book_gui_input(event: InputEvent, book_index: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging if book is collected
				if collected_books[book_index]:
					_start_drag(book_index, event.global_position)
			else:
				# End dragging
				if dragging:
					_end_drag(event.global_position)


func _input(event: InputEvent) -> void:
	if dragging:
		if event is InputEventMouseMotion:
			_update_drag(event.global_position)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_drag(event.global_position)


func _start_drag(index: int, mouse_pos: Vector2) -> void:
	dragging = true
	drag_index = index

	# Get the book's visual
	var book := _get_book_rect(index)
	if not book:
		return

	drag_offset = book.global_position - mouse_pos

	# Create a preview that follows the mouse
	drag_preview = ColorRect.new()
	drag_preview.custom_minimum_size = book.custom_minimum_size
	drag_preview.size = book.size
	drag_preview.color = book.color
	drag_preview.color.a = 0.7
	drag_preview.z_index = 100
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_preview)
	drag_preview.global_position = mouse_pos + drag_offset

	# Make original book semi-transparent
	book.color.a = 0.3


func _update_drag(mouse_pos: Vector2) -> void:
	if drag_preview:
		drag_preview.global_position = mouse_pos + drag_offset


func _end_drag(mouse_pos: Vector2) -> void:
	if not dragging:
		return

	# Find which slot we're dropping onto
	var target_index := _get_slot_at_position(mouse_pos)

	if target_index >= 0 and target_index != drag_index:
		# Swap the books
		_swap_books(drag_index, target_index)

	# Clean up
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

	dragging = false
	drag_index = -1
	_update_display()


func _get_book_rect(index: int) -> ColorRect:
	@warning_ignore("integer_division")
	var shelf_idx := index / BOOKS_PER_SHELF
	var book_idx := index % BOOKS_PER_SHELF

	if shelf_idx < books_containers.size():
		var books := books_containers[shelf_idx].get_children()
		if book_idx < books.size():
			return books[book_idx] as ColorRect
	return null


func _get_slot_at_position(global_pos: Vector2) -> int:
	for shelf_idx in range(NUM_SHELVES):
		var container := books_containers[shelf_idx]
		var books := container.get_children()

		for book_idx in range(books.size()):
			var book := books[book_idx] as ColorRect
			# Use the actual rendered size, falling back to minimum size
			var book_size := book.size if book.size.x > 0 else book.custom_minimum_size
			var rect := Rect2(book.global_position, book_size)
			if rect.has_point(global_pos):
				return shelf_idx * BOOKS_PER_SHELF + book_idx
	return -1


func _swap_books(from_index: int, to_index: int) -> void:
	# Swap collected state
	var temp_collected := collected_books[from_index]
	collected_books[from_index] = collected_books[to_index]
	collected_books[to_index] = temp_collected

	# Swap book data
	var temp_data := book_data_list[from_index]
	book_data_list[from_index] = book_data_list[to_index]
	book_data_list[to_index] = temp_data
