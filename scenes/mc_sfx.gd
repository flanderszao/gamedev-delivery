extends AudioStreamPlayer2D

enum State { #estados que o personagem pode estar, relevante para sprites
	IDLE,
	WALK,
	RUN,
	SKID,
	JUMP,
	FRONTJUMP,
	WALLGRAB,
	SLIDE,
	PARRY,
	HURT,
	DEATH
}

enum Second {
	THUD,
	PARRYHIT,
	CHARGE,
	ERROR
}

#Sons do soundize
var pulo_sfx = preload("res://SoundsAssets/pulo.wav")
var pegada_sfx = preload("res://SoundsAssets/pegada.wav")
var freio_sfx = preload("res://SoundsAssets/freio(sonic).wav")
var parry_sfx = preload("res://SoundsAssets/parry(emerald_00A2).wav")
var hurt_sfx = preload("res://SoundsAssets/levardano.wav")
var parryhit_sfx = preload("res://SoundsAssets/parryhit(emerald_00AF).wav")

@onready var sec = $mc_SEC
#Sons do secondize
var thud_sfx = preload("res://SoundsAssets/thudparede(pokemon).wav")
var charge_sfx = preload("res://SoundsAssets/recharge(emerald_0001).wav")
var error_sfx = preload("res://SoundsAssets/Error(Square).ogg")

var step_timer := 0

func soundize(state, state_frames, delta):
	match state:
		State.JUMP:
			if state_frames == 0:
				stream = pulo_sfx
				play()

		State.FRONTJUMP:
			if state_frames == 0:
				stream = pulo_sfx
				play()

		State.SKID:
			if state_frames == 7:
				stream = freio_sfx
				play()

		State.SLIDE:
			if state_frames == 2:
				stream = freio_sfx
				play()

		State.RUN:
			step_timer -= delta
			if step_timer <= 0:
				stream = pegada_sfx
				play()
				step_timer = 20

		State.WALK:
			step_timer -= delta
			if step_timer <= 0:
				stream = pegada_sfx
				play()
				step_timer = 30

		State.PARRY:
			if state_frames == 0:
				stream = parry_sfx
				play()
				
		State.HURT:
			if state_frames == 0:
				stream = hurt_sfx
				play()
		_:
			pass

func secondize(second):
	match second:
		Second.THUD:
			sec.stream = thud_sfx
			sec.play()
			
		Second.PARRYHIT:
			stream = parryhit_sfx
			play()
			
		Second.CHARGE:
			await get_tree().create_timer(0.5).timeout
			sec.stream = charge_sfx
			sec.play()
		
		Second.ERROR:
			sec.stream = error_sfx
			sec.play()
			
		_:
			pass
