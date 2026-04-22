extends ProgressBar

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.exp_changed.connect(_on_player_exp_changed)
		max_value = player.exp_to_next_level
		value = player.current_exp

func _on_player_exp_changed(current: int, maximum: int) -> void:
	max_value = maximum
	value = current
