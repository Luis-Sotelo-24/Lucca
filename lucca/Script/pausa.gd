extends CanvasLayer

@onready var overlay: Control = $Overlay

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()

func _set_paused(value: bool) -> void:
	get_tree().paused = value
	overlay.visible = value

func _on_continue_pressed() -> void:
	_set_paused(false)

func _on_restart_pressed() -> void:
	_set_paused(false)
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	_set_paused(false)
	get_tree().change_scene_to_file("res://Escenas/Menu/MenuInicio.tscn")
