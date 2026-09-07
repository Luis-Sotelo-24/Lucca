class_name Stats extends Resource

@export var health: int = 100
@export var max_health: int = 100

func take_damage(amount: int) -> void:
	health = max(0, health - amount)

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
