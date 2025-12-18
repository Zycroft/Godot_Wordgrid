class_name ScoringConfig
extends Resource

# Points configuration
@export var points_incorrect_letter: int = 0
@export var points_wrong_position_letter: int = 5
@export var points_correct_letter: int = 10
@export var points_word_solved_bonus: int = 20
@export var points_perfect_guess_bonus: int = 50
@export var points_early_solve_multiplier: float = 1.5

# Currency configuration
@export var currency_incorrect_letter: int = 0
@export var currency_wrong_position_letter: int = 1
@export var currency_correct_letter: int = 2
@export var currency_word_solved_bonus: int = 5
@export var currency_perfect_guess_bonus: int = 10
@export var currency_early_solve_multiplier: float = 1.25
