extends CharacterBody2D

@export var speed_phase1: float = 40.0
@export var speed_phase2: float = 55.0
@export var speed_phase3: float = 75.0

@export var max_hp: int = 1500
@export var damage: int = 30

@export var exp_orb_scene: PackedScene
@export var exp_value: int = 10
@export var exp_orbs_on_death: int = 30

# 소환할 적 씬들 (인스펙터에서 설정)
@export var kkomak_scene: PackedScene
@export var shield_kkomak_scene: PackedScene
@export var warrior_kkomak_scene: PackedScene
@export var fat_kkomak_scene: PackedScene

var current_hp: int
var current_speed: float
var player: Node2D = null

# 페이즈
enum Phase { PHASE_1, PHASE_2, PHASE_3 }
var current_phase: Phase = Phase.PHASE_1

# 소환 타이머
var summon_timer: float = 0.0
var summon_interval: float = 5.0
var minions_per_summon: int = 4

@onready var body: ColorRect = $Body
@onready var crown: ColorRect = $Crown
@onready var jewel: ColorRect = $Jewel

signal hp_changed(current: int, maximum: int)
signal boss_defeated

func _ready() -> void:
	current_hp = max_hp
	current_speed = speed_phase1
	player = get_tree().get_first_node_in_group("player")
	
	# 등장 연출: 크게 시작해서 원래 크기로
	scale = Vector2(0.1, 0.1)
	modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	hp_changed.emit(current_hp, max_hp)

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	# 플레이어 추적
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * current_speed
	move_and_slide()
	
	# 소환 타이머
	summon_timer += delta
	if summon_timer >= summon_interval:
		summon_timer = 0.0
		summon_minions()

func take_damage(amount: int) -> void:
	current_hp -= amount
	hp_changed.emit(current_hp, max_hp)
	
	# 피격 깜빡
	var tween = create_tween()
	tween.tween_property(body, "modulate", Color(2, 2, 2), 0.05)
	tween.tween_property(body, "modulate", Color(1, 1, 1), 0.1)
	
	# 페이즈 체크
	check_phase_transition()
	
	if current_hp <= 0:
		die()

func check_phase_transition() -> void:
	var hp_ratio = float(current_hp) / float(max_hp)
	
	if current_phase == Phase.PHASE_1 and hp_ratio <= 0.66:
		enter_phase_2()
	elif current_phase == Phase.PHASE_2 and hp_ratio <= 0.33:
		enter_phase_3()

func enter_phase_2() -> void:
	current_phase = Phase.PHASE_2
	current_speed = speed_phase2
	summon_interval = 4.0
	minions_per_summon = 5
	
	# 색 변화: 주황빛으로
	var tween = create_tween()
	tween.tween_property(body, "modulate", Color(1.3, 0.9, 0.7), 0.5)
	print("보스 페이즈 2!")

func enter_phase_3() -> void:
	current_phase = Phase.PHASE_3
	current_speed = speed_phase3
	summon_interval = 3.0
	minions_per_summon = 6
	
	# 색 변화: 붉은빛으로
	var tween = create_tween()
	tween.tween_property(body, "modulate", Color(1.5, 0.6, 0.6), 0.5)
	print("보스 페이즈 3! 광폭화!")

func summon_minions() -> void:
	# 페이즈별 소환 적 선택
	var minion_scenes: Array[PackedScene] = []
	
	match current_phase:
		Phase.PHASE_1:
			minion_scenes = [kkomak_scene]
		Phase.PHASE_2:
			minion_scenes = [kkomak_scene, shield_kkomak_scene]
		Phase.PHASE_3:
			minion_scenes = [warrior_kkomak_scene, fat_kkomak_scene]
	
	if minion_scenes.is_empty():
		return
	
	for i in minions_per_summon:
		var selected = minion_scenes.pick_random()
		if selected == null:
			continue
		
		var minion = selected.instantiate()
		get_tree().current_scene.call_deferred("add_child", minion)
		
		# 보스 주변 랜덤 위치
		var angle = randf() * TAU
		var offset = Vector2(cos(angle), sin(angle)) * randf_range(80, 120)
		minion.global_position = global_position + offset

func die() -> void:
	GameManager.on_enemy_killed("boss_kkomak")  # 추가
	GameManager.on_stage_cleared()              # 추가
	
	# 경험치 오브 쏟아붓기
	if exp_orb_scene:
		for i in exp_orbs_on_death:
			var orb = exp_orb_scene.instantiate()
			get_tree().current_scene.call_deferred("add_child", orb)
			orb.global_position = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
			orb.value = exp_value
	
	# 죽음 연출: 커지면서 사라짐
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.5, 2.5), 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	
	boss_defeated.emit()
	
	# StageManager에 알림
	var stage_manager = get_tree().get_first_node_in_group("stage_manager")
	if stage_manager and stage_manager.has_method("on_boss_defeated"):
		stage_manager.on_boss_defeated()
	
	queue_free()
