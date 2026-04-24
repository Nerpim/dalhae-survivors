extends Area2D

@export var speed: float = 500.0
@export var damage: int = 15
@export var max_bounces: int = 2  # 최대 튕김 횟수
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var bounces_left: int = 2
var last_hit_enemy: Node = null  # 방금 맞춘 적 (같은 놈에게 바로 안 튕기게)

func _ready() -> void:
	bounces_left = max_bounces
	body_entered.connect(_on_body_entered)
	
	# 수명 제한
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	
	# 방금 맞춘 적이면 무시 (같은 적 연타 방지)
	if body == last_hit_enemy:
		return
	
	# 데미지 주기
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	last_hit_enemy = body
	
	# 튕김 처리
	if bounces_left > 0:
		bounces_left -= 1
		bounce_to_next_enemy(body)
	else:
		queue_free()

func bounce_to_next_enemy(current_enemy: Node2D) -> void:
	# 현재 적 제외하고 가장 가까운 적 찾기
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	var nearest: Node2D = null
	var min_distance: float = INF
	
	for enemy in enemies:
		if enemy == current_enemy:
			continue
		if not is_instance_valid(enemy):
			continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			nearest = enemy
	
	# 다음 적이 있으면 방향 바꿈, 없으면 그냥 사라짐
	if nearest:
		direction = (nearest.global_position - global_position).normalized()
	else:
		queue_free()
