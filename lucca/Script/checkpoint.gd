extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	body.respawn_position = body.global_position
	$Label.text = "PUNTO SEGURO"
	$Glow.visible = true
