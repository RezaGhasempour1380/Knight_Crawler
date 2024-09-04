extends CharacterBody2D

@export var speed = 100
@export var gravity = 20
@export var jump_force = 300

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D
@onready var crouch_raycast_1 = $crouch_raycast_1
@onready var crouch_raycast_2 = $crouch_raycast_2

var is_crouching = false
var stuck_under_object = false

var standing_cshape = preload("res://resources/player_standing_collision_shape.tres")
var crouching_cshape = preload("res://resources/player_crouching_collision_shape.tres")

func _physics_process(_delta):
	if !is_on_floor():
		velocity.y += gravity
		if velocity.y > 1000:
			velocity.y = 1000
	
	if Input.is_action_just_pressed("jump") && is_on_floor():
		velocity.y = -jump_force
	
	var horizontal_direction = Input.get_axis("move_left","move_right")
	velocity.x = speed * horizontal_direction
	
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
	
	move_and_slide()
	
	update_animations(horizontal_direction)
	
func above_head_empty() -> bool:
	var result = !crouch_raycast_1.is_colliding() && !crouch_raycast_2.is_colliding() 
	return result
	
func update_animations(horizontal_direction):
	if is_on_floor():
		if horizontal_direction == 0:
			if is_crouching:
				ap.play("crouch")
			else:
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
	sprite.position.x = horizontal_direction * 1
	
func crouch():
	if is_crouching:
		return
	is_crouching = true
	speed = 50
	cshape.shape = crouching_cshape
	cshape.position.y = -3.5
	
func stand():
	if is_crouching == false:
		return
	is_crouching = false
	speed = 100
	cshape.shape = standing_cshape
	cshape.position.y = -5.5
	
