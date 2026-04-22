extends ProgressBar

func _ready() -> void:
	hide()
	var stage_manager = get_tree().get_first_node_in_group("stage_manager")
	if stage_manager:
		stage_manager.boss_spawn_time.connect(_on_boss_spawn)

func _on_boss_spawn() -> void:
	await get_tree().create_timer(0.3).timeout
	var boss = get_tree().get_first_node_in_group("boss")
	if boss:
		max_value = boss.max_hp
		value = boss.current_hp
		boss.hp_changed.connect(_on_boss_hp_changed)
		boss.boss_defeated.connect(_on_boss_defeated)
		show()

func _on_boss_hp_changed(current: int, maximum: int) -> void:
	value = current

func _on_boss_defeated() -> void:
	hide()
