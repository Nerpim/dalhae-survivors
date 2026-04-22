extends Node

@export var squad_scene: PackedScene
@export var spawn_distance: float = 800.0

@onready var timer: Timer = $Timer

var is_active: bool = false

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer.stop()

func _on_timer_timeout() -> void:
	if is_active:
		spawn_squad()

func spawn_squad() -> void:
	if squad_scene == null:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_distance
	
	var to_player = (player.global_position - spawn_pos).normalized()
	var move_direction = to_player
	
	var squad = squad_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", squad)
	squad.call_deferred("setup_squad", spawn_pos, move_direction)

func activate() -> void:
	is_active = true
	timer.start()
	print("닌자 대열 출동!")

func deactivate() -> void:
	is_active = false
	timer.stop()
