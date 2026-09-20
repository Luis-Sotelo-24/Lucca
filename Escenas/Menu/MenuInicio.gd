extends Control

const LEVEL_PATH := "res://Escenas/Niveles/Nivel1.tscn"


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_PATH)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()
