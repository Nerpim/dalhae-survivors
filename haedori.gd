extends Node2D

# 진화 레벨
@export var level: int = 1

# 공격 설정
@export var bubble_scene: PackedScene
@export var follow_speed: float = 200.0
@export var follow_distance: float = 60.0
@export var attack_range: float = 250.0

# 돌진 공격 설정
@export var dash_speed: float = 600.0
@export var dash_cooldown: float = 1.2  # Lv2용 쿨다운 (기존)

# Lv3 3연타 설정
@export var combo_retreat_distance: float = 30.0
@export var combo_interval: float = 0.15

# Lv4 헐크 돌진 설정
@export var hulk_dash_speed: float = 900.0
@export var hulk_dash_distance: float = 800.0
@export var hulk_cooldown: float = 5.0  # ★ 추가: Lv4 전용 쿨다운

# 해돌이끼리 밀어내기
@export var separation_distance: float = 40.0
@export var separation_strength: float = 80.0

@onready var visual: ColorRect = $Visual
@onready var attack_timer: Timer = $AttackTimer

var player: Node2D = null

# 상태
enum State { FOLLOWING, ATTACKING, RETURNING, COOLDOWN, COMBO_ATTACKING, HULK_DASHING, HULK_RETURNING }
var current_state: State = State.FOLLOWING
var attack_target: Node2D = null
var dash_damage_dealt: bool = false

# Lv3 콤보
var combo_hits_left: int = 0

# Lv4 헐크
var hulk_direction: Vector2 = Vector2.RIGHT
var hulk_start_position: Vector2
var hulk_damaged_enemies: Array = []


func _ready() -> void:
	add_to_group("haedori")
	player = get_tree().get_first_node_in_group("player")
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	apply_level_visual()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	match level:
		1:
			behavior_egg(delta)
		2:
			behavior_baby(delta)
		3:
			behavior_teen(delta)
		4:
			behavior_hulk(delta)
		_:
			behavior_egg(delta)
	
	apply_separation(delta)


# ============================================================
# 해돌이끼리 겹치지 않게 밀어내기
# ============================================================
func apply_separation(delta: float) -> void:
	var all_haedoris = get_tree().get_nodes_in_group("haedori")
	
	for other in all_haedoris:
		if other == self:
			continue
		if not is_instance_valid(other):
			continue
		
		var dist = global_position.distance_to(other.global_position)
		if dist < separation_distance and dist > 0:
			var push_direction = (global_position - other.global_position).normalized()
			var push_strength = (separation_distance - dist) / separation_distance
			global_position += push_direction * separation_strength * push_strength * delta


# ============================================================
# Lv1 알: 졸졸 따라다니며 거품 발사
# ============================================================
func behavior_egg(delta: float) -> void:
	var target = player.global_position + Vector2(0, follow_distance)
	global_position = global_position.lerp(target, follow_speed * delta / 100)


# ============================================================
# Lv2 아기: 툭! 한 대 치고 쪼르르 복귀
# ============================================================
func behavior_baby(delta: float) -> void:
	match current_state:
		State.FOLLOWING:
			follow_player(delta)
			var nearest = find_nearest_enemy_in_range()
			if nearest:
				attack_target = nearest
				dash_damage_dealt = false
				current_state = State.ATTACKING
		
		State.ATTACKING:
			if attack_target == null or not is_instance_valid(attack_target):
				current_state = State.RETURNING
				return
			
			var direction = (attack_target.global_position - global_position).normalized()
			global_position += direction * dash_speed * delta
			
			if global_position.distance_to(attack_target.global_position) < 25:
				if not dash_damage_dealt and attack_target.has_method("take_damage"):
					attack_target.take_damage(get_single_hit_damage())
					dash_damage_dealt = true
					hit_effect()
				current_state = State.RETURNING
		
		State.RETURNING:
			return_to_player(delta)
		
		State.COOLDOWN:
			follow_player(delta)


# ============================================================
# Lv3 청소년: 몽둥이 3연타
# ============================================================
func behavior_teen(delta: float) -> void:
	match current_state:
		State.FOLLOWING:
			follow_player(delta)
			var nearest = find_nearest_enemy_in_range()
			if nearest:
				attack_target = nearest
				combo_hits_left = 3
				current_state = State.COMBO_ATTACKING
				execute_combo_hit()
		
		State.COMBO_ATTACKING:
			if attack_target == null or not is_instance_valid(attack_target):
				var next_target = find_nearest_enemy_in_range()
				if next_target and combo_hits_left > 0:
					attack_target = next_target
					execute_combo_hit()
				else:
					current_state = State.RETURNING
				return
			
			var direction = (attack_target.global_position - global_position).normalized()
			global_position += direction * dash_speed * delta
		
		State.RETURNING:
			return_to_player(delta)
		
		State.COOLDOWN:
			follow_player(delta)


