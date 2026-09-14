extends Control
const LEVEL_PATH := "res://Escenas/Niveles/Nivel1.tscn"

func _ready() -> void:
	print("Menú listo, ruta: ", LEVEL_PATH)
	print("Existe nivel: ", ResourceLoader.exists(LEVEL_PATH))
	# Conexión por código por si falló por editor
	# Cambia $StartButton por tu nombre real:
	# $StartButton.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed() -> void:
	print("Botón presionado, cambiando a: ", LEVEL_PATH)
	if not ResourceLoader.exists(LEVEL_PATH):
		print("ERROR: no existe la escena, revisa Copy Path")
		return
	var err := get_tree().change_scene_to_file(LEVEL_PATH)
	print("Resultado cambio: ", err)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()
