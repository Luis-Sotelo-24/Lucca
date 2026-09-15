extends CharacterBody2D

@export var chase_speed := 105.0
@export var gravity := 900.0
@export var notice_distance := 420.0
@export var capture_distance := 38.0
@export var max_health := 100
@export var invulnerable := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var speech: Label = $Speech

var health := max_health
var capturing := false
var defeated := false

func _ready() -> void:
	add_to_group("enemy")
	animated_sprite.play("Idle")

func _physics_process(delta: float) -> void:
	if defeated or capturing:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		velocity.x = 0.0
		animated_sprite.play("Idle")
		move_and_slide()
		return

	var distance := player.global_position.distance_to(global_position)
	if distance > notice_distance:
		velocity.x = 0.0
		animated_sprite.play("Idle")
		move_and_slide()
		return

	var direction: float = signf(player.global_position.x - global_position.x)
	if abs(player.global_position.x - global_position.x) <= capture_distance and abs(player.global_position.y - global_position.y) < 65.0:
		_capture_player(player)
		return

	velocity.x = direction * chase_speed
	animated_sprite.flip_h = direction < 0.0
	if animated_sprite.animation != "Walk":
		animated_sprite.play("Walk")
	move_and_slide()

func _capture_player(player: CharacterBody2D) -> void:
	capturing = true
	velocity = Vector2.ZERO
	animated_sprite.play("Strike")
	speech.visible = true
	if player.has_method("die"):
		await get_tree().create_timer(0.35).timeout
		player.die()
	await get_tree().create_timer(1.65).timeout
	speech.visible = false
	capturing = false
	animated_sprite.play("Idle")

func take_damage(amount: int) -> void:
	if defeated or invulnerable:
		return

	health -= amount
	modulate = Color(1.0, 0.5, 0.5)
	await get_tree().create_timer(0.12).timeout
	modulate = Color.WHITE
	if health <= 0:
		defeated = true
		set_physics_process(false)
		queue_free()
