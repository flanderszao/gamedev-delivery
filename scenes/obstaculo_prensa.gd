extends StaticBody2D

@onready var gfx = $p_GFX
@onready var phy = $p_BOD
@onready var kil = $p_KIL
@onready var sfx = $p_SFX
var s_sfx = preload("res://SoundsAssets/impactMetal_004.ogg")
@onready var player = get_tree().current_scene.get_node("Personagem")


var pressing_down := false

var original_size: Vector2
var original_pos: Vector2
var original_kil_pos: Vector2

signal hitkill


func _ready():
	original_size = phy.shape.size
	original_pos = phy.position
	kil.body_entered.connect(_on_kil_body_entered)
	kil.monitoring = false
	hitkill.connect(Callable(player, "_on_hitkill"))
	sfx.stream = s_sfx
	loop_press()


func loop_press():
	while true:
		await get_tree().create_timer(2).timeout
		await press()


func press():
	var frame_tex = gfx.sprite_frames.get_frame_texture("defaultA", 0)
	var target_size = frame_tex.get_size() * gfx.scale

	var extra_height = target_size.y - original_size.y
	var target_pos = original_pos + Vector2(0, extra_height / 2.0)

	# DOWN
	pressing_down = true
	kil.monitoring = true
	gfx.play("defaultA")

	var tween = create_tween()
	tween.parallel().tween_property(phy.shape, "size", target_size, 0.15)
	tween.parallel().tween_property(phy, "position", target_pos, 0.15)

	await gfx.animation_finished

	# UP
	pressing_down = false
	kil.monitoring = false
	gfx.play("defaultB")
	sfx.play()

	var tween2 = create_tween()
	tween2.parallel().tween_property(phy.shape, "size", original_size, 0.15)
	tween2.parallel().tween_property(phy, "position", original_pos, 0.15)

	await gfx.animation_finished


func _on_kil_body_entered(body):
	if pressing_down and body == player:
		hitkill.emit()
		print("hitkill")
