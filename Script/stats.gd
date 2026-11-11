class_name Stats extends Resource

@export var health: int = 100
@export var max_health: int = 100

signal health_changed(current_health: int)

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	health_changed.emit(health)

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health)

func reset() -> void:
	health = max_health
	health_changed.emit(health)
