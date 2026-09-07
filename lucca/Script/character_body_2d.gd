extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 900.0
@export var respawn_position: Vector2 = Vector2(-886, 214)
@export var fall_death_y: float = 400

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: Stats = Stats.new()
@onready var camera: Camera2D = $Camera2D

signal health_changed(health: int)

enum State { SENTADO, CAMINAR, CORRER, SALTAR, CAER, ATACAR, MORIR }
var current_state: State = State.SENTADO
var is_attacking: bool = false

func _ready() -> void:
	add_to_group("player")
	stats.health = stats.max_health
	setup_camera_limits()

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta

	# Salto (solo una vez por pulsación, solo desde el suelo)
	if Input.is_action_just_pressed("Saltar") and is_on_floor():
		velocity.y = jump_velocity
	
	# Ataque
	if Input.is_action_just_pressed("Atacar") and not is_attacking:
		attack()
	
	# Movimiento horizontal
	var direction := Input.get_axis("Izquierda", "Derecha")
	velocity.x = direction * speed
	
	if Input.is_action_pressed("Correr"):
		speed = 350
	else:
		speed = 200.0
	
	move_and_slide()

	# Verificar caída al vacío
	if global_position.y > fall_death_y:		
		take_damage(stats.max_health)  # Muerte instantánea
	
	update_state(direction)
	update_animation()
	update_camera_limits()

func setup_camera_limits() -> void:
	var background = get_tree().get_first_node_in_group("background")
	if background and background.has_node("Sprite2D"):
		var sprite = background.get_node("Sprite2D")
		var texture = sprite.texture
		if texture:
			var bg_rect = Rect2(sprite.global_position, texture.get_size() * sprite.scale)
			var camera_half = camera.get_viewport_rect().size * 0.5 / camera.zoom
			
			# Inset de 1/3 del viewport en cada lado
			var inset = camera_half / 3.0
			
			camera.limit_left = bg_rect.position.x + inset.x
			camera.limit_top = bg_rect.position.y + inset.y
			camera.limit_right = bg_rect.end.x - inset.x
			camera.limit_bottom = bg_rect.end.y - inset.y
			
			print("Camera limits set: ", camera.limit_left, ", ", camera.limit_top, " to ", camera.limit_right, ", ", camera.limit_bottom)
			print("Inset applied: ", inset)


func update_camera_limits() -> void:
	if camera.limit_right > camera.limit_left and camera.limit_bottom > camera.limit_top:
		var camera_pos = camera.global_position
		var camera_half = camera.get_viewport_rect().size * 0.5 / camera.zoom
		camera_pos.x = clamp(camera_pos.x, camera.limit_left + camera_half.x, camera.limit_right - camera_half.x)
		camera_pos.y = clamp(camera_pos.y, camera.limit_top + camera_half.y, camera.limit_bottom - camera_half.y)
		camera.global_position = camera_pos

func attack() -> void:
	is_attacking = true
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

func get_stats() -> Stats:
	return stats

func take_damage(amount: int) -> void:
	stats.health-=amount
	emit_signal("health_changed",stats.health)
	print("Player recibió daño: ", amount, " | Vida actual: ", stats.health, "/", stats.max_health)
	if stats.health <= 0:
		die()

func die() -> void:
	print("Player murió - Respawn en: ", respawn_position)
	global_position = respawn_position
	velocity = Vector2.ZERO
	stats.health = stats.max_health
	health_changed.emit(stats.health)
	print("Respawn completado. Vida restaurada: ", stats.health)

func update_state(direction: float) -> void:
	if stats.health == 0:
		current_state = State.MORIR
	elif not is_on_floor():
		if velocity.y < 0:
			current_state = State.SALTAR
		else:
			current_state = State.CAER
	else:
		if direction != 0:
			current_state = State.CAMINAR
			if speed > 200:
				current_state = State.CORRER
		else:
			current_state = State.SENTADO

func update_animation() -> void:
	match current_state:
		State.SENTADO:
			animated_sprite.play("Caminata Derecha")
		State.CAMINAR:
			animated_sprite.play("Caminata Derecha")
		State.SALTAR:
			animated_sprite.play("Saltar")
		State.CAER:
			animated_sprite.play("Caer")
		State.CORRER:
			animated_sprite.play("Correr Derecha")
		State.ATACAR:
			animated_sprite.play("Caminata Derecha")
		State.MORIR:
			animated_sprite.play("Eliminado")

	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false
