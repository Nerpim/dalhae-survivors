extends Node2D

@export var haedori_scene: PackedScene
@export var max_level: int = 4  # 최종 진화 레벨

var haedoris: Array = []  # 현재 소환된 해돌이들

# 획득/강화: upgrade() 호출될 때
func upgrade() -> void:
	# 아직 해돌이가 없으면 (첫 획득) → Lv1 알 소환
	if haedoris.is_empty():
		spawn_new_haedori()
		return
	
	# 가장 레벨 낮은 해돌이 찾기
	var lowest_level_haedori = haedoris[0]
	for h in haedoris:
		if h.level < lowest_level_haedori.level:
			lowest_level_haedori = h
	
	# 그 해돌이가 아직 최대 레벨이 아니면 진화
	if lowest_level_haedori.level < max_level:
		lowest_level_haedori.evolve()
	else:
		# 모두 최대 레벨이면 새 해돌이 알 추가
		spawn_new_haedori()

func spawn_new_haedori() -> void:
	if haedori_scene == null:
		return
	
	var haedori = haedori_scene.instantiate()
	get_tree().current_scene.add_child(haedori)
	haedori.global_position = global_position
	haedoris.append(haedori)
