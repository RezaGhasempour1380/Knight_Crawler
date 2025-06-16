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
@onready var attack_hitbox = $Sprite2D/attack_hitbox/CollisionShape2D
@onready var jump_buffer_timer = $JumpBufferTimer
@onready var jump_height_timer = $JumpHeightTimer

var is_crouching = false
var stuck_under_object = false
var attack_mode = false
var can_coyote_jump = false
var attack_toggle_normal_no_move = true
var attack_toggle_crouch = true
var face_right = true
var jump_buffered = false  
var is_rolling = false
var is_turning = false

var standing_cshape = preload("res://resources/player_standing_collision_shape.tres")
var crouching_cshape = preload("res://resources/player_crouching_collision_shape.tres")
var standing_attack_cshape = preload("res://resources/player_standing_attack_collision.tres")
var crouching_attack_cshape = preload("res://resources/player_crouching_attack_collision.tres")

var saved_velocity = Vector2.ZERO

func _physics_process(_delta):
	if !is_on_floor() && (can_coyote_jump == false):
		velocity.y += gravity
		if velocity.y > 1000:
			velocity.y = 1000
	
	if Input.is_action_just_pressed("jump"):
		jump_height_timer.start()
		jump()
	
	var horizontal_direction = Input.get_axis("move_left","move_right")
	if is_turning: # Can't turn around on the middle of a turning animation
		horizontal_direction = 0
	check_direction(horizontal_direction)
	
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
	
	if Input.is_action_just_pressed("rolling"):
		if !horizontal_direction == 0 and !is_crouching:
			roll()
		else:
			pass
	
	if is_rolling and !ap.is_playing():
		is_rolling = false
	
	var was_on_floor = is_on_floor(); 

	move_and_slide()
	
	if was_on_floor && !is_on_floor() && velocity.y >= 0:
		can_coyote_jump = true
		coyote_timer.start()
	
	if !was_on_floor and is_on_floor():
		if jump_buffered:
			jump_buffered = false
			jump()
	
	update_animations(horizontal_direction)

func _on_coyote_timer_timeout():
	can_coyote_jump = false

func _on_jump_buffer_timer_timeout():
	jump_buffered = false
	
func _on_jump_height_timer_timeout():
	if !Input.is_action_pressed("jump"):
		if velocity.y < -100:
			velocity.y = -100
	else:
		pass

func above_head_empty() -> bool:
	var result = !crouch_raycast_1.is_colliding() && !crouch_raycast_2.is_colliding() 
	return result
	
func update_animations(horizontal_direction):
	if attack_mode or is_rolling:
		return
	
	if is_turning:
		if ap.current_animation != "turn_around":
			is_turning = false
		return
	
	if is_on_floor():
		if horizontal_direction == 0:
			if is_crouching and is_rolling == false:
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
	sprite.flip_h = is_turning != (horizontal_direction == -1)
	sprite.position.x = horizontal_direction * 5
	check_direction(horizontal_direction)
	if (is_crouching == false and face_right==true):
		attack_hitbox.position.x = (horizontal_direction * 33)
	elif (is_crouching == false and face_right==false):
		attack_hitbox.position.x = (horizontal_direction * 33)+10
	elif (is_crouching == true and face_right==true):
		attack_hitbox.position.x = (horizontal_direction * 29)
	elif (is_crouching == true and face_right==false):
		attack_hitbox.position.x = (horizontal_direction * 29)+10
	
	
func check_direction(horizontal_direction):
	var prev_face = face_right
	if(horizontal_direction == 1):
		face_right = true
	elif(horizontal_direction == -1):
		face_right = false
	
	if is_on_floor() and prev_face != face_right and !is_crouching:
		is_turning = true
		switch_direction(horizontal_direction)
		ap.play("turn_around")
	
func crouch():
	if is_crouching:
		return
	is_crouching = true
	speed = 50
	cshape.shape = crouching_cshape
	cshape.position.y = -13.75
	attack_hitbox.shape = crouching_attack_cshape
	attack_hitbox.position.y = -12
	if face_right:
		attack_hitbox.position.x = 29 
	else:
		attack_hitbox.position.x = -29+10  
	
func stand():
	if is_crouching == false:
		return
	is_crouching = false
	speed = 100
	cshape.shape = standing_cshape
	cshape.position.y = -19
	attack_hitbox.shape = standing_attack_cshape
	attack_hitbox.position.y = -19
	if face_right:
		attack_hitbox.position.x = 33 
	else:
		attack_hitbox.position.x = -33+10 
	
func jump():
	if is_on_floor() || can_coyote_jump:
		velocity.y = -jump_force
		if can_coyote_jump:
			can_coyote_jump = false;
	else:
		if !jump_buffered:
			jump_buffered = true
			jump_buffer_timer.start()
	
func roll():
	if is_rolling:
		return
	is_rolling = true
	ap.play("roll")
	
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

func _on_attack_hitbox_area_entered(area):
	pass # Replace with function body.






