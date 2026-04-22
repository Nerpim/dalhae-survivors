extends Node2D

@export var ninja_scene: PackedScene
@export var squad_size: int = 5
@export var formation_spacing: float = 40.0
@export var lifetime: float = 10.0
@export var speed: float = 250.0

var move_direction: Vector2 = Vector2.RIGHT
var ninjas: Array = []

func _ready() -> void:
	await get_tree().create_timer(lifetime).timeout
	for n in ninjas:
		if is_instance_valid(n):
			n.queue_free()
	queue_free()

func _process(delta: float) -> void:
	global_position += move_direction * speed * delta

func setup_squad(spawn_pos: Vector2, direction: Vector2) -> void:
	move_direction = direction.normalized()
	global_position = spawn_pos
	
	var perpendicular = Vector2(-move_direction.y, move_direction.x)
	var half = (squad_size - 1) / 2.0
	
	for i in squad_size:
		var ninja = ninja_scene.instantiate()
		get_tree().current_scene.call_deferred("add_child", ninja)
		ninjas.append(ninja)
		
		var offset = perpendicular * formation_spacing * (i - half)
		
		ninja.global_position = spawn_pos + offset
		ninja.direction = move_direction
		ninja.squad = self
		ninja.formation_offset = offset
