extends CharacterBody2D

@export var speed: float = 300.0
@export var max_hp: int = 100
@export var invincibility_time: float = 0.5

var current_hp: int
var is_invincible: bool = false

# 경험치/레벨
var level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 5

# 무기 보유/강화 레벨 (0 = 미보유, 1 이상 = 보유 + 레벨)
var weapon_levels: Dictionary = {
	"orbiting": 0,
	"meteor": 0,
	"bouncing": 0,
	"haedori": 0,
}

# 무기별 최대 강화 레벨
var max_weapon_levels: Dictionary = {
	"orbiting": 5,
	"meteor": 5,
	"bouncing": 5,
	"haedori": 999,
}

# 무기 정보 (UI에 표시할 이름/설명)
var weapon_info: Dictionary = {
	"orbiting": {
		"name": "공전 조약돌",
		"description_new": "달해 주위를 도는 조약돌",
		"description_upgrade": "회전하는 조약돌 개수 +1"
	},
	"meteor": {
		"name": "메테오 조약돌",
		"description_new": "하늘에서 조약돌이 떨어짐",
		"description_upgrade": "더 빠르고 많이 떨어짐"
	},
	"bouncing": {
		"name": "튕기는 조약돌",
		"description_new": "적을 맞고 다른 적으로 튕김",
		"description_upgrade": "튕기는 횟수 +1"
	},
	"haedori": {
		"name": "해돌이",
		"description_new": "아기 해돌이가 따라다니며 공격",
		"description_upgrade": "해돌이가 성장함"
	},
}

signal hp_changed(current: int, maximum: int)
signal exp_changed(current: int, maximum: int)
signal level_up(new_level: int)
signal died

func _ready() -> void:
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	exp_changed.emit(current_exp, exp_to_next_level)
	
	# LevelUpScreen과 연결
	var level_up_screen = get_tree().get_first_node_in_group("level_up_screen")
	if level_up_screen:
		level_up_screen.weapon_selected.connect(_on_weapon_selected)

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	input_vector = input_vector.normalized()
	
	velocity = input_vector * speed
	move_and_slide()
	
	check_enemy_collision()

func check_enemy_collision() -> void:
	if is_invincible:
		return
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemies"):
			take_damage(10)
			break

func take_damage(amount: int) -> void:
	if is_invincible:
		return
	
	current_hp -= amount
	hp_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		die()
		return
	
	start_invincibility()

func start_invincibility() -> void:
	is_invincible = true
	var color_rect = $ColorRect
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.3, 0.1)
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.1)
	tween.set_loops(int(invincibility_time / 0.2))
	
	await get_tree().create_timer(invincibility_time).timeout
	is_invincible = false
	color_rect.modulate.a = 1.0

func gain_exp(amount: int) -> void:
	current_exp += amount
	
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level_up_now()
	
	exp_changed.emit(current_exp, exp_to_next_level)

func level_up_now() -> void:
	level += 1
	exp_to_next_level = int(exp_to_next_level * 1.3)
	
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	
	flash_level_up()
	level_up.emit(level)
	GameManager.on_player_level_up(level)  # 추가
	print("레벨 업! Lv.", level)
	
	# 레벨업 선택지 띄우기
	show_weapon_choices()

func flash_level_up() -> void:
	var color_rect = $ColorRect
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate", Color(2, 2, 2), 0.1)
	tween.tween_property(color_rect, "modulate", Color(1, 1, 1), 0.2)

# 레벨업 시 제시할 무기 3개 선정
func show_weapon_choices() -> void:
	var available: Array = []
	
	# 획득 가능한 무기 모으기 (미보유 or 아직 최대 레벨 미만)
	for weapon_id in weapon_levels.keys():
		if weapon_levels[weapon_id] < max_weapon_levels[weapon_id]:
			available.append(weapon_id)
	
	# 선택지가 없으면 (모든 무기 최대) 그냥 종료
	if available.is_empty():
		return
	
	# 3개 뽑기 (랜덤). 부족하면 중복 허용
	var choices: Array = []
	available.shuffle()
	
	for i in 3:
		var weapon_id = available[i % available.size()]
		var info = weapon_info[weapon_id]
		var desc = info.description_new if weapon_levels[weapon_id] == 0 else info.description_upgrade
		
		choices.append({
			"id": weapon_id,
			"name": info.name,
			"description": desc
		})
	
	var level_up_screen = get_tree().get_first_node_in_group("level_up_screen")
	if level_up_screen:
		level_up_screen.show_options(choices)

# 무기 선택 시 호출
func _on_weapon_selected(weapon_id: String) -> void:
	weapon_levels[weapon_id] += 1
	print("무기 선택: ", weapon_id, " Lv.", weapon_levels[weapon_id])
	
	match weapon_id:
		"orbiting":
			var weapon = get_node_or_null("OrbitingPebbleWeapon")
			if weapon and weapon.has_method("upgrade"):
				weapon.upgrade()
		"meteor":
			var weapon = get_node_or_null("MeteorWeapon")
			if weapon:
				var timer = weapon.get_node("Timer")
				if weapon_levels[weapon_id] == 1:
					timer.start()
				else:
					weapon.upgrade()
		"bouncing":
			var weapon = get_node_or_null("BouncingPebbleWeapon")
			if weapon:
				var timer = weapon.get_node("Timer")
				if weapon_levels[weapon_id] == 1:
					timer.start()
				else:
					weapon.upgrade()
		"haedori":
			var weapon = get_node_or_null("HaedoriSummonWeapon")
			if weapon and weapon.has_method("upgrade"):
				weapon.upgrade()

func die() -> void:
	died.emit()
	GameManager.on_player_died()  # 추가
	print("Game Over!")
	
	# 게임오버 화면 표시
	var game_over_screen = get_tree().get_first_node_in_group("game_over_screen")
	if game_over_screen and game_over_screen.has_method("show_game_over"):
		await get_tree().create_timer(0.5).timeout  # 0.5초 후 (죽는 연출)
		game_over_screen.show_game_over()
	else:
		get_tree().paused = true  # 백업: 화면 없으면 그냥 정지
