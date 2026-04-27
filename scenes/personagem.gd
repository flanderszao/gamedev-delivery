extends CharacterBody2D

@export var walk_speed := 100 #velocidade máxima de caminhada
@export var run_speed := 600 #velocidade máxima de corrida
@export var acceleration := 200.0 #aceleração -- mudar para valor herdado?
@export var ground_friction := 400.0 #fricção de movimento -- mudar para valor herdado?
@export var skid_friction := 900.0 #fricção de freio -- mudar para valor herdado?

@export var jump_speed := -600.0 #velocidade de pulo
@export var gravity := 2500.0 #gravidade

@export var energy := 100.0 #variável de energia
@export var parry_cost := 10
@export var jump_cost := 10
@export var frontjump_cost := 10

@export var parry_duration := 0.25 #janela de parry em segundos

@export var camera_offset_x := 100 #distância da câmera para frente

@onready var sprite = $mc_Sprites
@onready var sfx = $mc_SFX
@onready var camera = $mc_Camera

@onready var caixape = $mc_DPe
@onready var caixaagch = $mc_Agch
@onready var caixaprry = $mc_Prry

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
	#FALL,
	#HURT,
	#DEATH
}

enum Second {
	THUD,
	#CHARGE,
	#PARRYHIT
}

enum FACE {
	Right,
	Left
}

@export var state = State.IDLE #estado atual do personagem
var last_state := [State.IDLE, State.IDLE] # [0] ultimo estado (pode ser o mesmo que o atual), [1] estado anterior (não pode ser o mesmo que o atual)
var state_frames := 0 #há quanto tempo está no mesmo state

var wants_run = false #trava de corrida do personagem

var turn_lock_time := 0.0 #trava de movimento
var parry_time_left := 0.0 #trava de parry

var stored_velocity := 0 #velocidade guardada, relevante pra momentum

var recharge := 0.0 #variável de recarga

var face = FACE.Right #Personagem inicia olhando para o lado direito

var caixape_base_pos := Vector2.ZERO #para guardar posições das caixas de colisão
var caixaagch_base_pos := Vector2.ZERO #para guardar posições das caixas de colisão
var caixaprry_base_pos := Vector2.ZERO #para guardar posições das caixas de colisão
var collision_flip_pivot_x := 0.0 #para guardar posições das caixas de colisão

func _ready(): 
	caixape_base_pos = caixape.position
	caixaagch_base_pos = caixaagch.position
	caixaprry_base_pos = caixaprry.position
	collision_flip_pivot_x = sprite.position.x
	update_face(0) #guardar posição inicial das caixas de colisão

func _physics_process(delta):
	var input_direction := Input.get_axis("left", "right")
	var impact_velocity_x := velocity.x

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
	sprite.animate(state)
		
	if state == last_state[0]:
		state_frames += 1
	else:
		state_frames = 0
		last_state[1] = last_state[0]
		last_state[0] = state
		
	sfx.soundize(state, state_frames, delta)
		
		#PROVAVELMENTE MUDAR A LÓGICA DO THUD!!!
	if (abs(impact_velocity_x) > 300) and is_on_wall() and is_on_floor():
		sfx.secondize(Second.THUD) #MUDAR QUANDO THUD MUDAR


func get_input():
	if Input.is_action_just_pressed("debug_1"):
		energy = 100
		
	if Input.is_action_just_pressed("debug_2"):
		energy += 10
	
	if Input.is_action_just_pressed("b_button") and do_action(State.PARRY):
		state = State.PARRY
		parry_time_left = parry_duration
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

	if Input.is_action_just_pressed("up") and is_on_floor() and (do_action(State.JUMP) or do_action(State.FRONTJUMP)): #pulo
		if state == State.SLIDE and not can_exit_slide():
			return
		if state == State.RUN or state == State.SLIDE:
			state = State.FRONTJUMP
		else:
			state = State.JUMP
		velocity.y = jump_speed


