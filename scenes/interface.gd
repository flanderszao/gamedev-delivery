extends Control

@onready var player = get_tree().current_scene.get_node("Personagem")
@onready var energy = $Energy
@onready var energylabel = $Energy/EnergyLabel
@onready var overchargelabel = $Energy/OverchargeLabel
@onready var recharge = $Recharge
@onready var rechargelabel = $Recharge/RechargeLabel

func _ready() -> void:
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	energy.value = player.energy
	energylabel.text = "%s" % int(player.energy)
	overchargelabel.text = "OVER" if player.energy > 100 else ""
	recharge.value = player.recharge
	rechargelabel.text = "%s" % int(player.recharge)
	pass
