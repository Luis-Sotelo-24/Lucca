extends Area2D

@onready var label: Label = $Label

var activated := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if activated or not body.is_in_group("player"):
		return

	activated = true
	add_to_group("activated_lever")
	$Handle.rotation_degrees = -45.0
	$Glow.visible = true
	label.text = "PALANCA ACTIVADA"
