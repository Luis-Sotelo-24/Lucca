extends CharacterBody2D
@export var speed: float = 200.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 900.0
@export var respawn_position: Vector2
@export var fall_death_y: float = 400
@export var damage: int = 50
@export var attack_duration: float = 0.45
@export var max_jumps := 2
@export var safe_fall := 200.0 
@export var damage_per_px := 0.10


@onready var animated_sprite: AnimatedSprite2D = $Jugador
@onready var animated_sprite_ataque: AnimatedSprite2D = $Area2D/Ataque
@onready var attack_area: Area2D = $Area2D
@onready var stats: Stats = Stats.new()
@onready var camera: Camera2D = $Camera2D

signal health_changed(health: int)

enum State { SENTADO, CAMINAR, CORRER, SALTAR, CAER, ATACAR, MORIR }
var current_state: State = State.SENTADO
var ataque: bool = false
var can_attack := true
var base_attack_x := 0.0
var jump_count := 0
var was_on_floor := true
var min_y_in_air := 0.0

func _ready() -> void:
	add_to_group("player")
	stats.health = stats.max_health
	base_attack_x = abs(attack_area.position.x)
	if base_attack_x < 1.0:
		base_attack_x = 30.0
	animated_sprite_ataque.visible = false
	respawn_position=Vector2(position.x,position.y)
	min_y_in_air = global_position.y
	was_on_floor = true
	setup_camera_limits()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_floor() and not ataque:
		jump_count = 0

	if Input.is_action_just_pressed("Saltar") and not ataque:
		if jump_count < max_jumps:
			velocity.y = jump_velocity
			jump_count += 1
			# fuerza anim de salto en el segundo salto
			if not is_on_floor():
				current_state = State.SALTAR
				play_once(animated_sprite, "Saltar")
	
	if Input.is_action_just_pressed("Ataque") and can_attack and is_on_floor():
		do_attack()
	
	var direction := Input.get_axis("Izquierda", "Derecha")
	
	# Bloqueado mientras ataca
	if ataque:
		velocity.x = 0
	else:
		var cur_speed := 350.0 if Input.is_action_pressed("Correr") else 200.0
		speed = cur_speed
		velocity.x = direction * cur_speed
	
	var floor_before := is_on_floor()
	move_and_slide()

	if is_on_floor():
		if not floor_before:
			var fall_height := global_position.y - min_y_in_air
			if fall_height > safe_fall and not ataque:
				var dmg := int((fall_height - safe_fall) * damage_per_px)
				take_damage(dmg)
		min_y_in_air = global_position.y
		was_on_floor = true
	else:
		if was_on_floor:
			min_y_in_air = global_position.y
		else:
			min_y_in_air = min(min_y_in_air, global_position.y)
		was_on_floor = false

	if global_position.y > fall_death_y:        
		take_damage(stats.max_health)
	
	update_state_movement(direction)
	update_animation(direction)
	update_camera_limits()

func do_attack() -> void:
	if not can_attack or ataque:
		return
	can_attack = false
	ataque = true
	velocity.x = 0
	animated_sprite_ataque.visible = true
	# No hacemos play aquí, lo hace update_animation una sola vez
	
	await get_tree().create_timer(0.2).timeout
	# Daño al enemigo que esté en el área
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage)
			break
	
	await get_tree().create_timer(attack_duration).timeout
	ataque = false
	animated_sprite_ataque.visible = false
	await get_tree().create_timer(0.2).timeout
	can_attack = true

# --- resto igual que lo tuyo ---
func setup_camera_limits() -> void:
	var background = get_tree().get_first_node_in_group("background")
	if background and background.has_node("Sprite2D"):
		var sprite = background.get_node("Sprite2D")
		var texture = sprite.texture
		if texture:
			var bg_rect = Rect2(sprite.global_position, texture.get_size() * sprite.scale)
			var camera_half = camera.get_viewport_rect().size * 0.5 / camera.zoom
			var inset = camera_half / 3.0
			camera.limit_left = bg_rect.position.x + inset.x
			camera.limit_top = bg_rect.position.y + inset.y
			camera.limit_right = bg_rect.end.x - inset.x
			camera.limit_bottom = bg_rect.end.y - inset.y

func update_camera_limits() -> void:
	if camera.limit_right > camera.limit_left and camera.limit_bottom > camera.limit_top:
		var camera_pos = camera.global_position
		var camera_half = camera.get_viewport_rect().size * 0.5 / camera.zoom
		camera_pos.x = clamp(camera_pos.x, camera.limit_left + camera_half.x, camera.limit_right - camera_half.x)
		camera_pos.y = clamp(camera_pos.y, camera.limit_top + camera_half.y, camera.limit_bottom - camera_half.y)
		camera.global_position = camera_pos

func get_stats() -> Stats:
	return stats

func take_damage(amount: int) -> void:
	stats.health -= amount
	emit_signal("health_changed", stats.health)
	modulate = Color(1.0, 0.35, 0.35)
	await get_tree().create_timer(0.12).timeout
	if stats.health <= 0:
		die()
		return
	modulate = Color.WHITE

func heal(amount: int) -> void:
	if stats.health <= 0:
		return
	stats.health = min(stats.health + amount, stats.max_health)
	health_changed.emit(stats.health)
	modulate = Color(0.4, 1.0, 0.4)
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE

func die() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	stats.health = stats.max_health
	ataque = false
	can_attack = true
	animated_sprite_ataque.visible = false
	health_changed.emit(stats.health)
	was_on_floor = true
	min_y_in_air = respawn_position.y

func update_state_movement(direction: float) -> void:
	current_state = State.SENTADO
	if stats.health <= 0:
		current_state = State.MORIR
	elif ataque:
		current_state = State.ATACAR
	elif not is_on_floor():
		current_state = State.SALTAR if velocity.y < 0 else State.CAER
	else:
		if direction != 0:
			current_state = State.CORRER if Input.is_action_pressed("Correr") else State.CAMINAR
			

func play_once(sprite: AnimatedSprite2D, anim_name: String) -> void:
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)

func update_animation(direction: float) -> void:
	match current_state:
		State.SENTADO:
			play_once(animated_sprite, "Esperar")
		State.CAMINAR:
			play_once(animated_sprite, "Caminata Derecha")
		State.SALTAR:
			play_once(animated_sprite, "Saltar")
		State.CAER:
			play_once(animated_sprite, "Caer")
		State.CORRER:
			play_once(animated_sprite, "Correr Derecha")
		State.ATACAR:
			play_once(animated_sprite, "Ataque")
			play_once(animated_sprite_ataque, "Garra 1")
		State.MORIR:
			play_once(animated_sprite, "Eliminado")

	# Flip cuerpo + área de ataque para pegar a ambos lados
	if direction < 0:
		animated_sprite.flip_h = true
		animated_sprite_ataque.flip_h = true
		attack_area.position.x = -base_attack_x
	elif direction > 0:
		animated_sprite.flip_h = false
		animated_sprite_ataque.flip_h = false
		attack_area.position.x = base_attack_x
