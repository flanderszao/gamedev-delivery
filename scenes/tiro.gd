extends Area2D

@onready var sprites = $t_GFX
@onready var physics: CollisionShape2D = $t_PHY

var speed = 150
@export var x = 1
@export var y = null
var player_position: Vector2
var direction := Vector2.ZERO

signal hitplayer
signal hitparry

var has_collided := false

func _ready():
	sprites.play("BULLET")
	connect("body_entered", Callable(self, "on_tiro_entered_body"))
	connect("area_entered", Callable(self, "on_tiro_entered_area"))

func _physics_process(delta):
	if has_collided:
		return
	if direction != Vector2.ZERO:
		position += direction * speed * delta
	elif y != null && player_position != null:
		var homing_direction = (player_position - global_position).normalized()
		position += homing_direction * speed * delta
	else:
		position += Vector2(x, 0) * speed * delta

func on_tiro_collided_with(parry):
	if has_collided:
		return
	has_collided = true
	if parry: sprites.play("DISPERSE_PRY") 
	else: sprites.play("DISPERSE_HIT")
	physics.set_deferred("disabled", true)
	await sprites.animation_finished
	queue_free()

func on_tiro_entered_body(body):
	if body.is_in_group("Personagem Corpo"):
		emit_signal("hitplayer")
	on_tiro_collided_with(false)

func on_tiro_entered_area(area):
	if area.is_in_group("Personagem Parry"):
		emit_signal("hitparry")
	on_tiro_collided_with(true)