func update_state(input_direction, delta):
	if is_skidding(input_direction): #desativa corrida se freiar
		wants_run = false

	if state == State.PARRY: #FEITO POR IA --- REVISAR
		parry_time_left = max(parry_time_left - delta, 0.0)
		if parry_time_left > 0.0:
			caixaprry.disabled = false
			return
		caixaprry.disabled = true
		state = last_state[1]
		
	if state == State.SLIDE:
		if not is_on_floor() and do_action(State.FRONTJUMP):
			state = State.FRONTJUMP
			return
		if abs(velocity.x) < 50:
			if can_exit_slide():
				state = State.IDLE
			else:
				velocity.x = 50
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
		else:
			state = State.JUMP

		return

	if is_skidding(input_direction):
		if state != State.SKID:
			turn_lock_time = 0.50
		state = State.SKID
		return

	if abs(velocity.x) < 25:
		state = State.IDLE
		wants_run = false
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
		var speed_mult := 1.0

		if is_on_floor(): #FEITO POR IA ---- REVISAR
			var floor_x := float(get_floor_normal().x)
			var steep := float(abs(floor_x))
			var slope_sign := float(input_direction * floor_x)

			if slope_sign < 0: # uphill
				speed_mult -= 0.45 * steep
			elif slope_sign > 0: # downhill
				speed_mult += 0.25 * steep

		#Estou entre a ideia de mudar ou velocidade limite
		#Ou aceleração ao subir/descer rampas
		#(SIMPLESMENTE MUDAR POSIÇÃO DO SPEED_MULT ENTRE
		#O SEGUNDO OU TERCEIRO ARGUMENTO
		velocity.x = move_toward(
			velocity.x,
			input_direction * target_speed * speed_mult,
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

func update_collision(): #FEITO POR IA ---- REVISAR	
	if state == State.SLIDE:
		caixape.disabled = true
		caixaagch.disabled = false
	else:
		caixape.disabled = false
		caixaagch.disabled = true

func update_camera(): #FEITO COM IA ---- REVISAR
	var base = 80 if face == FACE.Right else -80
	var look = velocity.x * 0.2
	
	var target = base + look
	
	if not state == State.WALLGRAB:
		camera.offset.x = lerp(camera.offset.x, target, 0.1)
		
func update_energy(delta):
	if energy > 100: #lidar com over-charge (é uma mecânica)
		energy = move_toward(energy, 100, 3 * delta)
	
	if state == State.SKID and state_frames == 0: #recarregar energia
		energy += int(recharge)
		recharge = 0
		return

	if abs(velocity.x) > walk_speed: #Talvez mudar a formúla de decay
		if recharge < 10:
			recharge = move_toward(recharge, 100, 3 * delta)
		elif recharge < 30:
			recharge = move_toward(recharge, 100, 2 * delta)
		else:
			recharge = move_toward(recharge, 100, 1.5 * delta)
	elif state != State.WALLGRAB:
		recharge = move_toward(recharge, 0, 5 * delta)

func do_wall_jump(): #FEITO POR IA ---- REVISAR
	var wall_dir = get_wall_normal().x

	velocity.x = wall_dir * stored_velocity
	velocity.y = jump_speed

	state = State.FRONTJUMP
	last_state[0] = State.RUN
	sprite.flip_h = wall_dir < 0
	turn_lock_time = 0.2
	
func do_action(state) -> bool:
	if energy <= 100:
		match state:
			State.PARRY: #Declarado separado caso eu queira fazer algo com isso depois
				if energy >= 10:
					energy -= parry_cost
					return true
				else:
					return false
			State.JUMP: #Declarado separado caso eu queira fazer algo com isso depois
				if energy >= 10:
					energy -= jump_cost
					return true
				else:
					return false
			State.FRONTJUMP:
				if energy >= 10:
					energy -= frontjump_cost
					return true
				else:
					return false
			_:
				return false
	elif energy > 100:
		return true
	else:
		return false
	
func can_exit_slide() -> bool: #FEITO POR IA ---- REVISAR
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
	
func is_skidding(input_direction): #FEITO POR IA ---- REVISAR
	if is_on_floor():
		if input_direction == 0:
			return false

		if abs(velocity.x) < 50:
			return false

		return sign(input_direction) != sign(velocity.x)
