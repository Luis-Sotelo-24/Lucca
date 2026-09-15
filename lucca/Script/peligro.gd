extends Area2D

@export var damage := 25

var hit_bodies: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body in hit_bodies or not body.is_in_group("player"):
		return

	hit_bodies.append(body)
	if body.has_method("take_damage"):
		body.take_damage(damage)

func _on_body_exited(body: Node2D) -> void:
	hit_bodies.erase(body)
