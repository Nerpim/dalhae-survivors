class_name EnemyData
extends Resource

# 기본 스탯
@export var enemy_type: String = "kkomak"  # 내부 식별 이름 (GameManager용)
@export var display_name: String = "꼬막"    # 표시 이름

# 능력치
@export var max_hp: int = 20
@export var speed: float = 80.0
@export var damage: int = 5

# 보상
@export var exp_value: int = 1
@export var exp_orbs_on_death: int = 1  # 죽을 때 떨어뜨리는 경험치 오브 개수

# 비주얼
@export var body_color: Color = Color(0.6, 0.3, 0.1)  # 기본 꼬막 갈색
@export var body_size: Vector2 = Vector2(32, 32)
