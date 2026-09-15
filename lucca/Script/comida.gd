extends Area2D
@export var heal_amount := 30
@export var amplitude := 6.0
@export var speed := 2.0

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
var base_y := 0.0
var time := 0.0

func _ready():
	base_y = spr.position.y
	spr.play("Pescado")
	body_entered.connect(_on_body_entered)

func _process(delta):
	time += delta * speed
	spr.position.y = base_y + sin(time * 2.0) * amplitude

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("heal"):
			body.heal(heal_amount)
		elif body.has_method("get_stats"):
			var st = body.get_stats()
			st.health = min(st.health + heal_amount, st.max_health)
			body.emit_signal("health_changed", st.health)
		queue_free()
