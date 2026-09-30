extends CharacterBody2D
@export var speed: float = 200.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 900.0
@export var respawn_position: Vector2
@export var fall_death_y: float = 400
@export var damage: int = 50
@export var air_attack_damage: int = 75
@export var attack_duration: float = 0.45
@export var max_jumps := 2
@export var safe_fall := 200.0 
@export var damage_per_px := 0.10
@export var super_jump_velocity := -600.0
@export var super_speed_multiplier := 2.0
@export var super_speed_duration := 3.0


@onready var animated_sprite: AnimatedSprite2D = $Jugador
@onready var animated_sprite_ataque: AnimatedSprite2D = $Area2D/Ataque
@onready var attack_area: Area2D = $Area2D
@onready var stats: Stats = Stats.new()
@onready var camera: Camera2D = $Camera2D
@onready var canvas_mod: CanvasModulate = get_tree().get_first_node_in_group("canvas_mod")

enum State { SENTADO, CAMINAR, CORRER, SALTAR, CAER, ATACAR, MORIR }
enum Power { NONE, SUPER_JUMP, SUPER_SPEED }
var current_state: State = State.SENTADO
var ataque: bool = false
var air_attacking := false
var can_attack := true
var facing_direction := 1
var base_attack_x := 0.0
var jump_count := 0
var was_on_floor := true
var min_y_in_air := 0.0
var stored_power: Power = Power.NONE
var super_speed_active := false
var power_message_version := 0
var food_count := 0
var super_strength_ready := false
var power_label: Label

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
	_setup_power_label()
	GameManager.enemy_killed.connect(_on_enemy_killed)
	if canvas_mod:
		var c := canvas_mod.color
		self_modulate = Color(1.0 / c.r, 1.0 / c.g, 1.0 / c.b, 1.0)
		print("Compensando oscuridad: ", self_modulate)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_floor() and not ataque:
		jump_count = 0
	
	if Input.is_action_just_pressed("Saltar") and not ataque:
		if jump_count < max_jumps:
			velocity.y = jump_velocity
			jump_count += 1
			AudioDirector.play_jump()
	
	if Input.is_action_just_pressed("Ataque") and can_attack:
		if is_on_floor():
			do_attack()
		elif not ataque:
			do_air_attack()
	if Input.is_action_just_pressed("Supervelocidad") and super_strength_ready and not ataque:
		do_super_strength()
	
	var direction := Input.get_axis("Izquierda", "Derecha")
	if direction != 0:
		facing_direction = 1 if direction > 0 else -1
	
	if ataque:
		velocity.x = facing_direction if air_attacking else 0
	else:
		var cur_speed := 350.0 if Input.is_action_pressed("Correr") else 200.0
		if super_speed_active:
			cur_speed *= super_speed_multiplier
		speed = cur_speed
		velocity.x = direction * cur_speed
	
	var floor_before := is_on_floor()
	move_and_slide()

	if is_on_floor():
		if not floor_before:
			var fall_height := global_position.y - min_y_in_air
			if fall_height > safe_fall and not ataque:
				var dmg := int((fall_height - safe_fall) * damage_per_px)
				take_damage(dmg, true)
		min_y_in_air = global_position.y
		was_on_floor = true
	else:
		if was_on_floor:
			min_y_in_air = global_position.y
		else:
			min_y_in_air = min(min_y_in_air, global_position.y)
		was_on_floor = false

	if global_position.y > fall_death_y:        
		take_damage(stats.max_health, true)
	
	update_state_movement(direction)
	update_animation(direction)

func do_attack() -> void:
	if not can_attack or ataque:
		return
	can_attack = false
	ataque = true
	air_attacking = false
	velocity.x = 0
	AudioDirector.play_cat_attack()
	animated_sprite_ataque.visible = true
	# No hacemos play aquí, lo hace update_animation una sola vez
	
	await get_tree().create_timer(0.2).timeout
	_apply_attack_damage(damage)
	
	await get_tree().create_timer(attack_duration).timeout
	ataque = false
	animated_sprite_ataque.visible = false
	await get_tree().create_timer(0.2).timeout
	can_attack = true

