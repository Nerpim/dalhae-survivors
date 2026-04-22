extends ProgressBar

func _ready() -> void:
	# 플레이어 찾아서 시그널 연결
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.hp_changed.connect(_on_player_hp_changed)
		# 초기값 설정
		max_value = player.max_hp
		value = player.current_hp

func _on_player_hp_changed(current: int, maximum: int) -> void:
	max_value = maximum
	value = current
