extends Node2D

@onready var player = $Personagem
@onready var debug_label = $CanvasLayer/DebugLabel
@onready var gameplay_label = $CanvasLayer/GameplayLabel
@onready var musica = $MusicaDeFundo

func _ready():
	print("Level loaded")
	get_tree().debug_collisions_hint = true
	musica.stream = preload("res://SoundsAssets/sf3alex.mp3")
	musica.play()
	
func _process(delta):
	gameplay_label.text = "ENERGY: %s\nRECHARGE: %s" % [
		player.energy,
		player.recharge
	]
	debug_label.text = "STATE: %s\nSFX: %s\nVEL: %s\nSTORE.VEL: %s\nRUN: %s" % [
		get_state_name(),
		get_sfx_name(),
		player.velocity.x,
		player.stored_velocity,
		player.wants_run
	]
	
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
	return "UNKNOWN"
	
func get_sfx_name():
	var stream = player.sfx.stream
	if stream == null:
		return "NONE"
	return stream.resource_path.get_file()
