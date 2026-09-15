extends Node2D

@export var required_levers := 2

@onready var collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var label: Label = $Label

var opened := false

func _process(_delta: float) -> void:
	if opened or get_tree().get_nodes_in_group("activated_lever").size() < required_levers:
		return

	opened = true
	collision.set_deferred("disabled", true)
	$Bars.visible = false
	$Glow.visible = true
	label.text = "SALIDA ABIERTA"
