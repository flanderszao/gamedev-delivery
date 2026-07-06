extends CharacterBody2D

enum State {
	IDLE,
	ATTACK,
	#HURT,
	#DEATH
}

@onready var sprite = $iE_Sprites
@onready var sfx = $iE_SFX
@onready var visao = $iE_Visao
var s_sfx = preload("res://SoundsAssets/laserSmall_004.ogg")

@onready var player = get_tree().current_scene.get_node("Personagem")

@export var tiro : PackedScene
@export var face = -1

@export var gravity := 2500.0 #gravidade

var state := State.IDLE
var state_frames := 0
var state_changed := false

var idle_loop := 0
var attack_loop := 0

func _ready():
	sfx.stream = s_sfx
	pass

func _physics_process(delta):
	move_and_slide()
	behaviorize(delta)
	animate(delta)
	soundize()
	if state_changed:
		state_changed = false
		state_frames = 0
	state_frames += 1
	pass
	
func behaviorize(delta):
	if not is_on_floor(): 
		velocity.y += gravity
	match state:
		State.IDLE:
			attack_loop -= delta
			if visao.get_collider() == player and attack_loop <= 0:
				state = State.ATTACK
				state_changed = true
				pass
		State.ATTACK:
			if state_frames == 5:
				shoot()
			if state_frames >= 20:
				state = State.IDLE
				attack_loop = 80
				state_changed = true
			#bullet behavior

func animate(delta):
	match state:
		State.IDLE:
			idle_loop-= delta
			if idle_loop <= 0:
				sprite.play("idle")
				idle_loop = 20
		State.ATTACK:
			sprite.play("attack")
	pass
	
func soundize():
	match state:
		State.ATTACK:
			#add sfx for attack
			pass
		_:
			pass
	pass

func shoot():
	var t = tiro.instantiate()
	t.x = face
	add_child(t)
	sfx.play()
	t.physics.disabled = true
	await get_tree().create_timer(0.15).timeout
	t.physics.disabled = false
	t.connect("hitplayer", Callable(player, "_on_bullet_hitplayer"))
	t.connect("hitparry", Callable(player, "_on_bullet_hitparry"))
