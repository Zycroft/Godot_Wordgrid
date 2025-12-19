extends Node
## Shared constants for the WordGrid game

# Book colors - used in bookshelf and shop
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
