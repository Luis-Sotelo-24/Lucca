extends CanvasLayer

@onready var player = get_tree().get_first_node_in_group("player")
@onready var health_bar: TextureProgressBar = $TextureProgressBar

func _ready() -> void:
	health_bar.max_value = player.stats.max_health
	health_bar.value = player.stats.health
	player.health_changed.connect(_on_health_changed)

func _on_health_changed(health: int) -> void:
	health_bar.value = health
