extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK }

@export var patrol_speed := 60.0
@export var chase_speed := 120.0
@export var damage := 10
@export var gravity := 900.0
@export var max_hp_enemy := 50

var state: State = State.PATROL
var patrol_dir := -1
var player: Node2D = null
var player_in_attack_range := false
var can_attack := true
var is_attacking := false
var attack_base_x := 0
var turn_cooldown := false
var hp_enemy: int
var dead := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var cooldown: Timer = $AttackCooldown
@onready var ray_suelo: RayCast2D = $RayCast2D

func _ready():
	if velocity.x > 0:
		attack_base_x = abs(attack_area.position.x)
	else:
		attack_area.position.x=attack_area.position.x-2*attack_base_x
	add_to_group("enemy") # ponlo también por editor en Global
	hp_enemy = max_hp_enemy


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	match state:
		State.PATROL:
			velocity.x = patrol_dir * patrol_speed
			if anim.animation != "Caminar":
				anim.play("Caminar")
			_flip(patrol_dir)
			# Mueve el raycast al frente según dirección
			ray_suelo.position.x = 15 * patrol_dir
			
			if not turn_cooldown:
				# Pared o borde (ya no hay suelo adelante)
				if is_on_wall() or (is_on_floor() and not ray_suelo.is_colliding()):
					patrol_dir *= -1
					turn_cooldown = true
					# Pequeño empuje para salir del borde y no vibrar
					velocity.x = patrol_dir * patrol_speed
					await get_tree().create_timer(0.3).timeout
					turn_cooldown = false

		State.CHASE:
			if player == null:
				state = State.PATROL
			elif player_in_attack_range and can_attack and not is_attacking:
				print(str(player_in_attack_range) + str(can_attack))
				do_attack()
				
			else:
				var dir_to_player = sign(player.global_position.x - global_position.x)
				if dir_to_player == 0:
					dir_to_player = 1
				velocity.x = dir_to_player * chase_speed
				if not is_attacking:
					anim.play("Correr")
				_flip(dir_to_player)

		State.ATTACK:
			velocity.x = 0
			# No hacemos nada aquí, esperamos a que termine la animación
			# Si se traba, el Timer lo rescata en _on_attack_cooldown_timeout

	move_and_slide()

func _flip(dir: int):
	if dir < 0:
		anim.flip_h = true
		attack_area.position.x = -abs(attack_area.position.x)
	elif dir > 0:
		anim.flip_h = false
		attack_area.position.x = abs(attack_area.position.x)

func do_attack():
	if not can_attack or is_attacking:
		return
	can_attack = false
	is_attacking = true
	state = State.ATTACK
	velocity.x = 0
	anim.play("Atacar")
	cooldown.start()
	
	await get_tree().create_timer(0.3).timeout
	# Pega aunque la animación siga
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage)
			print("Golpe! can_attack=", can_attack)
			break

func take_damage(amount: int):
	if dead:
		return
	hp_enemy -= amount
	print("Enemigo HP: ", hp_enemy)
	# parpadeo rápido para feedback
	anim.play("Daño")
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	if hp_enemy <= 0:
		die()

func die():
	dead = true
	print("Enemigo muerto")
	# detiene todo para que no siga pegando
	set_physics_process(false)
	anim.play("Morir") 
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		state = State.CHASE

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null
		player_in_attack_range = false
		state = State.PATROL

func _on_attack_area_body_entered(body):
	print("El cuerpo está dentro del area de ataque")
	if body.is_in_group("player"):
		player_in_attack_range = true
		if state != State.ATTACK:
			state = State.CHASE

func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_attack_range = false

func _on_attack_cooldown_timeout():
	can_attack = true
	print("Cooldown listo, puede volver a pegar")
	# Rescate: si se quedó trabado en ATTACK, libéralo
	if is_attacking:
		is_attacking = false
		if player != null:
			state = State.CHASE
		else:
			state = State.PATROL

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "Atacar":
		is_attacking = false
		if player != null:
			state = State.CHASE
		else:
			state = State.PATROL
