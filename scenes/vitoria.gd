extends Node2D

@onready var voltar = $voltarmenu

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
	

func _on_voltarmenu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_principal.tscn")
