extends CanvasLayer

func _ready() -> void:
	$TextureProgressBar.value = 100


func _on_gato_health_changed(health: int) -> void:
	$TextureProgressBar.value = health
