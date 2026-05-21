extends Sprite2D

@onready var raycast = get_node("RayCast2D") as RayCast2D
@onready var audio = get_node("AudioStreamPlayer2D") as AudioStreamPlayer2D
var drop_interval: float = 1.0
var attack = false
var target: Node2D = null  # store target at class scope
var spike_scene = preload("res://scenes/spike.tscn")
var drop_timer = 0.0
var target_offset: float = 0.0 # Store the random distance here
var speed: float = 300.0 # Pixel speed per second

func _ready() -> void:
	randomize_interval()

func _process(delta: float) -> void:
	if raycast.is_colliding():
		var hit_node = raycast.get_collider()
		if hit_node.is_in_group("player"):
			attack = true
			target = hit_node  # save to class-level variable
			target_offset = randf_range(134.0, 250.0)

	if attack and target != null:
		if not audio.is_playing():
			audio.play()
		var destination_x = target.position.x + 190.0
		
		# Move smoothly using delta (multiplied by speed)
		position.x = lerp(position.x, destination_x, 1.0 - exp(-5.0 * delta))
		drop_timer += delta
		if drop_timer >= drop_interval:
			spawn_drop()
			drop_timer = 0.0	
			randomize_interval()


func spawn_drop() -> void:
	var drop = spike_scene.instantiate()
	play_sound()
	drop.position = Vector2(position.x, position.y + 20)
	get_parent().add_child(drop) 
	
	
func play_sound():
	var dropsound = load("res://assest/po.mp3")
	$pop.stream = dropsound
	$pop.play()
	
func randomize_interval() -> void:
	drop_interval = randf_range(0.45, 2.01)
