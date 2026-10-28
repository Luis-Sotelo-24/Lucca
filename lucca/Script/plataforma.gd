@tool
extends StaticBody2D

@export var size := Vector2(200, 24):
	set(value):
		size = Vector2(maxf(value.x, 32.0), maxf(value.y, 12.0))
		_refresh()
@export var rock_color := Color(0.25, 0.14, 0.34):
	set(value):
		rock_color = value
		queue_redraw()
@export var rim_color := Color(0.85, 0.36, 0.54):
	set(value):
		rim_color = value
		queue_redraw()
@export var one_way := false:
	set(value):
		one_way = value
		_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	$CollisionShape2D.one_way_collision = one_way
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), rock_color)
	draw_rect(Rect2(-size / 2.0, Vector2(size.x, 6)), rim_color)
	for x in range(16, int(size.x), 40):
		var start := Vector2(x - size.x / 2.0, 7 - size.y / 2.0)
		draw_line(start, start + Vector2(10, minf(size.y - 8, 18)), rock_color.lightened(0.15), 2)
