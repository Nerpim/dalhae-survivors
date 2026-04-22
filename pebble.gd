extends Area2D

@export var speed: float = 500.0
@export var damage: int = 10
@export var lifetime: float = 3.0  # 3초 후 자동 제거 (화면 밖으로 날아가면 낭비 방지)

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# 일정 시간 후 사라짐
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()  # 적에 맞으면 조약돌 소멸
