extends CharacterBody2D


var velocidad = 150
@onready var player = $".."
@onready var animacion = $AnimatedSprite2D


func _physics_process(delta):
	if Input.is_action_pressed("Correr"):
		velocidad = 300
	else: 
		velocidad = 150
	
	if Input.is_action_pressed("Izquierda"):
		player.position.x -= velocidad*delta
		if Input.is_action_pressed("Correr"):
			animacion.play("Correr Izquierda")
		else: 
			animacion.play("Caminata Izquierda")
	elif Input.is_action_pressed("Derecha"):
		player.position.x += velocidad*delta
		if Input.is_action_pressed("Correr"):
			animacion.play("Correr Derecha")
		else: 
			animacion.play("Caminata Derecha")
	elif Input.is_action_pressed("Arriba"):
		player.position.y -= velocidad*delta
		if Input.is_action_pressed("Correr"):
			animacion.play("Correr Arriba")
		else: 
			animacion.play("Caminata Arriba")
	elif Input.is_action_pressed("Abajo"):
		player.position.y += velocidad*delta
		if Input.is_action_pressed("Correr"):
			animacion.play("Correr Abajo")
		else: 
			animacion.play("Caminata Abajo")
	else:
		animacion.play("Esperar")

	move_and_slide()
