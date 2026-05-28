extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -300.0

@export var normal_gravity_scale: float = 1.0
@export var glide_gravity_scale: float = 0.25 

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Hitbox tracking
@onready var normal_shape: Shape2D = collision_shape.shape
var normal_offset: Vector2
var slide_shape: RectangleShape2D
var slide_offset: Vector2

# Sprite offset tracking
var normal_sprite_offset: Vector2
var slide_sprite_offset: Vector2

func _ready() -> void:
	normal_offset = collision_shape.position
	normal_sprite_offset = sprite.position
	
	# Determine how tall the original shape is
	var normal_height: float = 0.0
	if normal_shape is RectangleShape2D:
		normal_height = normal_shape.size.y
	elif normal_shape is CapsuleShape2D:
		normal_height = normal_shape.height

	# 1. Setup the slide shape (half height, 1.2x wider)
	slide_shape = RectangleShape2D.new()
	if normal_shape is RectangleShape2D:
		slide_shape.size = Vector2(normal_shape.size.x * 1.2, normal_height * 0.5)
	elif normal_shape is CapsuleShape2D:
		slide_shape.size = Vector2((normal_shape.radius * 2) * 1.2, normal_height * 0.5)

	# 2. MATH FIX: Position the slide hitbox so its BOTTOM matches the normal hitbox's BOTTOM
	# This completely stops floor-clipping and keeps you grounded perfectly
	var height_difference = (normal_height - slide_shape.size.y) / 2.0
	slide_offset = normal_offset + Vector2(0, height_difference)
	slide_sprite_offset = normal_sprite_offset + Vector2(0, height_difference)

func _physics_process(delta: float) -> void:
	velocity.x = SPEED

	# Track if the player wants to slide right now
	var is_sliding: bool = Input.is_action_pressed("ui_down")

	# --- HANDLE AIR STATE ---
	if not is_on_floor():
		if Input.is_action_pressed("ui_accept") and velocity.y > 0:
			velocity += get_gravity() * delta * glide_gravity_scale
			
			if is_sliding:
				set_slide_state(true)
			else:
				sprite.play("glide")
				set_slide_state(false)
		else:
			velocity += get_gravity() * delta * normal_gravity_scale
			
			if is_sliding:
				set_slide_state(true)
			elif velocity.y > 0:
				sprite.play("default")
				set_slide_state(false)
	
	# --- HANDLE GROUND STATE ---
	else:
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
			
			if is_sliding:
				set_slide_state(true)
			else:
				sprite.play("jump")
				set_slide_state(false)
				
		elif is_sliding:
			set_slide_state(true)
		else:
			sprite.play("default")
			set_slide_state(false)

	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("spike"):
			get_tree().call_deferred("reload_current_scene")

# Helper function to cleanly swap hitboxes AND sprite positions together
func set_slide_state(sliding: bool) -> void:
	if sliding:
		sprite.play("slide")
		collision_shape.shape = slide_shape
		collision_shape.position = slide_offset
		sprite.position = slide_sprite_offset
	else:
		collision_shape.shape = normal_shape
		collision_shape.position = normal_offset
		sprite.position = normal_sprite_offset 
