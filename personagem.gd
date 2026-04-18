extends CharacterBody2D

# Get node references
@onready var animated_sprite = $Sprites

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get input direction (-1, 0, 1)
	var direction = Input.get_axis("ui_left", "ui_right")

	# Handle horizontal movement
	if direction != 0:
		velocity.x = direction * SPEED
		
		# Flip sprite
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Update animations
	update_animations(direction)

	# Move the character
	move_and_slide()


func update_animations(direction):
	if not is_on_floor():
		# Air animations
		if velocity.y < 0:
			play_anim("Jump")
		else:
			play_anim("Fall") # Only if you add this animation
	else:
		# Ground animations
		if direction == 0:
			play_anim("Idle")
		else:
			play_anim("Walk") # Change to "Run" if needed


# Prevents restarting the same animation every frame
func play_anim(name):
	if animated_sprite.animation != name:
		animated_sprite.play(name)
