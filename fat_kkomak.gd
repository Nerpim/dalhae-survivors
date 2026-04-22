extends CharacterBody2D

@export var speed: float = 30.0
@export var max_hp: int = 150
@export var damage: int = 20
@export var exp_orb_scene: PackedScene
@export var exp_value: int = 5

@export var aura_type: String = "none"

var current_hp: int
var player: Node2D = null

@onready var hp_bar: ProgressBar = $HPBar
@onready var body: ColorRect = $Body
@onready var aura_glow: ColorRect = $AuraGlow

func _ready() -> void:
	apply_aura_stats()
	
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	
	apply_aura_visual()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func take_damage(amount: int) -> void:
	current_hp -= amount
	hp_bar.value = current_hp
	
	var tween = create_tween()
	tween.tween_property(body, "modulate", Color(2, 2, 2), 0.05)
	tween.tween_property(body, "modulate", Color(1, 1, 1), 0.1)
	
	if current_hp <= 0:
		GameManager.on_enemy_killed("fat_kkomak")
		drop_exp()
		queue_free()

func drop_exp() -> void:
	if exp_orb_scene == null:
		return
	
	var orb_count = 3
	match aura_type:
		"blue":
			orb_count = 9
		"gold":
			orb_count = 18
	
	for i in orb_count:
		var orb = exp_orb_scene.instantiate()
		get_tree().current_scene.call_deferred("add_child", orb)
		orb.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		orb.value = exp_value

func apply_aura_stats() -> void:
	match aura_type:
		"blue":
			max_hp *= 2
			damage *= 2
		"gold":
			max_hp *= 4
			damage *= 4

func apply_aura_visual() -> void:
	match aura_type:
		"blue":
			aura_glow.color = Color(0.3, 0.7, 1.0, 0.6)
			scale = Vector2(1.2, 1.2)
			start_aura_pulse(Color(0.3, 0.7, 1.0, 0.6), Color(0.3, 0.7, 1.0, 0.9))
		"gold":
			aura_glow.color = Color(1.0, 0.85, 0.2, 0.6)
			scale = Vector2(1.3, 1.3)
			start_aura_pulse(Color(1.0, 0.85, 0.2, 0.6), Color(1.0, 0.85, 0.2, 1.0))
		_:
			aura_glow.color = Color(0, 0, 0, 0)

func start_aura_pulse(dim_color: Color, bright_color: Color) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(aura_glow, "color", bright_color, 0.5)
	tween.tween_property(aura_glow, "color", dim_color, 0.5)
