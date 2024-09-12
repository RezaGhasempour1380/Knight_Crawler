extends CharacterBody2D

@export var speed = 100
@export var gravity = 20
@export var jump_force = 300

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D
@onready var crouch_raycast_1 = $crouch_raycast_1
@onready var crouch_raycast_2 = $crouch_raycast_2
@onready var coyote_timer = $CoyoteTimer
@onready var attack_hitbox = $attack_hitbox

var is_crouching = false
var stuck_under_object = false
var attack_mode = false
var can_coyote_jump = false
var attack_toggle_normal_no_move = true
var attack_toggle_crouch = true  

var standing_cshape = preload("res://resources/player_standing_collision_shape.tres")
var crouching_cshape = preload("res://resources/player_crouching_collision_shape.tres")
var atk_standing_csshape = preload("res://resources/player_standing_attack_collision.tres")
var atk_crouch_csshape = preload("res://resources/player_crouching_attack_collision.tres")

var saved_velocity = Vector2.ZERO

func _physics_process(_delta):
	if !is_on_floor() && (can_coyote_jump == false):
		velocity.y += gravity
		if velocity.y > 1000:
			velocity.y = 1000
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() || can_coyote_jump:
			velocity.y = -jump_force
			if can_coyote_jump:
				can_coyote_jump = false;
	
	var horizontal_direction = Input.get_axis("move_left","move_right")
	
	if !attack_mode:
		velocity.x = speed * horizontal_direction
	else:
		velocity.x = 0
	
	if horizontal_direction != 0:
		switch_direction(horizontal_direction)
		
	if Input.is_action_just_pressed("crouch"):
		crouch()
	elif Input.is_action_just_released("crouch"):
		if above_head_empty():
			stand()
		else:
			if stuck_under_object != true:
				stuck_under_object = true
	
	if stuck_under_object && above_head_empty():
		if !Input.is_action_pressed("crouch"):
			stand()
			stuck_under_object = false
	
	if Input.is_action_just_pressed("attack") and !attack_mode and is_on_floor():
			attack_mode = true
			saved_velocity = velocity 
			velocity.x = 0  
			attack()
	
	if attack_mode and !ap.is_playing():
		attack_mode = false
		velocity = saved_velocity
	
	var was_on_floor = is_on_floor(); 

	move_and_slide()
	
	if was_on_floor && !is_on_floor() && velocity.y >= 0:
		can_coyote_jump = true
		coyote_timer.start()
	
	update_animations(horizontal_direction)

func _on_coyote_timer_timeout():
	can_coyote_jump = false

func above_head_empty() -> bool:
	var result = !crouch_raycast_1.is_colliding() && !crouch_raycast_2.is_colliding() 
	return result
	
func update_animations(horizontal_direction):
	if attack_mode:
		return
	
	if is_on_floor():
		if horizontal_direction == 0:
			if is_crouching:
				ap.play("crouch")
			elif attack_mode == false:
				ap.play("idle")
		else:
			if is_crouching:
				ap.play("crouch_walk")
			else:
				ap.play("run")
	else: 
		if velocity.y < 0:
			ap.play("jump")
		elif velocity.y >0: 
			ap.play("fall")
	
func switch_direction(horizontal_direction):
	sprite.flip_h = (horizontal_direction == -1)
	sprite.position.x = horizontal_direction * 5
	
func crouch():
	if is_crouching:
		return
	is_crouching = true
	speed = 50
	cshape.shape = crouching_cshape
	cshape.position.y = -13.75
	
func stand():
	if is_crouching == false:
		return
	is_crouching = false
	speed = 100
	cshape.shape = standing_cshape
	cshape.position.y = -19
	
func attack():
	if is_crouching:
		if attack_toggle_crouch:
			ap.play("crouch_atk") 
	else:
		if attack_toggle_normal_no_move:
			ap.play("atk_no_move_1")
		else:
			ap.play("atk_no_move_2")
		attack_toggle_normal_no_move = !attack_toggle_normal_no_move



