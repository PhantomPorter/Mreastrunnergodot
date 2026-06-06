extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -300.0

@export var normal_gravity_scale: float = 1.0
@export var glide_gravity_scale: float = 0.25 

@onready var collision_shape: CollisionShape2D = $theguy
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


@onready var arm: Node2D = $arm
var is_parrying: bool = false
var is_on_cooldown: bool = false

const PARRY_WINDOW: float = 0.67
const COOLDOWN_DURATION: float = 0.50 

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
	if Input.is_action_just_pressed("parry"):
		try_parry()
	
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("spike"):
			get_tree().call_deferred("reload_current_scene")

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

func try_parry() -> void:
	if is_parrying or is_on_cooldown:
		return
		
	trigger_parry_sequence()

func trigger_parry_sequence() -> void:
	is_parrying = true
	arm.visible = true
	play_arm_sound(false)
	
	await get_tree().create_timer(PARRY_WINDOW).timeout
	
	is_parrying = false
	arm.visible = false 
	is_on_cooldown = true
	
	await get_tree().create_timer(COOLDOWN_DURATION).timeout
	
	is_on_cooldown = false

func play_arm_sound(soundbyte: bool) -> void: 
	if soundbyte: 
		var sound = load("res://assest/parry.mp3") 
		$arm/armsounds.stream = sound 
		$arm/armsounds.play() 
	else: 
		var sound = load("res://assest/swoosh.ogg") 
		$arm/armsounds.stream = sound 
		$arm/armsounds.play()

func _on_parry_box_area_entered(incoming_area: Area2D) -> void:
	if incoming_area.is_in_group("enemy_attack"):
		
		if is_parrying:
			play_arm_sound(true) 
			
			if incoming_area.has_method("reflect_or_recoil"):
				incoming_area.reflect_or_recoil()