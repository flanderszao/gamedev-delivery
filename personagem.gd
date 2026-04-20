extends CharacterBody2D

@export var walk_speed := 100 #velocidade máxima de caminhada
@export var run_speed := 600 #velocidade máxima de corrida
@export var jump_speed := -600.0 #velocidade de pulo
@export var gravity := 2500.0

@export var acceleration := 200.0 #aceleração
@export var ground_friction := 400.0 #fricção de movimento
@export var skid_friction := 900.0 #fricção de freio

@export var camera_offset_x := 100

@onready var sprite = $Sprites
@onready var sfx = $SFX
@onready var camera = $Camera
@onready var colisao1 = $DePe
@onready var colisao2 = $Agachado

@export var wants_run = false #trava de corrida do personagem

enum State { #estados que o personagem pode estar, relevante para sprites
	IDLE,
	WALK,
	RUN,
	SKID,
	JUMP,
	FRONTJUMP,
	WALLGRAB,
	SLIDE
}

enum FACE {
	Right,
	Left
}

var pulo_sfx = preload("res://SoundsAssets/pulo.wav")
var pegada_sfx = preload("res://SoundsAssets/pegada.wav")
var freio_sfx = preload("res://SoundsAssets/freio(sonic).wav")

@export var state = State.IDLE #estado atual do personagem
var last_state = state #último estado do personagem
var state_frames := 0 #há quanto tempo está no mesmo state

var turn_lock_time := 0.0 #trava de movimento
var stored_velocity := 0 #velocidade guardada, relevante pra momentum
var recharge := 0.0
var energy := 100

var step_timer := 0 #para pegadas

var face = FACE.Right

func _physics_process(delta):
	var input_direction := Input.get_axis("left", "right")

	get_input()
	update_state(input_direction)
	update_collision()

	if turn_lock_time > 0:
		turn_lock_time -= delta

	update_movement(input_direction, delta)
	update_face(input_direction)
	update_camera()
	update_energy(delta)

	move_and_slide()
	animate()
		
	if state == last_state:
		state_frames += 1
	else:
		state_frames = 0
		
	last_state = state
	
	soundize(delta)


func get_input():
	if Input.is_action_just_pressed("a_button"): #gatilho de corrida
		if state == State.SLIDE and can_exit_slide():
			state = State.RUN
		wants_run = true
		
	if Input.is_action_pressed("down") and state == State.RUN:
		state = State.SLIDE
		turn_lock_time = 0.3

	if Input.is_action_just_pressed("up") and is_on_floor() and energy>10: #pulo
		if state == State.SLIDE and not can_exit_slide():
			return
		if state == State.RUN or state == State.SLIDE:
			state = State.FRONTJUMP
		else:
			state = State.JUMP
		energy -= 10 #diminui energia ao pular
		velocity.y = jump_speed


func update_state(input_direction):
	if is_skidding(input_direction): #desativa corrida se freiar
		wants_run = false
		
	if state == State.SLIDE:
		if not is_on_floor() and energy > 10:
			energy -= 10
			state = State.FRONTJUMP
			return
		if abs(velocity.x) < 50:
			if can_exit_slide():
				state = State.IDLE
			return
		return
	
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
				return
		elif energy > 10:
			state = State.JUMP

		return

	if is_skidding(input_direction):
		if state != State.SKID:
			turn_lock_time = 0.50
		state = State.SKID
		return

	if abs(velocity.x) < 25:
		state = State.IDLE
		return

	if abs(velocity.x) > 300:
		state = State.RUN
	else:
		state = State.WALK

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
		
	if state == State.SLIDE:
		velocity.x *= 0.99
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
		if velocity.x < 0:
			face = FACE.Left
		else:
			face = FACE.Right
			
	sprite.flip_h = (face == FACE.Left)

func update_collision():
	if state == State.SLIDE:
		colisao1.disabled = true
		colisao2.disabled = false
	else:
		colisao1.disabled = false
		colisao2.disabled = true


func can_exit_slide() -> bool:
	if not is_on_floor():
		return true

	if colisao1 == null or colisao1.shape == null:
		return true

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = colisao1.shape
	params.transform = colisao1.global_transform
	params.collision_mask = collision_mask
	params.exclude = [self]

	var hits := get_world_2d().direct_space_state.intersect_shape(params, 1)
	return hits.is_empty()

func update_camera():
	var base = 80 if face == FACE.Right else -80
	var look = velocity.x * 0.2
	
	var target = base + look
	
	if not state == State.WALLGRAB:
		camera.offset.x = lerp(camera.offset.x, target, 0.1)
		
func update_energy(delta):
	if state == State.SKID and state_frames == 0:
		if energy + recharge > 100:
			energy = 100
		else:
			energy += int(recharge)
		recharge = 0
		return

	if abs(velocity.x) > walk_speed:
		recharge = move_toward(recharge, 1000, 1.5 * delta)
	elif state != State.WALLGRAB:
		recharge = move_toward(recharge, 0, 5 * delta)
	

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
				
		State.SLIDE:
			if sprite.animation != "Slide":
				sprite.play("Slide")

		State.RUN:
			if sprite.animation != "Run":
				sprite.play("Run")

		State.WALK:
			if sprite.animation != "Walk":
				sprite.play("Walk")

		State.IDLE:
			wants_run=false
			if sprite.animation != "Idle":
				sprite.play("Idle")

func soundize(delta):		
	match state:
		State.JUMP:
			if state_frames == 0:
				sfx.stream = pulo_sfx
				sfx.play()
				
		State.FRONTJUMP:
			if state_frames == 0:
				sfx.stream = pulo_sfx
				sfx.play()
				
		State.WALLGRAB:
			pass

		State.SKID:
			if state_frames == 7:
				sfx.stream = freio_sfx
				sfx.play()
				
		State.SLIDE:
			if state_frames == 7:
				sfx.stream = freio_sfx
				sfx.play()

		State.RUN:
			step_timer -= delta
			if step_timer <= 0:
				sfx.stream = pegada_sfx
				sfx.play()
				step_timer = 20

		State.WALK:
			step_timer -= delta
			if step_timer <= 0:
				sfx.stream = pegada_sfx
				sfx.play()
				step_timer = 30

		State.IDLE:
			pass
			
		_:
			pass
