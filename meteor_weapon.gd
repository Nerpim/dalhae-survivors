extends Node2D

@export var meteor_scene: PackedScene
@export var spawn_range: float = 300.0  # 플레이어 주변 몇 픽셀 안에 떨어질지
@export var meteors_per_strike: int = 1  # 한 번에 몇 개 떨어질지 (강화 시 증가)

@onready var timer: Timer = $Timer

var upgrade_level: int = 0

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	strike()

func strike() -> void:
	if meteor_scene == null:
		return
	
	for i in meteors_per_strike:
		var meteor = meteor_scene.instantiate()
		get_tree().current_scene.add_child(meteor)
		
		# 플레이어 주변 랜덤 위치
		var angle = randf() * TAU
		var distance = randf_range(50, spawn_range)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		meteor.global_position = global_position + offset

# 강화: 레벨에 따라 쿨다운/개수 번갈아 증가
func upgrade() -> void:
	upgrade_level += 1
	
	match upgrade_level:
		1:  # 첫 강화: 쿨다운 감소
			timer.wait_time = 2.0
		2:  # 둘째 강화: 개수 +1
			meteors_per_strike = 2
		3:  # 셋째 강화: 쿨다운 감소
			timer.wait_time = 1.5
		4:  # 넷째 강화: 개수 +1
			meteors_per_strike = 3
		5:  # 최종 강화: 쿨다운 최저
			timer.wait_time = 1.0
	
	print("메테오 강화 Lv%d: 쿨다운 %.1f초, 개수 %d" % [upgrade_level, timer.wait_time, meteors_per_strike])
