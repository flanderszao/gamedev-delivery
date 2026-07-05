extends CharacterBody2D

enum State {
	IDLE,
	ATTACK,
	#HURT,
	#DEATH
}

@onready var sprite = $iA_Sprites
@onready var sfx = $iA_SFX
@onready var visao = $iA_Visao

@onready var player = get_tree().current_scene.get_node("Personagem")

@export var tiro : PackedScene
@export var face = -1
@export var move_speed := 60.0

var state := State.IDLE
var state_frames := 0
var state_changed := false

var idle_loop := 0
var attack_loop := 0
var vision_base_target := Vector2.ZERO

func _ready():
	vision_base_target = visao.target_position
	if face == 0:
		face = -1
	face = sign(face)
	sprite.flip_h = face > 0
	visao.target_position = Vector2(abs(vision_base_target.x) * face, vision_base_target.y)
	pass

func _physics_process(delta):
	behaviorize(delta)
	moveize(delta)
	animate(delta)
	soundize()
	if state_changed:
		state_changed = false
		state_frames = 0
	state_frames += 1
	pass
	
func behaviorize(delta):
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
				attack_loop = 40
				state_changed = true

func moveize(delta):
	if state != State.IDLE:
		return
	if visao.get_collider() == player:
		return
	position.x += face * move_speed * delta

func animate(_delta):
	match state:
		State.IDLE:
			sprite.play("IDLE")
		State.ATTACK:
			sprite.play("ATTACK")
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
	t.direction = (player.global_position - global_position).normalized()
	t.global_position = global_position
	get_tree().current_scene.add_child(t)
	t.physics.disabled = true
	await get_tree().create_timer(0.2).timeout
	t.physics.disabled = false
	t.connect("hitplayer", Callable(player, "_on_bullet_hitplayer"))
	t.connect("hitparry", Callable(player, "_on_bullet_hitparry"))
