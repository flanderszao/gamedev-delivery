extends Control

@onready var player = get_tree().current_scene.get_node("Personagem")
@onready var energy = $Energy
@onready var recharge = $Recharge

func _ready() -> void:
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	energy.value = player.energy
	recharge.value = player.recharge
	pass
