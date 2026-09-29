extends Node

signal enemy_killed(total: int)

var kills := 0
var needed_to_win := 2

func _ready():
	print("GameManager listo, necesitas ", needed_to_win, " kills")

func on_enemy_killed():
	kills += 1
	print("Kill #", kills, "/", needed_to_win)
	enemy_killed.emit(kills)
	if kills >= needed_to_win:
		print("¡Meta alcanzada!")
