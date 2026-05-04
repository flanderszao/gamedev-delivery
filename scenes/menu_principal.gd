extends Node2D

@onready var musica = $MusicaDeFundo
@onready var comecar = $CanvasLayer/ComecarJogo
@onready var ajuda = $CanvasLayer/ComoJogar
@onready var sair = $CanvasLayer/Sair
@onready var painel = $CanvasLayer/ComoJogar/Painel
@onready var painelfec = $CanvasLayer/ComoJogar/Painel/Fechar

func _ready() -> void:
	painel.visible = false
	pass


func _process(_delta) -> void:
	if painel.visible and painelfec.button_pressed:
		painel.visible = false
	if ajuda.button_pressed:
		painel.visible = true
		pass
	if comecar.button_pressed:
		get_tree().change_scene_to_file("res://scenes/teste.tscn")
	if sair.button_pressed:
		get_tree().quit()
	pass
