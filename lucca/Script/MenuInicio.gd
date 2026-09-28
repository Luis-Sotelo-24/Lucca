extends Control

const LEVEL_PATH := "res://Escenas/Niveles/Nivel1.tscn"

@onready var start_button: Button = $Content/MenuCard/Margin/Stack/StartButton
@onready var title: Label = $Content/MenuCard/Margin/Stack/Title
@onready var hero: Control = $Hero
@onready var fade: ColorRect = $Fade

var is_starting := false

func _ready() -> void:
	start_button.grab_focus()
	_animate_menu()

func _animate_menu() -> void:
	var title_tween := create_tween().set_loops()
	title_tween.tween_property(title, "position:y", title.position.y - 7.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	title_tween.tween_property(title, "position:y", title.position.y, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var hero_tween := create_tween().set_loops()
	hero_tween.tween_property(hero, "position:y", hero.position.y - 10.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hero_tween.tween_property(hero, "position:y", hero.position.y, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_start_button_pressed() -> void:
	if is_starting or not ResourceLoader.exists(LEVEL_PATH):
		return

	is_starting = true
	start_button.disabled = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(get_tree().change_scene_to_file.bind(LEVEL_PATH))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_on_start_button_pressed()
