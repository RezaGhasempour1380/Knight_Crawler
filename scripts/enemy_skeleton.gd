extends CharacterBody2D

@export var speed = 100
@export var gravity = 20

@onready var ap = $AnimationPlayer

func _physics_process(delta):
	# Apply gravity if not on the floor
	if not is_on_floor():
		velocity.y += gravity

	# Apply movement
	move_and_slide()

	# Play idle animation if not already playing
	if ap.current_animation != "idle" or not ap.is_playing():
		ap.play("idle")
