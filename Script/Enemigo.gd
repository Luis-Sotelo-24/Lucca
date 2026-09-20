extends CharacterBody2D

@export var speed: float = 100.0
@export var max_health: int = 100
@export var patrol_distance: float = 100.0
@export var gravity: float = 900.0

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var ray_cast_2d_2: RayCast2D = $RayCast2D2
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: Stats = Stats.new()

signal health_changed(health: int)

var direction = 1
var health: int = 100
var start_x: float

func _ready() -> void:
	add_to_group("enemy")
	stats.max_health = max_health
	stats.health = max_health
	health = max_health
	start_x = global_position.x

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity.y += gravity * delta
		
	_check_edges()
	velocity.x = direction * speed
	move_and_slide()
	
	if abs(global_position.x - start_x) >= patrol_distance:
		_turn_around()
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		print("Is colliding"+collider.name)
	move_and_slide()

func _check_edges() -> void:
	var ray
	if direction > 0:
		ray = ray_cast_2d 
	else: 
		ray=ray_cast_2d_2
	ray.force_raycast_update()
	if ray.is_colliding():
		_turn_around()

func _turn_around() -> void:
	direction *= -1
	animatedSprite.flip_h = direction < 0
	start_x = global_position.x

func take_damage(amount: int) -> void:
	stats.take_damage(amount)
	health = stats.health
	health_changed.emit(health)
	if stats.health <= 0:
		die()

func die() -> void:
	queue_free()
