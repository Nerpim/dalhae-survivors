extends Control

@onready var retry_button: Button = $RetryButton
@onready var main_menu_button: Button = $MainMenuButton
@onready var stats_label: Label = $StatsLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	hide()

func show_clear_screen() -> void:
	update_stats()
	get_tree().paused = true
	show()

func update_stats() -> void:
	var run = GameManager.current_run
	var time_text = format_time(run.survived_time)
	var kills = run.kills
	var level = run.player_level
	
	stats_label.text = "생존 시간: %s\n처치 수: %d\n도달 레벨: Lv.%d" % [time_text, kills, level]

func format_time(seconds: float) -> String:
	var total = int(seconds)
	var minutes = total / 60
	var secs = total % 60
	return "%d분 %d초" % [minutes, secs]

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_screen.tscn")
