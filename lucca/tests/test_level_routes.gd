extends SceneTree

# Run from the repository: godot --headless --path lucca --script res://tests/test_level_routes.gd --fixed-fps 60
# Exercise the real player controller and collision geometry, at walking speed.
# Enemies are paused only for traversal; combat and the Chef are tested separately.
const FOOD_SCRIPT = preload("res://Script/comida.gd")
const HAZARD_SCRIPT = preload("res://Script/peligro.gd")
const CHECKPOINT_SCRIPT = preload("res://Script/checkpoint.gd")
const ROUTES := {
	1: [Vector2(-2180, -326), Vector2(-1960, -326), Vector2(-1800, -326),
		Vector2(-1700, -403), Vector2(-1590, -463), Vector2(-1480, -513), Vector2(-1310, -563),
		Vector2(-1110, -454), Vector2(-960, -403), Vector2(-790, -338), Vector2(-600, -263),
		Vector2(-500, -166), Vector2(-300, -166),
		Vector2(-180, -238), Vector2(100, -310), Vector2(275, -310),
		Vector2(570, -198), Vector2(770, -198), Vector2(900, -143),
		Vector2(1140, -78), Vector2(1550, -78), Vector2(1990, -78), Vector2(2130, -78)],
	2: [Vector2(-680, 161), Vector2(-510, 68), Vector2(-405, 68), Vector2(-130, -2),
		Vector2(0, 161), Vector2(60, 161), Vector2(395, 53), Vector2(690, -12),
		Vector2(1060, 161), Vector2(1370, 161), Vector2(1640, 81), Vector2(1940, 9),
		Vector2(2260, -63), Vector2(2570, 9), Vector2(2860, 81), Vector2(3150, 161),
		Vector2(3450, 81), Vector2(3740, 9), Vector2(4020, -63), Vector2(4300, 9),
		Vector2(4590, 81), Vector2(4800, 161), Vector2(5030, 161)],
	3: [Vector2(-680, 161), Vector2(-490, 161), Vector2(-360, 51), Vector2(-100, 161),
		Vector2(160, 161), Vector2(250, 51), Vector2(330, 161), Vector2(720, 161),
		Vector2(1100, 161), Vector2(1470, 81), Vector2(1680, 161), Vector2(1850, 49),
		Vector2(2230, 81), Vector2(2450, 161), Vector2(2700, 49), Vector2(3080, 81),
		Vector2(3290, 161), Vector2(3480, 49), Vector2(3880, 81), Vector2(4040, 161),
		Vector2(4250, 49), Vector2(4530, 161), Vector2(4770, 161)]
}

var failures: Array[String] = []
var player: CharacterBody2D
var hazards: Array[Node2D] = []

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	for number in [1, 2, 3]:
		await test_route(number)
	await test_forest_recovery()
	# Fixed-FPS simulations outpace the audio thread; release playback before exit.
	var audio := root.get_node("AudioDirector")
	audio.set_process(false)
	audio.music_playback = null
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	OS.delay_msec(100)
	await tick(2)
	if failures.is_empty():
		print("PASS: all level routes, recovery paths, pickups, checkpoints, camera bounds and exits")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func tick(count := 1) -> void:
	for _frame in range(count):
		await physics_frame
		await process_frame

func release_inputs() -> void:
	for action in ["Izquierda", "Derecha", "Saltar", "Correr", "Ataque"]:
		Input.action_release(action)

