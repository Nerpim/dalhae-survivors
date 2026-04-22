extends Node

@export var stage_duration: float = 1800.0  # 30분
@export var boss_warning_time: float = 5.0

@export var kkomak_scene: PackedScene
@export var shield_kkomak_scene: PackedScene
@export var warrior_kkomak_scene: PackedScene
@export var fat_kkomak_scene: PackedScene
@export var boss_scene: PackedScene

# 스폰 간격 설정 (난이도)
@export var spawn_interval_start: float = 1.5  # 시작 스폰 간격
@export var spawn_interval_min: float = 0.4    # 최소 스폰 간격 (캡)

var time_remaining: float
var stage_ended: bool = false
var boss_spawned: bool = false
var warning_emitted: bool = false

# 웨이브 진행 체크
var wave_1_done: bool = false  # 방패 꼬막 추가 (10%)
var wave_2_done: bool = false  # 꼬막 닌자 추가 (20%)
var wave_3_done: bool = false  # 꼬막 무사 추가 (30%)
var wave_4_done: bool = false  # 비만 꼬막 추가 (40%)
var wave_5_done: bool = false  # 풀 라인업 가중치 조정 (50%)

signal time_updated(time_left: float)
signal boss_warning
signal boss_spawn_time
signal stage_cleared

var enemy_spawner: Node = null
var ninja_spawner: Node = null

func _ready() -> void:
	BgmManager.play_game()
	GameManager.start_new_run()
	
	time_remaining = stage_duration
	enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	ninja_spawner = get_tree().get_first_node_in_group("ninja_spawner")
	time_updated.emit(time_remaining)
	start_wave_0()

func _process(delta: float) -> void:
	if stage_ended:
		return
	if get_tree().paused:
		return
	if boss_spawned:
		return
	
	GameManager.update_playtime(delta)
	
	time_remaining -= delta
	if time_remaining < 0:
		time_remaining = 0
	
	time_updated.emit(time_remaining)
	check_waves()
	update_difficulty()
	update_aura_chances()
	
	if time_remaining <= boss_warning_time and time_remaining > 0 and not warning_emitted:
		warning_emitted = true
		boss_warning.emit()
		print("보스 경고!")
	
	if time_remaining <= 0 and not boss_spawned:
		boss_spawned = true
		spawn_boss()

# === 웨이브 ===

# 웨이브 0 (0~10%): 기본 꼬막만
func start_wave_0() -> void:
	if enemy_spawner:
		var scenes: Array[PackedScene] = [kkomak_scene]
		var weights: Array[int] = [10]
		enemy_spawner.set_enemy_pool(scenes, weights)
	print("웨이브 0: 기본 꼬막만 등장")

# 웨이브 1 (10%~): + 방패 꼬막
func start_wave_1() -> void:
	if enemy_spawner:
		var scenes: Array[PackedScene] = [kkomak_scene, shield_kkomak_scene]
		var weights: Array[int] = [7, 3]
		enemy_spawner.set_enemy_pool(scenes, weights)
	print("웨이브 1: 방패 꼬막 등장!")

# 웨이브 2 (20%~): + 꼬막 닌자 (대열)
func start_wave_2() -> void:
	if enemy_spawner:
		var scenes: Array[PackedScene] = [kkomak_scene, shield_kkomak_scene]
		var weights: Array[int] = [6, 4]
		enemy_spawner.set_enemy_pool(scenes, weights)
	if ninja_spawner:
		ninja_spawner.activate()
	print("웨이브 2: 꼬막 닌자 출동!")

# 웨이브 3 (30%~): + 꼬막 무사
func start_wave_3() -> void:
	if enemy_spawner:
		var scenes: Array[PackedScene] = [kkomak_scene, shield_kkomak_scene, warrior_kkomak_scene]
		var weights: Array[int] = [5, 3, 2]
		enemy_spawner.set_enemy_pool(scenes, weights)
	print("웨이브 3: 꼬막 무사 등장!")

# 웨이브 4 (40%~): + 비만 꼬막 (풀 라인업)
func start_wave_4() -> void:
	if enemy_spawner:
		var scenes: Array[PackedScene] = [kkomak_scene, shield_kkomak_scene, warrior_kkomak_scene, fat_kkomak_scene]
		var weights: Array[int] = [4, 3, 2, 1]
		enemy_spawner.set_enemy_pool(scenes, weights)
	print("웨이브 4: 비만 꼬막 등장! 풀 라인업")

# 웨이브 5 (50%~): 풀 라인업 비중 조정 (강한 적 비중 증가)
func start_wave_5() -> void:
	if enemy_spawner:
		var scenes: Array[PackedScene] = [kkomak_scene, shield_kkomak_scene, warrior_kkomak_scene, fat_kkomak_scene]
		var weights: Array[int] = [3, 3, 3, 2]  # 모든 적 비슷한 비율
		enemy_spawner.set_enemy_pool(scenes, weights)
	print("웨이브 5: 강한 적 비중 증가!")

func check_waves() -> void:
	var progress = 1.0 - (time_remaining / stage_duration)
	
	if progress >= 0.10 and not wave_1_done:
		wave_1_done = true
		start_wave_1()
	
	if progress >= 0.20 and not wave_2_done:
		wave_2_done = true
		start_wave_2()
	
	if progress >= 0.30 and not wave_3_done:
		wave_3_done = true
		start_wave_3()
	
	if progress >= 0.40 and not wave_4_done:
		wave_4_done = true
		start_wave_4()
	
	if progress >= 0.50 and not wave_5_done:
		wave_5_done = true
		start_wave_5()

# === 오라 확률 업데이트 ===
func update_aura_chances() -> void:
	if enemy_spawner == null:
		return
	
	var progress = 1.0 - (time_remaining / stage_duration)
	progress = clamp(progress, 0.0, 1.0)
	
	# 오라 확률 (희귀한 이벤트 느낌)
	var blue = lerp(0.01, 0.02, progress)
	var gold = lerp(0.0, 0.02, progress)
	
	enemy_spawner.set_aura_chances(blue, gold)

# === 난이도 (스폰 간격) ===
func update_difficulty() -> void:
	if enemy_spawner == null:
		return
	
	var progress = 1.0 - (time_remaining / stage_duration)
	progress = clamp(progress, 0.0, 1.0)
	
	# 스폰 간격: 시작 → 최소까지 점진 감소 (캡 적용됨)
	var new_interval = lerp(spawn_interval_start, spawn_interval_min, progress)
	
	if enemy_spawner.has_node("Timer"):
		enemy_spawner.get_node("Timer").wait_time = new_interval

# === 보스 ===
func spawn_boss() -> void:
	if enemy_spawner and enemy_spawner.has_node("Timer"):
		enemy_spawner.get_node("Timer").stop()
	if ninja_spawner:
		ninja_spawner.deactivate()
	
	boss_spawn_time.emit()
	print("보스 등장!")
	
	if boss_scene == null:
		push_warning("Boss Scene이 설정되지 않음!")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	
	var boss = boss_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", boss)
	boss.global_position = player.global_position + Vector2(0, -300)

func on_boss_defeated() -> void:
	stage_ended = true
	stage_cleared.emit()
	print("스테이지 클리어!")
	
	# 스테이지 클리어 화면 표시
	var clear_screen = get_tree().get_first_node_in_group("stage_clear_screen")
	if clear_screen and clear_screen.has_method("show_clear_screen"):
		await get_tree().create_timer(1.0).timeout  # 1초 후 표시 (보상 먹을 시간)
		clear_screen.show_clear_screen()
