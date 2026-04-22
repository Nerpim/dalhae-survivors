extends Node2D

@export var orbit_radius: float = 80.0  # 궤도 반지름
@export var rotation_speed: float = 3.0  # 회전 속도 (라디안/초)
@export var pebble_scene: PackedScene
@export var starting_pebble_count: int = 1  # 시작 개수

var pebbles: Array = []

func _ready() -> void:
	# 초기 조약돌 생성
	for i in starting_pebble_count:
		add_pebble()

func _process(delta: float) -> void:
	# 매 프레임 회전
	rotation += rotation_speed * delta

func add_pebble() -> void:
	if pebble_scene == null:
		return
	
	var pebble = pebble_scene.instantiate()
	add_child(pebble)
	pebbles.append(pebble)
	
	# 모든 조약돌을 원 궤도 위에 균등하게 재배치
	reposition_pebbles()

func reposition_pebbles() -> void:
	var count = pebbles.size()
	for i in count:
		var angle = (TAU / count) * i  # 각 조약돌의 각도
		var pos = Vector2(cos(angle), sin(angle)) * orbit_radius
		pebbles[i].position = pos

# 나중에 레벨업에서 호출할 함수
func upgrade() -> void:
	add_pebble()
