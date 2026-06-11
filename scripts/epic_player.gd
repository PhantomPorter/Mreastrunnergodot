extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -300.0

@export var normal_gravity_scale: float = 1.0
@export var glide_gravity_scale: float = 0.25 

@onready var standing_collision: CollisionShape2D = $theguy
@onready var sliding_collision: CollisionShape2D = $theguy_slide
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


@onready var arm: Node2D = $arm
var is_parrying: bool = false
var is_on_cooldown: bool = false

const PARRY_WINDOW: float = 0.67
const COOLDOWN_DURATION: float = 0.50 

var currently_sliding: bool = false
var normal_sprite_offset: Vector2
var slide_sprite_offset: Vector2
func _ready() -> void:
	var new_shape = RectangleShape2D.new()
	
	
	new_shape.size = Vector2(0, 2) 
	
	sliding_collision.shape = new_shape

	sliding_collision.set_deferred("disabled", true)
	standing_collision.set_deferred("disabled", false)
	
	normal_sprite_offset = sprite.position
	
	var standing_height: float = standing_collision.shape.size.y if standing_collision.shape is RectangleShape2D else standing_collision.shape.height
	var sliding_height: float = sliding_collision.shape.size.y
	var height_difference = (standing_height - sliding_height) / 2.0
	
	# Set the slide offset destination
	slide_sprite_offset = normal_sprite_offset + Vector2(0, height_difference)



func _physics_process(delta: float) -> void:
	var is_sliding: bool = Input.is_action_pressed("ui_down")
	
	if is_sliding != currently_sliding:
		set_slide_state(is_sliding)

	velocity.x = SPEED

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
	
	


func set_slide_state(sliding: bool) -> void:
	currently_sliding = sliding
	
	if sliding:
		sprite.play("slide")
		sprite.position = slide_sprite_offset
		
		standing_collision.set_deferred("disabled", true)
		sliding_collision.set_deferred("disabled", false)
	else:
		sprite.play("default")
		sprite.position = normal_sprite_offset
		
		standing_collision.set_deferred("disabled", false)
		sliding_collision.set_deferred("disabled", true)


 

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
