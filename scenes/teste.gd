extends Node2D

@onready var player = $Personagem
@onready var debug_label = $CanvasLayer/DebugLabel
@onready var debug_label2 = $CanvasLayer/DebugLabel2
@onready var gameplay_label = $CanvasLayer/GameplayLabel

@onready var area1 = $Area1
#@onready var musica = $MusicaDeFundo

func _ready():
	print("Level loaded")
	get_tree().debug_collisions_hint = true
	#musica.stream = preload("res://SoundsAssets/sf3alex.mp3")
	#musica.play()
	
func _process(_delta):
	gameplay_label.text = "ENERGY: %s\nRECHARGE: %s" % [
		int(player.energy),
		int(player.recharge)
	]
	debug_label.text = "BGM: %s\nSTATE: %s\nSFX: %s\nVELY: %s\nVELX: %s\nSTORE.VELX: %s\nRUN: %s" % [
		get_bgm_name(area1),
		get_state_name(),
		get_sfx_name(),
		player.velocity.y,
		player.velocity.x,
		player.stored_velocity,
		player.wants_run
	]
	debug_label2.text = "Press 1 for full energy\nPress 2 to add 10 energy"
	
func get_state_name():
	match player.state:
		player.State.IDLE: return "IDLE"
		player.State.WALK: return "WALK"
		player.State.RUN: return "RUN"
		player.State.SKID: return "SKID"
		player.State.JUMP: return "JUMP"
		player.State.FRONTJUMP: return "FRONTJUMP"
		player.State.WALLGRAB: return "WALLGRAB"
		player.State.SLIDE: return "SLIDE"
		player.State.PARRY: return "PARRY"
	return "UNKNOWN"
	
func get_sfx_name():
	var stream = player.sfx.stream
	if stream == null:
		return "NONE"
	return stream.resource_path.get_file()
	
func get_bgm_name(variavel):
	var stream = variavel.musica.stream
	if stream == null:
		return "NONE"
	return stream.resource_path.get_file()
