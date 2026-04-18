extends CharacterBody2D

@export var speed := 400
@export var jump_speed := -1000.0
@export var gravity := 2500.0
@onready var sprite = $AnimatedSprite2D

func get_input():
	var input_direction := Input.get_axis("left", "right")
	velocity.x = input_direction * speed
	var jump := Input.is_action_just_pressed("ui_select")
	if jump and is_on_floor():
		velocity.y = jump_speed
	if is_on_floor() and Input.is_action_just_pressed("down"):
		position.y += 1

func _physics_process(delta):
	velocity.y = velocity.y + (gravity * delta)
	get_input()
	animate()
	move_and_slide()
	
func animate():
	if velocity.x > 0:
		sprite.play("right")
	elif velocity.x < 0:
		sprite.play("left")
	else:
		sprite.stop()
