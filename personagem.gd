extends AnimatedSprite2D

func _process(_delta):
	if Input.is_action_pressed("ui_up"):
		play("jump_neutral")
	elif Input.is_action_pressed("ui_right"):
		flip_h=false
		play("move_walk")
	elif Input.is_action_pressed("ui_left"):
		flip_h=true
		play("move_walk")
	else:
		play("idle")
