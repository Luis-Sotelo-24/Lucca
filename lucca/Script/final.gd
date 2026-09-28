extends Control

const MENU_PATH := "res://Escenas/Menu/MenuInicio.tscn"

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file(MENU_PATH)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_on_return_pressed()
