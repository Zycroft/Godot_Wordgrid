extends PanelContainer

@onready var round_label: Label = %RoundLabel
@onready var stage_label: Label = %StageLabel
@onready var stage_indicators: HBoxContainer = %StageIndicators
@onready var points_label: Label = %PointsLabel
@onready var target_label: Label = %TargetLabel
@onready var progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	GameManager.round_changed.connect(_on_round_changed)
	GameManager.stage_changed.connect(_on_stage_changed)
	GameManager.points_changed.connect(_on_points_changed)
	GameManager.round_points_changed.connect(_on_round_points_changed)

	_create_stage_indicators()
	_update_all()


func _create_stage_indicators() -> void:
	for child in stage_indicators.get_children():
		child.queue_free()

	for i in range(GameManager.STAGES_PER_ROUND):
		var indicator := ColorRect.new()
		indicator.custom_minimum_size = Vector2(40, 40)
		indicator.color = Color(0.3, 0.3, 0.3, 0.8)
		stage_indicators.add_child(indicator)

	_update_stage_indicators()


func _update_stage_indicators() -> void:
	var children := stage_indicators.get_children()
	for i in range(children.size()):
		var indicator := children[i] as ColorRect
		if i < GameManager.current_stage - 1:
			indicator.color = Color(0.2, 0.8, 0.2, 0.9)  # Completed - green
		elif i == GameManager.current_stage - 1:
			indicator.color = Color(0.9, 0.7, 0.1, 0.9)  # Current - yellow
		else:
			indicator.color = Color(0.3, 0.3, 0.3, 0.8)  # Upcoming - gray


func _update_all() -> void:
	_on_round_changed(GameManager.current_round)
	_on_stage_changed(GameManager.current_stage)
	_on_points_changed(GameManager.points)
	_on_round_points_changed(GameManager.round_points_needed)


func _on_round_changed(round_number: int) -> void:
	round_label.text = "Round: %d" % round_number
	_create_stage_indicators()


func _on_stage_changed(stage_number: int) -> void:
	stage_label.text = "Stage: %d / %d" % [stage_number, GameManager.STAGES_PER_ROUND]
	_update_stage_indicators()


func _on_points_changed(points: int) -> void:
	points_label.text = "Points: %d" % points
	progress_bar.value = GameManager.get_progress_percentage()


func _on_round_points_changed(round_points: int) -> void:
	target_label.text = "Target: %d" % round_points
	progress_bar.max_value = 100
	progress_bar.value = GameManager.get_progress_percentage()
