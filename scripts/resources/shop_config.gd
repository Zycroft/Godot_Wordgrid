class_name ShopConfig
extends Resource

## Rarity configuration for the book shop

@export var common_price: int = 5
@export var common_weight: int = 50
@export var common_color: Color = Color(0.7, 0.7, 0.7)

@export var uncommon_price: int = 10
@export var uncommon_weight: int = 30
@export var uncommon_color: Color = Color(0.3, 0.8, 0.3)

@export var rare_price: int = 20
@export var rare_weight: int = 15
@export var rare_color: Color = Color(0.3, 0.5, 0.9)

@export var epic_price: int = 40
@export var epic_weight: int = 5
@export var epic_color: Color = Color(0.7, 0.3, 0.9)


func get_price(rarity: String) -> int:
	match rarity:
		"common": return common_price
		"uncommon": return uncommon_price
		"rare": return rare_price
		"epic": return epic_price
	return 0


func get_weight(rarity: String) -> int:
	match rarity:
		"common": return common_weight
		"uncommon": return uncommon_weight
		"rare": return rare_weight
		"epic": return epic_weight
	return 0


func get_color(rarity: String) -> Color:
	match rarity:
		"common": return common_color
		"uncommon": return uncommon_color
		"rare": return rare_color
		"epic": return epic_color
	return Color.WHITE


func get_total_weight() -> int:
	return common_weight + uncommon_weight + rare_weight + epic_weight


func roll_rarity() -> String:
	var total := get_total_weight()
	var roll := randi() % total

	if roll < common_weight:
		return "common"
	roll -= common_weight

	if roll < uncommon_weight:
		return "uncommon"
	roll -= uncommon_weight

	if roll < rare_weight:
		return "rare"

	return "epic"
