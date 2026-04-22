extends Control

@onready var retry_button: Button = $RetryButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	retry_button.pressed.connect(_on_retry_pressed)
	hide()

func show_game_over() -> void:
	get_tree().paused = true
	show()

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
