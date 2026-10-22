extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Save the safe landing point even if the cat touches the flag mid-jump.
	body.respawn_position = global_position - Vector2(0, 3)
	$Label.text = "PUNTO SEGURO"
	$Glow.visible = true
