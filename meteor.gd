extends Node2D

@export var damage: int = 15
@export var warning_duration: float = 0.5  # 경고 표시 시간
@export var fall_duration: float = 0.2  # 낙하 시간
@export var fall_height: float = 400.0  # 하늘에서 얼마나 높은 곳에서 떨어지는지

@onready var warning: ColorRect = $Warning
@onready var meteor_body: ColorRect = $MeteorBody
@onready var explosion_area: Area2D = $ExplosionArea

func _ready() -> void:
	# 시작: 경고만 보이고 메테오는 숨김
	warning.visible = true
	meteor_body.visible = false
	
	# 메테오 애니메이션 시작
	start_meteor_sequence()

func start_meteor_sequence() -> void:
	# 1단계: 경고 표시 유지
	await get_tree().create_timer(warning_duration).timeout
	
	# 2단계: 메테오 낙하
	warning.visible = false
	meteor_body.visible = true
	meteor_body.position.y = -fall_height  # 화면 위쪽에서 시작
	meteor_body.position.x = -15  # 중심 유지
	
	var tween = create_tween()
	tween.tween_property(meteor_body, "position:y", -15, fall_duration)
	await tween.finished
	
	# 3단계: 폭발! 범위 내 적에게 데미지
	explode()
	
	# 4단계: 잠시 후 제거
	await get_tree().create_timer(0.1).timeout
	queue_free()

func explode() -> void:
	# 폭발 시각 효과: 메테오 본체가 커졌다가 사라짐
	var tween = create_tween()
	tween.set_parallel(true)  # 동시에 여러 속성 변경
	tween.tween_property(meteor_body, "scale", Vector2(2.5, 2.5), 0.1)
	tween.tween_property(meteor_body, "modulate:a", 0.0, 0.1)
	
	# 범위 내 적 모두에게 데미지
	var bodies = explosion_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)