func test_route(number: int) -> void:
	var path := "res://Escenas/Niveles/Nivel%d.tscn" % number
	var level := load(path).instantiate() as Node2D
	root.add_child(level)
	current_scene = level
	player = level.get_node("Gato")
	var initial_food := 0
	var dogs := 0
	hazards.clear()
	for child in level.get_children():
		if child.is_in_group("enemy"):
			child.set_physics_process(false)
			if child.scene_file_path.ends_with("Enemigo1.tscn"):
				dogs += 1
		if child.get_script() == FOOD_SCRIPT:
			initial_food += 1
		if child.get_script() == HAZARD_SCRIPT:
			hazards.append(child)
	check(initial_food >= 18, "Level %d must have at least 18 foods" % number)
	check(dogs >= 7, "Level %d must have at least seven dogs" % number)
	var portal: Area2D = level.get_node({1: "PortalNivel", 2: "PortalCocina", 3: "Salida"}[number])
	check(portal.position.x - player.position.x > 4400, "Level %d route is too short" % number)
	var camera := player.get_node("Camera2D") as Camera2D
	check(camera.limit_left <= player.position.x and camera.limit_right > portal.position.x + 100,
		"Level %d camera must include the full route" % number)
	await tick(30)
	check(player.is_on_floor(), "Level %d spawn must land on solid ground" % number)
	var reached_exit := true
	for point: Vector2 in ROUTES[number]:
		if not await walk_to(point):
			check(false, "Level %d cannot reach %s; stopped at %s" % [number, point, player.position])
			reached_exit = false
			break
	if reached_exit:
		var remaining_food := 0
		for child in level.get_children():
			if child.get_script() == FOOD_SCRIPT:
				remaining_food += 1
		check(remaining_food == 0, "Level %d route must collect every food" % number)
		check(player.super_strength_ready, "Level %d food must charge super strength" % number)
		check(player.respawn_position.x > 1000, "Level %d must activate the later checkpoints" % number)
		if number == 3:
			check(level.get_node("Barrera").opened, "Both kitchen levers must open the exit")
		var destination: String = portal.target_scene
		Input.action_press("Derecha")
		for _frame in range(120):
			await tick()
			if current_scene != level:
				break
		await tick(2)
		check(current_scene != null and current_scene != level and current_scene.scene_file_path == destination,
			"Level %d portal must load its destination" % number)
		print("Level %d: traversed at walking speed, %d/%d foods, %d dogs, exit checked" %
			[number, initial_food - remaining_food, initial_food, dogs])
	release_inputs()
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	await tick(90)

func walk_to(target: Vector2) -> bool:
	var jumped := false
	for frame in range(360):
		Input.action_release("Saltar")
		var dx := target.x - player.position.x
		if absf(dx) < 6 and absf(target.y - player.position.y) < 8 and player.is_on_floor():
			release_inputs()
			return true
		Input.action_release("Izquierda")
		Input.action_release("Derecha")
		var direction := signf(dx)
		if absf(dx) > 3:
			Input.action_press("Derecha" if direction > 0 else "Izquierda")
		if player.is_on_floor():
			jumped = false
			var rise := player.position.y - target.y
			var ray := PhysicsRayQueryParameters2D.create(
				player.position + Vector2(direction * 32, -5),
				player.position + Vector2(direction * 32, 24), 1)
			var ledge := player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
			var fire_ahead := false
			for hazard in hazards:
				var distance := (hazard.position.x - player.position.x) * direction
				if distance > 0 and distance < 85 and absf(hazard.position.y - player.position.y) < 25:
					fire_ahead = true
			if (rise > 12 and absf(dx) < 190) or (ledge and absf(dx) > 40) or player.is_on_wall() or fire_ahead:
				Input.action_press("Saltar")
				jumped = true
		elif jumped and player.jump_count == 1 and player.velocity.y >= -30:
			Input.action_press("Saltar")
		var previous_position := player.position
		await tick()
		if player.position.distance_to(previous_position) > 80:
			check(false, "The route must not require a death/respawn")
			break
		if player.position.y > player.fall_death_y - 20:
			break
	release_inputs()
	print("Unreached target: ", target, " position=", player.position, " floor=", player.is_on_floor(), " wall=", player.is_on_wall(), " velocity=", player.velocity)
	for index in player.get_slide_collision_count():
		var collision := player.get_slide_collision(index)
		print("Contact ", collision.get_collider(), " at ", collision.get_position(), " normal ", collision.get_normal())
	return false

func test_forest_recovery() -> void:
	var level := load("res://Escenas/Niveles/Nivel1.tscn").instantiate() as Node2D
	root.add_child(level)
	current_scene = level
	player = level.get_node("Gato")
	for enemy in get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
	hazards.clear()
	# Falling into either lower basin must leave a playable way back up.
	for path in [
		[Vector2(-1660, -112), Vector2(-1570, -193), Vector2(-1440, -273),
			Vector2(-1340, -353), Vector2(-1230, -433), Vector2(-1110, -454)],
		[Vector2(-970, -147), Vector2(-690, -166), Vector2(-500, -166)]]:
		player.position = path[0]
		player.velocity = Vector2.ZERO
		await tick(30)
		for point: Vector2 in path.slice(1):
			check(await walk_to(point), "Forest lower path must recover to %s" % point)
	release_inputs()
	level.queue_free()
	current_scene = null
	await tick(60)
