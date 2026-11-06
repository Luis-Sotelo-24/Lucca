@tool
extends Node2D
## Painted scenery only: every surface here is decorative and has no collision.
## The actual counters and platforms remain separate level objects.

const DARK := Color("382d32")
const WALL := Color("b89b7d")
const TILE := Color("d2bba0")
const GROUT := Color("ac9078")
const CABINET := Color("735449")
const CABINET_LIGHT := Color("947060")
const METAL := Color("777e7c")
const METAL_LIGHT := Color("aeb4a8")
const SHADOW := Color("51484a")
const GOLD := Color("d6a567")

func _draw() -> void:
	# An enclosed, warmly lit kitchen stretches behind the complete level.
	draw_rect(Rect2(-1020, -590, 6240, 754), WALL)
	draw_rect(Rect2(-1020, -590, 6240, 196), Color("54464b"))
	draw_rect(Rect2(-1020, -410, 6240, 20), Color("3e3539"))
	draw_rect(Rect2(-1020, -390, 6240, 20), Color("debc91"))
	draw_rect(Rect2(-1020, -370, 6240, 290), TILE)
	# Grout lines give the backsplash a small-scale tiled pattern.
	for y in range(-370, -79, 38):
		draw_line(Vector2(-1020, y), Vector2(5220, y), GROUT, 2.0)
	for row in range(8):
		var y: int = -370 + row * 38
		for x in range(-1100 + (row % 2) * 48, 5280, 96):
			draw_line(Vector2(x, y), Vector2(x, min(y + 38, -80)), GROUT, 2.0)
	# Base cabinets sit far behind the playable obstacles.
	draw_rect(Rect2(-1020, -80, 6240, 244), Color("72584d"))
	draw_rect(Rect2(-1020, -91, 6240, 17), DARK)
	draw_rect(Rect2(-1020, -100, 6240, 14), Color("a89c88"))
	draw_rect(Rect2(-1020, -100, 6240, 4), Color("d6c5a6"))
	for x in range(-1000, 5260, 160):
		_cabinet_door(x, -61, 146, 195, false)
	# Large upper cabinets alternate with recognizable kitchen fixtures.
	for base in range(-980, 5250, 1040):
		_upper_cabinets(base, -345)
		_shelf(base + 520, -288)
		_range_hood(base + 765, -352)
		_counter_details(base)
		_ceiling_lamp(base + 170)
		_ceiling_lamp(base + 690)
	# A few landmarks keep the long route from looking like one repeated tile.
	_window(320, -348)
	_window(2440, -348)
	_fridge(1070, -324)
	_fridge(4030, -324)
	_hanging_pans(-710, -312)
	_hanging_pans(1800, -312)
	_hanging_pans(3550, -312)
	# Soft trim separates the floor from the background.
	draw_rect(Rect2(-1020, 148, 6240, 16), Color("51413b"))
	draw_rect(Rect2(-1020, 148, 6240, 3), Color("a7886c"))

func _cabinet_door(x: float, y: float, w: float, h: float, upper: bool) -> void:
	draw_rect(Rect2(x, y, w, h), DARK)
	draw_rect(Rect2(x + 4, y + 4, w - 8, h - 8), CABINET)
	draw_rect(Rect2(x + 12, y + 12, w - 24, h - 24), CABINET_LIGHT)
	draw_rect(Rect2(x + 17, y + 17, w - 34, h - 34), CABINET)
	var handle_x := x + w - 20 if upper else x + w / 2.0
	var handle_y := y + h * 0.55 if upper else y + 24
	draw_rect(Rect2(handle_x - 9, handle_y, 18, 4), GOLD)
	draw_rect(Rect2(handle_x - 8, handle_y + 4, 16, 2), SHADOW)

func _upper_cabinets(x: float, y: float) -> void:
	draw_rect(Rect2(x - 7, y - 8, 414, 146), Color("47373a"))
	for i in range(3):
		_cabinet_door(x + i * 134, y, 130, 128, true)
	draw_rect(Rect2(x - 8, y - 12, 416, 9), Color("9e7964"))
	draw_rect(Rect2(x - 8, y + 128, 416, 8), Color("48383a"))

func _shelf(x: float, y: float) -> void:
	# Shelf with jars, crockery and a cutting board.
	draw_rect(Rect2(x - 12, y + 60, 212, 10), DARK)
	draw_rect(Rect2(x - 12, y + 56, 212, 7), CABINET_LIGHT)
	for i in range(3):
		var jar_x := x + i * 42
		draw_rect(Rect2(jar_x, y + 19, 28, 37), Color("d1c5a8"))
		draw_rect(Rect2(jar_x + 3, y + 25, 22, 28), [Color("9c6b4f"), Color("a88d5b"), Color("758474")][i])
		draw_rect(Rect2(jar_x - 2, y + 14, 32, 6), DARK)
	draw_rect(Rect2(x + 135, y + 16, 43, 40), Color("966e4d"))
	draw_rect(Rect2(x + 141, y + 22, 31, 28), Color("c49a6b"))
	draw_circle(Vector2(x + 156, y + 10), 4, DARK)

