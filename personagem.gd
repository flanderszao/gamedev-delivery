extends CharacterBody2D

@export var walk_speed := 100 #velocidade máxima de caminhada
@export var run_speed := 600 #velocidade máxima de corrida
@export var jump_speed := -600.0 #velocidade de pulo
@export var gravity := 2500.0

@export var acceleration := 200.0 #aceleração
@export var ground_friction := 400.0 #fricção de movimento
@export var skid_friction := 900.0 #fricção de freio
@export var parry_duration := 0.25 #janela de parry em segundos

@export var camera_offset_x := 100

@onready var sprite = $mc_Sprites
@onready var sfx = $mc_SFX
@onready var camera = $mc_Camera

@onready var caixape = $mc_DPe
@onready var caixaagch = $mc_Agch
@onready var caixaprry = $mc_Prry

@export var wants_run = false #trava de corrida do personagem

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

enum FACE {
	Right,
	Left
}

@export var state = State.IDLE #estado atual do personagem
var last_state := [State.IDLE, State.IDLE] # [0] ultimo estado (pode ser o mesmo que o atual), [1] estado anterior (não pode ser o mesmo que o atual)
var state_frames := 0 #há quanto tempo está no mesmo state

var turn_lock_time := 0.0 #trava de movimento
var parry_time_left := 0.0 #trava de parry

var stored_velocity := 0 #velocidade guardada, relevante pra momentum

var recharge := 0.0 #variável de recarga
var energy := 100.0 #variável de energia

var face = FACE.Right #Personagem inicia olhando para o lado direito
var caixape_base_pos := Vector2.ZERO 
var caixaagch_base_pos := Vector2.ZERO
var caixaprry_base_pos := Vector2.ZERO
var collision_flip_pivot_x := 0.0 #para guardar posições das caixas de colisão

func _ready(): 
	caixape_base_pos = caixape.position
	caixaagch_base_pos = caixaagch.position
	caixaprry_base_pos = caixaprry.position
	collision_flip_pivot_x = sprite.position.x
	update_face(0) #guardar posição inicial das caixas de colisão

func _physics_process(delta):
	var input_direction := Input.get_axis("left", "right")

	get_input()
	update_state(input_direction, delta)
	update_collision()

	if turn_lock_time > 0:
		turn_lock_time -= delta

	update_movement(input_direction, delta)
	update_face(input_direction)
	update_camera()
	update_energy(delta)

	move_and_slide()
	animate()
		
	if state == last_state[0]:
		state_frames += 1
	else:
		state_frames = 0
		last_state[1] = last_state[0]
		last_state[0] = state
	
	sfx.soundize(state, state_frames, delta)


func get_input():
	if Input.is_action_just_pressed("debug_1"):
		energy = 100
	
	if Input.is_action_just_pressed("b_button") and energy >= 10:
		state = State.PARRY
		parry_time_left = parry_duration
		energy -= 10
		return

	if state == State.PARRY:
		return
	
	if Input.is_action_just_pressed("a_button"): #gatilho de corrida
		if state == State.SLIDE and can_exit_slide():
			state = State.RUN #sair de um slide para uma corrida
		wants_run = true
		
	if Input.is_action_pressed("down") and state == State.RUN:
		state = State.SLIDE
		turn_lock_time = 0.3

	if Input.is_action_just_pressed("up") and is_on_floor() and energy >= 10: #pulo
		if state == State.SLIDE and not can_exit_slide():
			return
		if state == State.RUN or state == State.SLIDE:
			state = State.FRONTJUMP
		else:
			state = State.JUMP
		energy -= 10 #diminui energia ao pular
		velocity.y = jump_speed


func update_state(input_direction, delta):
	#if is_skidding(input_direction): #desativa corrida se freiar
		#wants_run = false

	if state == State.PARRY:
		parry_time_left = max(parry_time_left - delta, 0.0)
		if parry_time_left > 0.0:
			caixaprry.disabled = false
			return
		caixaprry.disabled = true
		state = State.IDLE
		
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

		if last_state[0] == State.RUN:
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

	if face == FACE.Right:
		caixape.position.x = caixape_base_pos.x
		caixaagch.position.x = caixaagch_base_pos.x
		caixaprry.position.x = caixaprry_base_pos.x
	else:
		caixape.position.x = (2.0 * collision_flip_pivot_x) - caixape_base_pos.x
		caixaagch.position.x = (2.0 * collision_flip_pivot_x) - caixaagch_base_pos.x
		caixaprry.position.x = (2.0 * collision_flip_pivot_x) - caixaprry_base_pos.x

func update_collision():
	#if state == State.PARRY:
		#caixaprry.disabled = false
	#else:
		#caixaprry.disabled = true
	
	if state == State.SLIDE:
		caixape.disabled = true
		caixaagch.disabled = false
	else:
		caixape.disabled = false
		caixaagch.disabled = true

func update_camera():
	var base = 80 if face == FACE.Right else -80
	var look = velocity.x * 0.2
	
	var target = base + look
	
	if not state == State.WALLGRAB:
		camera.offset.x = lerp(camera.offset.x, target, 0.1)
		
func update_energy(delta):
	if energy > 100:
		energy = move_toward(energy, 100, 1 * delta)
	
	if state == State.SKID and state_frames == 0:
		energy += int(recharge)
		recharge = 0
		return

	if abs(velocity.x) > walk_speed:
		recharge = move_toward(recharge, 1000, 1.5 * delta)
	elif state != State.WALLGRAB:
		recharge = move_toward(recharge, 0, 5 * delta)
	
func can_exit_slide() -> bool:
	if not is_on_floor():
		return true

	if caixape == null or caixape.shape == null:
		return true

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = caixape.shape
	params.transform = caixape.global_transform
	params.collision_mask = collision_mask
	params.exclude = [self]

	var hits := get_world_2d().direct_space_state.intersect_shape(params, 1)
	return hits.is_empty()

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
	last_state[0] = State.RUN
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
			if sprite.animation != "Skid":
				sprite.play("Skid")
				
		State.SLIDE:
			if sprite.animation != "Slide":
				sprite.play("Slide")

		State.RUN:
			if sprite.animation != "Run":
				sprite.play("Run")

		State.WALK:
			if sprite.animation != "Walk":
				sprite.play("Walk")
				
		State.PARRY:
			if sprite.animation != "Parry":
				sprite.play("Parry")

		State.IDLE:
			wants_run=false
			if sprite.animation != "Idle":
				sprite.play("Idle")
