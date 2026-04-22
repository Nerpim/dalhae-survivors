extends Control

@onready var resume_button: Button = $ResumeButton
@onready var restart_button: Button = $RestartButton
@onready var main_menu_button: Button = $MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	hide()

func show_pause() -> void:
	# 게임 오버/클리어 화면이 떠있으면 일시정지 불가
	var game_over = get_tree().get_first_node_in_group("game_over_screen")
	var clear = get_tree().get_first_node_in_group("stage_clear_screen")
	if (game_over and game_over.visible) or (clear and clear.visible):
		return
	
	get_tree().paused = true
	show()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_screen.tscn")
