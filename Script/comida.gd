extends Area2D

enum FoodType { FISH, APPLE, MEAT }

@export var heal_amount := 30
@export var amplitude := 6.0
@export var speed := 2.0
@export var food_type: FoodType = FoodType.FISH

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
var base_y := 0.0
var time := 0.0

func _ready():
	base_y = spr.position.y
	spr.visible = false
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta):
	time += delta * speed
	spr.position.y = base_y + sin(time * 2.0) * amplitude
	queue_redraw()

func _draw() -> void:
	var offset := Vector2(0, sin(time * 2.0) * amplitude)
	match food_type:
		FoodType.FISH:
			draw_circle(offset, 10.0, Color(0.35, 0.7, 0.95))
			draw_colored_polygon(PackedVector2Array([offset + Vector2(-8, 0), offset + Vector2(-18, -8), offset + Vector2(-18, 8)]), Color(0.2, 0.5, 0.85))
			draw_circle(offset + Vector2(4, -3), 1.5, Color.WHITE)
		FoodType.APPLE:
			draw_circle(offset, 11.0, Color(0.95, 0.25, 0.2))
			draw_circle(offset + Vector2(-5, -2), 7.0, Color(0.95, 0.25, 0.2))
			draw_line(offset + Vector2(1, -10), offset + Vector2(4, -17), Color(0.3, 0.18, 0.08), 2.0)
			draw_circle(offset + Vector2(7, -14), 4.0, Color(0.3, 0.8, 0.3))
		FoodType.MEAT:
			draw_circle(offset, 12.0, Color(0.75, 0.23, 0.16))
			draw_circle(offset + Vector2(-4, -4), 6.0, Color(0.95, 0.5, 0.35))
			draw_circle(offset + Vector2(6, 5), 4.0, Color(0.95, 0.5, 0.35))

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("heal"):
			body.heal(heal_amount)
		elif body.has_method("get_stats"):
			var st = body.get_stats()
			st.health = min(st.health + heal_amount, st.max_health)
			body.emit_signal("health_changed", st.health)
		if body.has_method("collect_food"):
			body.collect_food()
		queue_free()
