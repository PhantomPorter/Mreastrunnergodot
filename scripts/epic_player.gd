extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	velocity.x = SPEED

	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if (collision.get_collider().name == "spike"):
			get_tree().reload_current_scene()
