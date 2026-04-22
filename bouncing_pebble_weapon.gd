extends Node2D

@export var bouncing_pebble_scene: PackedScene
@export var bounces: int = 2  # 강화 시 증가

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	fire()

func fire() -> void:
	# 가장 가까운 적 찾기
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	
	var nearest: Node2D = null
	var min_distance: float = INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest = enemy
	
	if nearest == null:
		return
	
	# 튕기는 조약돌 생성
	var pebble = bouncing_pebble_scene.instantiate()
	get_tree().current_scene.add_child(pebble)
	pebble.global_position = global_position
	pebble.direction = (nearest.global_position - global_position).normalized()
	pebble.max_bounces = bounces  # 현재 튕김 횟수 전달

# 강화 함수 (나중에 레벨업에서 호출)
func upgrade() -> void:
	bounces += 1
