extends Area2D

@export var player_path: NodePath = ^"../Personagem"
@export var musica_path: NodePath = ^"../MusicaDeFundo"
@export var bgm_area1: AudioStream = preload("res://SoundsAssets/sf3alex.mp3")

@onready var player: Node2D = get_node_or_null(player_path)
@onready var musica: AudioStreamPlayer = get_node_or_null(musica_path)
@onready var area_camera: Camera2D = $CameraArea

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body != player:
		return

	_set_player_camera(false)
	area_camera.enabled = true

	if bgm_area1 != null and musica != null and musica.stream != bgm_area1:
		musica.stream = bgm_area1
		musica.play()

func _on_body_exited(body):
	if body != player:
		return

	area_camera.enabled = false
	_set_player_camera(true)

func _set_player_camera(enabled: bool):
	if player == null:
		return

	var player_camera = player.get("camera")
	if player_camera is Camera2D:
		player_camera.enabled = enabled
