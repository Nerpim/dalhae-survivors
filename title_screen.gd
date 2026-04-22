extends Control

@onready var start_button: Button = $StartButton
@onready var quit_button: Button = $QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	# 메인 게임 씬으로 전환
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
