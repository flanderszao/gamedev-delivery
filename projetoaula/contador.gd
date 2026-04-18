extends Node2D

var total:= 0.0
const SPEED : int = 100

func _ready() -> void:
	update_label(total)
	
func _physics_process(delta: float) -> void:
	total += delta
	update_label(total)
	if Input.is_action_just_pressed("ui_right"):
		# Move enquanto a tecla estiver pressionada
		position.x += SPEED * delta

func update_label(value) -> void:
	$Label.text  = str(value)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		print("Right arrow!")
	


func _on_timer_timeout() -> void:
	print("Disparou")
	$Label.visible = !$Label.visible
