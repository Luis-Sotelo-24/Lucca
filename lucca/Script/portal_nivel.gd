extends Area2D

@export_file("*.tscn") var target_scene: String
@export var prompt := "ENTRAR"
@export var requires_mini_boss_defeated := false

@onready var label: Label = $Label

var used := false

func _ready() -> void:
	label.text = prompt
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if used or not body.is_in_group("player") or target_scene.is_empty():
		return
	if requires_mini_boss_defeated and get_tree().get_first_node_in_group("mini_boss"):
		label.text = "DERROTA AL GUARDIAN"
		return

	used = true
	get_tree().change_scene_to_file(target_scene)
