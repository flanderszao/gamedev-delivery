extends CharacterBody2D

@export var walk_speed := 100 #velocidade máxima de caminhada
@export var run_speed := 600 #velocidade máxima de corrida
@export var jump_speed := -600.0 #velocidade de pulo
@export var gravity := 2500.0

@export var acceleration := 200.0 #aceleração
@export var ground_friction := 400.0 #fricção de movimento
@export var skid_friction := 900.0 #fricção de freio

@onready var sprite = $Sprites
@onready var sfx = $SFX

@export var wants_run = false #trava de corrida do personagem

enum State { #estados que o personagem pode estar, relevante para sprites
	IDLE,
	WALK,
	RUN,
	SKID,
	JUMP,
	FRONTJUMP,
	WALLGRAB
}

var pulo_sfx = preload("res://SoundsAssets/pulo.wav")
var pegada_sfx = preload("res://SoundsAssets/pegada.wav")
var freio_sfx = preload("res://SoundsAssets/freio(sonic).wav")

var state = State.IDLE #estado atual do personagem
var last_state = state #último estado do personagem
var turn_lock_time := 0.0 #trava de movimento
var stored_velocity := 0 #velocidade guardada, relevante pra momentum

var step_timer := 0 #para pegadas
var played := false


func _physics_process(delta):
	var input_direction := Input.get_axis("left", "right")

	get_input()
	update_state(input_direction)

	if turn_lock_time > 0:
		turn_lock_time -= delta

	update_movement(input_direction, delta)
	update_face(input_direction)

	move_and_slide()
	animate()
	soundize(delta)


func get_input():
	if Input.is_action_just_pressed("a_button"): #gatilho de corrida
		wants_run = true

	if Input.is_action_just_pressed("up") and is_on_floor(): #pulo
		if state == State.RUN:
			state = State.FRONTJUMP
		else:
			state = State.JUMP

		velocity.y = jump_speed


func update_state(input_direction):
	if is_skidding(input_direction): #desativa corrida se freiar
		wants_run = false
	
	if not is_on_floor():
		if state == State.WALLGRAB and Input.is_action_just_pressed("up"):
			do_wall_jump()
			return
			
		if is_on_wall() and state == State.FRONTJUMP:
			state = State.WALLGRAB
			return
		
		if state == State.WALLGRAB:
			return

		if state == State.FRONTJUMP:
			stored_velocity = abs(velocity.x)
			return

		if last_state == State.RUN:
			state = State.FRONTJUMP
		else:
			state = State.JUMP

		return

	if is_skidding(input_direction):
		if state != State.SKID:
			turn_lock_time = 0.50
		state = State.SKID
		last_state = state
		return

	if abs(velocity.x) < 25:
		state = State.IDLE
		last_state = state
		return

	if abs(velocity.x) > 300:
		state = State.RUN
	else:
		state = State.WALK
		
	if is_on_floor():
		last_state = state

func update_movement(input_direction, delta):
	var target_speed = walk_speed
	if wants_run:
		target_speed = run_speed
		
	if state == State.WALLGRAB:
		velocity.y = 0
		velocity.x = 0
		turn_lock_time = 0.15
		return

	if state == State.SKID:
		velocity.x = move_toward(velocity.x, 0, skid_friction * delta)
		return

	if input_direction != 0:
		velocity.x = move_toward(
			velocity.x,
			input_direction * target_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			ground_friction * delta
		)

	if not is_on_floor():
		velocity.y += gravity * delta


func update_face(_input_direction):
	if turn_lock_time > 0:
		return

	if abs(velocity.x) > 10:
		sprite.flip_h = velocity.x < 0

func is_skidding(input_direction):
	if is_on_floor():
		if input_direction == 0:
			return false

		if abs(velocity.x) < 50:
			return false

		return sign(input_direction) != sign(velocity.x)

func do_wall_jump():
	var wall_dir = get_wall_normal().x

	velocity.x = wall_dir * stored_velocity
	velocity.y = jump_speed

	state = State.FRONTJUMP
	last_state = State.RUN
	sprite.flip_h = wall_dir < 0
	turn_lock_time = 0.2

func animate():
	match state:
		State.JUMP:
			if sprite.animation != "Jump":
				sprite.play("Jump")
				
		State.FRONTJUMP:
			if sprite.animation != "FrontJump":
				sprite.play("FrontJump")
				
		State.WALLGRAB:
			if sprite.animation != "WallGrab":
				sprite.play("WallGrab")

		State.SKID:
			if sprite.animation != "Stop":
				sprite.play("Stop")

		State.RUN:
			if sprite.animation != "Run":
				sprite.play("Run")

		State.WALK:
			if sprite.animation != "Walk":
				sprite.play("Walk")

		State.IDLE:
			if sprite.animation != "Idle":
				sprite.play("Idle")

func soundize(delta):
	
	match state:
		State.JUMP:
			if not played:
				sfx.stream = pulo_sfx
				sfx.play()
				played = true
				
		State.FRONTJUMP:
			if not played:
				sfx.stream = pulo_sfx
				sfx.play()
				played = true
				
		State.WALLGRAB:
			played = false
			pass

		State.SKID:
			if not played:
				sfx.stream = freio_sfx
				sfx.play()
				played = true

		State.RUN:
			played = false
			step_timer -= delta
			if step_timer <= 0:
				sfx.stream = pegada_sfx
				sfx.play()
				step_timer = 20

		State.WALK:
			played = false
			step_timer -= delta
			if step_timer <= 0:
				sfx.stream = pegada_sfx
				sfx.play()
				step_timer = 30

		State.IDLE:
			played = false
			pass
			
		_:
			played = false