func do_air_attack() -> void:
	can_attack = false
	ataque = true
	air_attacking = true
	AudioDirector.play_cat_attack()
	animated_sprite_ataque.visible = true

	await get_tree().create_timer(0.12).timeout
	_apply_attack_damage(air_attack_damage)

	await get_tree().create_timer(attack_duration).timeout
	air_attacking = false
	ataque = false
	animated_sprite_ataque.visible = false
	await get_tree().create_timer(0.2).timeout
	can_attack = true

func do_super_strength() -> void:
	if not can_attack or ataque:
		return
	if not damage_first_enemy(damage * 3):
		_update_power_label("ACERCATE A UN ENEMIGO Y PRESIONA L")
		return

	super_strength_ready = false
	food_count = 0
	can_attack = false
	ataque = true
	air_attacking = false
	velocity.x = 0
	AudioDirector.play_super_strength()
	animated_sprite_ataque.visible = true
	_update_power_label()
	await get_tree().create_timer(attack_duration).timeout
	ataque = false
	animated_sprite_ataque.visible = false
	await get_tree().create_timer(0.2).timeout
	can_attack = true

func _apply_attack_damage(base_damage: int) -> void:
	damage_first_enemy(base_damage)

func damage_first_enemy(amount: int) -> bool:
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(amount)
			return true
	return false

# --- resto igual que lo tuyo ---
func setup_camera_limits() -> void:
	var background = get_tree().get_first_node_in_group("background")
	if background and background.has_node("Sprite2D"):
		var sprite = background.get_node("Sprite2D")
		var texture = sprite.texture
		if texture:
			var bg_rect = Rect2(sprite.global_position, texture.get_size() * sprite.scale)
			camera.limit_left = bg_rect.position.x
			camera.limit_top = bg_rect.position.y
			camera.limit_right = bg_rect.end.x
			camera.limit_bottom = bg_rect.end.y

func get_stats() -> Stats:
	return stats

func take_damage(amount: int, is_fall_damage := false) -> void:
	clear_power()
	stats.take_damage(amount)
	if is_fall_damage:
		AudioDirector.play_fall_damage()
	modulate = Color(1.0, 0.35, 0.35)
	await get_tree().create_timer(0.12).timeout
	if stats.health <= 0:
		die()
		return
	modulate = Color.WHITE

func heal(amount: int) -> void:
	if stats.health <= 0:
		return
	stats.heal(amount)
	modulate = Color(0.4, 1.0, 0.4)
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE

func die() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	stats.reset()
	ataque = false
	air_attacking = false
	can_attack = true
	clear_power()
	animated_sprite_ataque.visible = false
	was_on_floor = true
	min_y_in_air = respawn_position.y

func clear_power() -> void:
	stored_power = Power.NONE
	super_speed_active = false

func collect_food() -> void:
	if super_strength_ready:
		_update_power_label()
		return
	food_count += 1
	if food_count >= 3:
		food_count = 3
		super_strength_ready = true
		_update_power_label("SUPERFUERZA LISTA: PRESIONA L")
		return
	_update_power_label()

func _setup_power_label() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 3
	add_child(hud)
	power_label = Label.new()
	power_label.position = Vector2(34, 108)
	power_label.add_theme_font_size_override("font_size", 16)
	power_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	hud.add_child(power_label)
	_update_power_label("J: ATACAR  |  COMIDAS: 0/3")

func _update_power_label(message := "") -> void:
	if message.is_empty():
		message = "COMIDAS: %d/3" % food_count
	power_label.text = message

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
		
func _on_enemy_killed(total: int) -> void:
	if total >= GameManager.needed_to_win:
		print("¡Se desbloquea la puerta!")
		
