extends CharacterBody2D

@export var speed: float = 250.0
@export var max_hp: int = 15
@export var damage: int = 10
@export var exp_orb_scene: PackedScene
@export var exp_value: int = 2

@export var formation_correction_strength: float = 3.0

var current_hp: int
var direction: Vector2 = Vector2.RIGHT
var squad: Node2D = null
var formation_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_hp = max_hp

func _physics_process(delta: float) -> void:
	# 기본 전진 속도
	velocity = direction * speed
	
	# 대열 복귀 힘 (속도 제한 포함)
	if squad != null and is_instance_valid(squad):
		var ideal_position = squad.global_position + formation_offset
		var offset = ideal_position - global_position
		
		# 복귀 속도 계산
		var correction_velocity = offset * formation_correction_strength
		
		# 속도 제한: 기본 전진 속도의 1.3배까지만 (150% 상한)
		var max_total_speed = speed * 1.3
		var total_velocity = velocity + correction_velocity
		
		if total_velocity.length() > max_total_speed:
			total_velocity = total_velocity.normalized() * max_total_speed
		
		velocity = total_velocity
	
	move_and_slide()

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		drop_exp()
		queue_free()

func drop_exp() -> void:
	if exp_orb_scene == null:
		return
	var orb = exp_orb_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", orb)
	orb.global_position = global_position
	orb.value = exp_value
