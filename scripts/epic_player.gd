extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -300.0
const ACCELERATION = 300

@export var normal_gravity_scale: float = 1.0
@export var glide_gravity_scale: float = 0.25 # Gravity is 4x weaker while gliding

func _physics_process(delta: float) -> void:
	velocity.x = SPEED
	if not is_on_floor():
	# GLIDE: Held while falling downward
		if Input.is_action_pressed("ui_accept") and velocity.y > 0:
			# Gravity still increases velocity, but much slower
			velocity += get_gravity() * delta * glide_gravity_scale
			$AnimatedSprite2D.play("glide") 
		else: 
			# NORMAL FALL: Standard gravity acceleration
			velocity += get_gravity() * delta * normal_gravity_scale
			$AnimatedSprite2D.play("jump")
	else:
		$AnimatedSprite2D.play("default")


	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$AnimatedSprite2D.play("jump")

	# Get the input direction and handle the movement/deceleration.

	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("spike"):
			get_tree().call_deferred("reload_current_scene")
