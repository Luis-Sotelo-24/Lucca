extends Node2D

@export var camera_bounds := Rect2(-880, -590, 6200, 810)

func _ready() -> void:
	# The playable area can span several background sprites.
	var camera: Camera2D = $Gato/Camera2D
	camera.limit_left = int(camera_bounds.position.x)
	camera.limit_top = int(camera_bounds.position.y)
	camera.limit_right = int(camera_bounds.end.x)
	camera.limit_bottom = int(camera_bounds.end.y)
