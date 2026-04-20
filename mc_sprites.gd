extends AnimatedSprite2D

enum State { #estados que o personagem pode estar, relevante para sprites
	IDLE,
	WALK,
	RUN,
	SKID,
	JUMP,
	FRONTJUMP,
	WALLGRAB,
	SLIDE,
	PARRY
	#FALL,
	#HURT,
	#DEATH
}

func animate(state):
	match state:
		State.JUMP:
			if animation != "Jump":
				play("Jump")
				
		State.FRONTJUMP:
			if animation != "FrontJump":
				play("FrontJump")
				
		State.WALLGRAB:
			if animation != "WallGrab":
				play("WallGrab")

		State.SKID:
			if animation != "Skid":
				play("Skid")
				
		State.SLIDE:
			if animation != "Slide":
				play("Slide")

		State.RUN:
			if animation != "Run":
				play("Run")

		State.WALK:
			if animation != "Walk":
				play("Walk")
				
		State.PARRY:
			if animation != "Parry":
				play("Parry")

		State.IDLE:
			if animation != "Idle":
				play("Idle")
