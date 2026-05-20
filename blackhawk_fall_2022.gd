extends Sprite2D

@onready var raycast = get_node("RayCast2D") as RayCast2D

var attack = false
var target: Node2D = null  # store target at class scope
var spike_scene = preload("res://scenes/spike.tscn")
var drop_timer = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	var drop_interval = randf_range(0.45, 2.01)
	if raycast.is_colliding():
		var hit_node = raycast.get_collider()
		if hit_node.is_in_group("player"):
			attack = true
			target = hit_node  # save to class-level variable

	if attack and target != null:
		position.x = move_toward(position.x, target.position.x + randi_range(134, 250), 5)
		drop_timer += delta
		if drop_timer >= drop_interval:
			drop_timer = 0.0	
			spawn_drop()


func spawn_drop() -> void:
	var drop = spike_scene.instantiate()
	drop.position = position
	get_parent().add_child(drop) 
