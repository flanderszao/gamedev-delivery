extends Node2D

@onready var player = $personagem
@onready var debug_label = $CanvasLayer/DebugLabel

func _ready():
	print("Level loaded")
	
func _process(delta):
	debug_label.text = "STATE: %s\nSFX: %s\nVEL: %s\nSVEL: %s\nRUN: %s" % [
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
	return "UNKNOWN"
	
func get_sfx_name():
	var stream = player.sfx.stream
	if stream == null:
		return "NONE"
	return stream.resource_path.get_file()
