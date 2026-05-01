extends Node2D

@onready var musica = $MusicaDeFundo
@onready var comecar = $CanvasLayer/ComecarJogo
@onready var sair = $CanvasLayer/Sair

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if comecar.button_pressed:
		get_tree().change_scene_to_file("res://scenes/teste.tscn")
	if sair.button_pressed:
		get_tree().quit()
	pass
