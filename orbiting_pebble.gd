extends Area2D

@export var damage: int = 8
@export var knockback_cooldown: float = 0.5  # 같은 적 연타 방지

var hit_enemies: Dictionary = {}  # 최근에 때린 적 기록

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	
	# 같은 적 너무 빨리 때리는 거 방지
	if hit_enemies.has(body):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# 0.5초 동안 이 적 기록
	hit_enemies[body] = true
	await get_tree().create_timer(knockback_cooldown).timeout
	hit_enemies.erase(body)