func execute_combo_hit() -> void:
	await get_tree().create_timer(combo_interval).timeout
	
	if current_state != State.COMBO_ATTACKING:
		return
	if attack_target == null or not is_instance_valid(attack_target):
		return
	
	if global_position.distance_to(attack_target.global_position) < 30:
		if attack_target.has_method("take_damage"):
			attack_target.take_damage(get_combo_damage())
			hit_effect()
		combo_hits_left -= 1
		
		var retreat_dir = (global_position - attack_target.global_position).normalized()
		global_position += retreat_dir * combo_retreat_distance
		
		if combo_hits_left > 0:
			if is_instance_valid(attack_target):
				execute_combo_hit()
			else:
				var next_target = find_nearest_enemy_in_range()
				if next_target:
					attack_target = next_target
					execute_combo_hit()
				else:
					current_state = State.RETURNING
		else:
			current_state = State.RETURNING
	else:
		execute_combo_hit()


# ============================================================
# Lv4 몸짱: 헐크 돌진! 일직선 관통
# ============================================================
func behavior_hulk(delta: float) -> void:
	match current_state:
		State.FOLLOWING:
			follow_player(delta)
			var nearest = find_nearest_enemy_in_range()
			if nearest:
				hulk_direction = (nearest.global_position - global_position).normalized()
				hulk_start_position = global_position
				hulk_damaged_enemies.clear()
				current_state = State.HULK_DASHING
		
		State.HULK_DASHING:
			global_position += hulk_direction * hulk_dash_speed * delta
			check_hulk_collisions()
			
			if global_position.distance_to(hulk_start_position) >= hulk_dash_distance:
				current_state = State.HULK_RETURNING
				hulk_damaged_enemies.clear()
		
		State.HULK_RETURNING:
			var return_target = player.global_position + Vector2(0, follow_distance)
			var return_direction = (return_target - global_position).normalized()
			global_position += return_direction * hulk_dash_speed * delta
			
			check_hulk_collisions()
			
			if global_position.distance_to(return_target) < 50:
				current_state = State.COOLDOWN
				await get_tree().create_timer(hulk_cooldown).timeout  # ★ 변경: hulk_cooldown 사용
				current_state = State.FOLLOWING
		
		State.COOLDOWN:
			follow_player(delta)


func check_hulk_collisions() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy in hulk_damaged_enemies:
			continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist < 35:
			if enemy.has_method("take_damage"):
				enemy.take_damage(get_hulk_damage())
				hulk_damaged_enemies.append(enemy)
				hit_effect()


# ============================================================
# 공통 이동
# ============================================================
func follow_player(delta: float) -> void:
	var target_pos = player.global_position + Vector2(0, follow_distance)
	global_position = global_position.lerp(target_pos, follow_speed * delta / 100)


func return_to_player(delta: float) -> void:
	var return_target = player.global_position + Vector2(0, follow_distance)
	var direction = (return_target - global_position).normalized()
	global_position += direction * dash_speed * delta
	
	if global_position.distance_to(return_target) < 30:
		current_state = State.COOLDOWN
		await get_tree().create_timer(dash_cooldown).timeout
		current_state = State.FOLLOWING


# ============================================================
# 데미지 값
# ============================================================
func get_single_hit_damage() -> int:
	match level:
		2: return 20
		_: return 10


func get_combo_damage() -> int:
	match level:
		3: return 18
		_: return 10


func get_hulk_damage() -> int:
	return 40


func hit_effect() -> void:
	var tween = create_tween()
	tween.tween_property(visual, "modulate", Color(2, 2, 2), 0.05)
	tween.tween_property(visual, "modulate", Color(1, 1, 1), 0.1)


# ============================================================
# Lv1 기본 공격 (거품)
# ============================================================
func _on_attack_timer_timeout() -> void:
	match level:
		1:
			attack_basic()


func attack_basic() -> void:
	if bubble_scene == null:
		return
	var nearest = find_nearest_enemy_in_range()
	if nearest == null:
		return
	var bubble = bubble_scene.instantiate()
	get_tree().current_scene.add_child(bubble)
	bubble.global_position = global_position
	bubble.direction = (nearest.global_position - global_position).normalized()


func find_nearest_enemy_in_range() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_distance: float = attack_range
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			nearest = enemy
	return nearest


# ============================================================
# 외형 & 진화
# ============================================================
func apply_level_visual() -> void:
	match level:
		1:
			visual.size = Vector2(16, 20)
			visual.position = Vector2(-8, -10)
			visual.color = Color("FFF8E1")
		2:
			visual.size = Vector2(20, 20)
			visual.position = Vector2(-10, -10)
			visual.color = Color("FFCDD2")
		3:
			visual.size = Vector2(26, 26)
			visual.position = Vector2(-13, -13)
			visual.color = Color("F8BBD0")
		4:
			visual.size = Vector2(36, 36)
			visual.position = Vector2(-18, -18)
			visual.color = Color("EF5350")


func evolve() -> void:
	level += 1
	if level > 4:
		level = 4
	apply_level_visual()
	current_state = State.FOLLOWING
	attack_target = null
	combo_hits_left = 0
	hulk_damaged_enemies.clear()
