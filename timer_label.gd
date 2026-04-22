extends Label

func _ready() -> void:
	# StageManager 찾아서 시그널 연결
	var stage_manager = get_tree().get_first_node_in_group("stage_manager")
	if stage_manager:
		stage_manager.time_updated.connect(_on_time_updated)
		stage_manager.boss_warning.connect(_on_boss_warning)
		stage_manager.boss_spawn_time.connect(_on_boss_spawn)

func _on_time_updated(time_left: float) -> void:
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	text = "%02d:%02d" % [minutes, seconds]
	
	# 마지막 30초는 빨갛게
	if time_left <= 30 and time_left > 5:
		modulate = Color(1, 0.5, 0.5)
	elif time_left > 30:
		modulate = Color(1, 1, 1)

func _on_boss_warning() -> void:
	# 깜빡임
	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(self, "modulate", Color(2, 0.3, 0.3), 0.2)
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5), 0.2)

func _on_boss_spawn() -> void:
	text = "BOSS!"
	modulate = Color(1, 0.2, 0.2)
