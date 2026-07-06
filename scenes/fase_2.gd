extends Node2D

@onready var player: Personagem = $Personagem
@onready var player_camera: Camera2D = $Personagem/mc_Camera
@onready var death_camera: Camera2D = $CameraGenerica
@onready var world_boundary: Area2D = $Mundo
@onready var musica = $MusicaDeFundo
@onready var death_sfx = preload("res://SoundsAssets/player_miss(castlevania).mp3")
@onready var vitoria_area = $Vitoria/Vitoria_Area
@onready var label_vitoria = $Controle/Control/LabelVitoria
@onready var fade = $Controle/Control/Fade
@onready var tutorial_panel = $Controle/Control/Tutorial/Tutorial_Panel
@onready var tutorial_text = $Controle/Control/Tutorial/Tutorial_Panel/Tutorial_Text
@onready var tilemaps = $TileMaps

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world_boundary.body_entered.connect(_on_world_boundary_body_entered)
	player.PlayerDeath.connect(_on_player_death)
	vitoria_area.body_entered.connect(_on_vitoria_area_body_entered)
	label_vitoria.visible = false
	fade.visible = false
	tutorial_panel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_vitoria_area_body_entered(body: Node) -> void:
	if body != player:
		return
	fade.visible = true
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.7, 1.0)
	await get_tree().create_timer(0.8).timeout
	label_vitoria.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/vitoria.tscn")
	
func _on_world_boundary_body_entered(body: Node) -> void:
	if body != player:
		return
	player._on_hitkill()

func _on_player_death() -> void:
	if player_camera != null and death_camera != null:
		death_camera.global_position = player_camera.global_position
		death_camera.offset = player_camera.offset
		death_camera.rotation = player_camera.rotation
		death_camera.zoom = player_camera.zoom
		player_camera.enabled = false
		death_camera.enabled = true
	musica.stream = death_sfx
	musica.play()
	await get_tree().create_timer(2).timeout
	get_tree().reload_current_scene()

func _on_placa_entered(body: Node, placa: Area2D) -> void:
	if body != player:
		return
	
	tutorial_panel.visible = true

	match placa.name:
		"Placa_Perigo":
			tutorial_text.text = "Pulo frontal de fé à frente!"
			
func _on_placa_exited(body: Node, placa: Area2D) -> void:
	if body != player:
		return
	tutorial_panel.visible = false
