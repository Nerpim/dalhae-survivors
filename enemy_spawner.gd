extends Node

@export var enemy_scenes: Array[PackedScene] = []
@export var enemy_weights: Array[int] = []
@export var spawn_distance: float = 600.0
@export var max_enemies: int = 100

# 오라 확률 (StageManager가 변경)
var blue_aura_chance: float = 0.03  # 3%
var gold_aura_chance: float = 0.0   # 0%

@onready var timer: Timer = $Timer

var player: Node2D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy() -> void:
	if player == null:
		return
	if enemy_scenes.is_empty():
		return
	
	var current_count = get_tree().get_nodes_in_group("enemies").size()
	if current_count >= max_enemies:
		return
	
	var selected_scene = pick_weighted_scene()
	if selected_scene == null:
		return
	
	var enemy = selected_scene.instantiate()
	
	# 오라 결정 (스크립트에 aura_type 속성 있으면)
	var roll = randf()
	if roll < gold_aura_chance:
		if "aura_type" in enemy:
			enemy.aura_type = "gold"
	elif roll < gold_aura_chance + blue_aura_chance:
		if "aura_type" in enemy:
			enemy.aura_type = "blue"
	
	get_tree().current_scene.add_child(enemy)
	
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * spawn_distance
	enemy.global_position = player.global_position + offset

func pick_weighted_scene() -> PackedScene:
	if enemy_weights.size() != enemy_scenes.size():
		return enemy_scenes.pick_random()
	
	var total_weight = 0
	for w in enemy_weights:
		total_weight += w
	
	if total_weight <= 0:
		return enemy_scenes.pick_random()
	
	var roll = randi() % total_weight
	var accumulated = 0
	for i in enemy_scenes.size():
		accumulated += enemy_weights[i]
		if roll < accumulated:
			return enemy_scenes[i]
	
	return enemy_scenes[0]

func set_enemy_pool(scenes: Array[PackedScene], weights: Array[int]) -> void:
	enemy_scenes = scenes
	enemy_weights = weights
	print("적 풀 업데이트: ", enemy_scenes.size(), "종")

# StageManager가 호출해서 오라 확률 변경
func set_aura_chances(blue: float, gold: float) -> void:
	blue_aura_chance = blue
	gold_aura_chance = gold
	# print("오라 확률 변경: 파란 %.1f%%, 금색 %.1f%%" % [blue * 100, gold * 100])
