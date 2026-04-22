extends Area2D

@export var value: int = 1
@export var pickup_range: float = 80.0  # 자석 효과 시작 거리
@export var move_speed: float = 400.0

var player: Node2D = null
var is_attracted: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# 자석 효과
	if distance < pickup_range:
		is_attracted = true
	
	if is_attracted:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * move_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("gain_exp"):
			body.gain_exp(value)
		queue_free()