func _range_hood(x: float, y: float) -> void:
	draw_rect(Rect2(x + 54, y - 32, 58, 83), SHADOW)
	draw_rect(Rect2(x + 60, y - 32, 46, 83), METAL)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 54, y + 34), Vector2(x + 112, y + 34), Vector2(x + 160, y + 86), Vector2(x + 6, y + 86)]), DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 58, y + 38), Vector2(x + 108, y + 38), Vector2(x + 148, y + 80), Vector2(x + 17, y + 80)]), METAL)
	draw_rect(Rect2(x + 8, y + 86, 150, 9), METAL_LIGHT)
	draw_rect(Rect2(x + 30, y + 101, 106, 5), DARK)
	for i in range(4):
		draw_circle(Vector2(x + 42 + i * 27, y + 103), 3, GOLD)

func _counter_details(x: float) -> void:
	# Bottles and pots sit on the distant worktop, below the movement area.
	for i in range(3):
		var bx := x + 475 + i * 27
		draw_rect(Rect2(bx + 5, -130, 13, 30), Color("667a65"))
		draw_rect(Rect2(bx + 9, -137, 5, 9), Color("8f795b"))
		draw_rect(Rect2(bx + 7, -121, 9, 10), Color("c7b68e"))
	var px := x + 825
	draw_rect(Rect2(px - 4, -125, 65, 5), DARK)
	draw_rect(Rect2(px, -122, 58, 22), Color("555b5a"))
	draw_rect(Rect2(px + 4, -119, 50, 14), METAL)
	draw_rect(Rect2(px + 20, -130, 18, 5), METAL_LIGHT)

func _ceiling_lamp(x: float) -> void:
	draw_line(Vector2(x, -590), Vector2(x, -474), Color("2f2b30"), 6.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 35, -474), Vector2(x + 35, -474), Vector2(x + 53, -450), Vector2(x - 53, -450)]), DARK)
	draw_rect(Rect2(x - 39, -451, 78, 5), Color("f1cf91"))
	draw_colored_polygon(PackedVector2Array([Vector2(x - 30, -445), Vector2(x + 30, -445), Vector2(x + 98, -377), Vector2(x - 98, -377)]), Color(1.0, 0.79, 0.50, 0.07))

func _window(x: float, y: float) -> void:
	draw_rect(Rect2(x - 8, y - 8, 206, 158), DARK)
	draw_rect(Rect2(x, y, 190, 142), Color("647f82"))
	draw_rect(Rect2(x + 6, y + 6, 178, 130), Color("83a0a0"))
	# Stylized muted glass reflects the interior lighting.
	draw_colored_polygon(PackedVector2Array([Vector2(x + 8, y + 88), Vector2(x + 70, y + 6), Vector2(x + 100, y + 6), Vector2(x + 12, y + 132)]), Color(0.8, 0.88, 0.78, 0.14))
	draw_rect(Rect2(x + 91, y, 8, 142), DARK)
	draw_rect(Rect2(x, y + 66, 190, 8), DARK)
	draw_rect(Rect2(x - 12, y + 142, 214, 12), Color("c1a183"))

func _fridge(x: float, y: float) -> void:
	draw_rect(Rect2(x - 5, y - 5, 172, 312), DARK)
	draw_rect(Rect2(x, y, 162, 302), Color("88938d"))
	draw_rect(Rect2(x + 8, y + 8, 146, 94), Color("a6b0a4"))
	draw_rect(Rect2(x + 8, y + 109, 146, 184), Color("a6b0a4"))
	draw_rect(Rect2(x + 18, y + 20, 5, 68), Color("e2ddc5"))
	draw_rect(Rect2(x + 18, y + 126, 5, 70), Color("e2ddc5"))
	draw_rect(Rect2(x + 98, y + 136, 35, 33), Color("e6c780"))
	draw_line(Vector2(x + 103, y + 146), Vector2(x + 127, y + 146), Color("9b806b"), 2)
	draw_line(Vector2(x + 103, y + 153), Vector2(x + 124, y + 153), Color("9b806b"), 2)
	draw_circle(Vector2(x + 115, y + 138), 3, Color("b66451"))

func _hanging_pans(x: float, y: float) -> void:
	draw_rect(Rect2(x, y, 215, 7), DARK)
	for i in range(3):
		var px := x + 35 + i * 70
		draw_line(Vector2(px, y + 6), Vector2(px, y + 37), DARK, 5)
		draw_circle(Vector2(px, y + 62), 28, DARK)
		draw_circle(Vector2(px, y + 62), 22, Color("707371"))
		draw_circle(Vector2(px, y + 62), 15, Color("858783"))
