extends SceneTree

# godot --headless --path lucca --script res://tests/test_movement.gd --fixed-fps 60
# Load gameplay scenes after autoloads exist, not while the CLI script compiles.
const CAT = "res://Escenas/Lucca/Gato.tscn"
const PLATFORM = "res://Escenas/Objetos/Plataforma.tscn"
const DOG = "res://Escenas/Enemigos/Enemigo1.tscn"
const CHEF = "res://Escenas/Enemigos/Chef.tscn"
const FOOD = "res://Escenas/Consumibles/Comida.tscn"
const CHECKPOINT = "res://Escenas/Objetos/Checkpoint.tscn"

var failures: Array[String] = []
var world: Node2D
var player: CharacterBody2D

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	await test_double_jump_and_buffer()
	await test_ledge_grace()
	await test_air_attack()
	await test_food_and_combat()
	await test_checkpoint()
	await test_chef_obstacle()
	await test_locked_exit()
	await dispose_world()
	var audio := root.get_node("AudioDirector")
	audio.set_process(false)
	audio.music_playback = null
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	OS.delay_msec(100)
	await tick(2)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: double jump, input buffer, ledge grace, air attack, food, combat, respawn, Chef and locked exit")
	quit(0 if failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func tick(count := 1) -> void:
	for _frame in range(count):
		await physics_frame
		await process_frame

func release_inputs() -> void:
	for action in ["Derecha", "Izquierda", "Saltar", "Ataque", "Supervelocidad"]:
		Input.action_release(action)

func press(action: String) -> void:
	Input.action_press(action)
	await tick()
	Input.action_release(action)

func dispose_world() -> void:
	release_inputs()
	if is_instance_valid(world):
		world.queue_free()
	world = null
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	await tick(60)

func setup_world(width := 1200.0) -> void:
	await dispose_world()
	world = Node2D.new()
	root.add_child(world)
	var floor_body = load(PLATFORM).instantiate()
	floor_body.size = Vector2(width, 40)
	floor_body.position = Vector2(0, 120)
	world.add_child(floor_body)
	player = load(CAT).instantiate()
	player.position = Vector2(0, 70)
	world.add_child(player)
	await tick(30)
	check(player.is_on_floor(), "Fixture must start on the floor")

func test_double_jump_and_buffer() -> void:
	await setup_world()
	var start_y := player.position.y
	await press("Saltar")
	for _frame in range(60):
		await tick()
		if player.velocity.y >= -30:
			break
	check(start_y - player.position.y > 90, "Single jump must clear a 90px step")
	await press("Saltar")
	await tick(2)
	var velocity_before := player.velocity.y
	await press("Saltar")
	check(player.velocity.y > velocity_before, "A third press must not grant another air jump")
	var highest_y := player.position.y
	for _frame in range(120):
		await tick()
		highest_y = minf(highest_y, player.position.y)
		if player.velocity.y > 0 and player.position.y > start_y - 12:
			break
	check(start_y - highest_y > 185, "Double jump must reach the higher platforms")
	await press("Saltar")
	await tick(3)
	check(player.velocity.y < -300, "A press just before landing must start the next jump")
	check(player.stats.health == 100, "A normal double jump must not cause fall damage")

func walk_off_ledge() -> void:
	Input.action_press("Derecha")
	for _frame in range(90):
		await tick()
		if not player.is_on_floor():
			break
	Input.action_release("Derecha")

func test_ledge_grace() -> void:
	await setup_world(180)
	await walk_off_ledge()
	await tick(2)
	await press("Saltar")
	check(player.velocity.y < -300 and player.jump_count == 1, "Jump just after a ledge must keep the air jump available")
	await setup_world(180)
	await walk_off_ledge()
	await tick(9)
	await press("Saltar")
	check(player.velocity.y < -300 and player.jump_count == 2, "Late ledge recovery must use the remaining air jump")
	await tick(2)
	var velocity_before := player.velocity.y
	await press("Saltar")
	check(player.velocity.y > velocity_before, "Walking off a ledge must not grant two extra jumps")

func test_air_attack() -> void:
	await setup_world()
	Input.action_press("Derecha")
	await press("Saltar")
	await tick(5)
	await press("Ataque")
	var start_x := player.position.x
	await tick(10)
	check(player.position.x - start_x > 30, "Attacking in the air must preserve horizontal control")
	await press("Saltar")
	check(player.velocity.y < -300, "Air attack must not swallow the second jump")

func test_food_and_combat() -> void:
	await setup_world()
	player.stats.take_damage(60)
	for _index in range(3):
		var food = load(FOOD).instantiate()
		food.food_type = 1
		food.position = player.position - Vector2(0, 15)
		world.add_child(food)
		await tick(12)
		check(not is_instance_valid(food), "Touching an apple must consume it")
	check(player.stats.health == 100 and player.super_strength_ready, "Apples must heal and charge strength")
	var dog = load(DOG).instantiate()
	dog.max_hp_enemy = 150
	dog.position = Vector2(55, 86)
	world.add_child(dog)
	dog.set_physics_process(false)
	await tick(3)
	await press("Supervelocidad")
	await tick(60)
	check(not is_instance_valid(dog), "Charged L attack must defeat a dog in range")
	check(not player.super_strength_ready and player.food_count == 0, "Strength must consume its three-food charge")
	dog = load(DOG).instantiate()
	dog.position = Vector2(55, 86)
	world.add_child(dog)
	dog.set_physics_process(false)
	await tick(3)
	await press("Ataque")
	await tick(60)
	check(not is_instance_valid(dog), "J must still defeat a normal dog")

func test_checkpoint() -> void:
	await setup_world()
	var checkpoint = load(CHECKPOINT).instantiate()
	checkpoint.position = Vector2(120, 98)
	world.add_child(checkpoint)
	Input.action_press("Derecha")
	await press("Saltar")
	await tick(35)
	Input.action_release("Derecha")
	for _frame in range(90):
		await tick()
		if checkpoint.get_node("Glow").visible:
			break
	check(checkpoint.get_node("Glow").visible, "An airborne cat must activate a checkpoint")
	check(player.respawn_position == Vector2(120, 95), "Checkpoint must store the safe flag position")
	player.die()
	await tick(30)
	check(player.is_on_floor() and absf(player.position.x - 120) < 1, "Respawn must land safely beside the checkpoint")
	await press("Saltar")
	check(player.velocity.y < -300, "Respawn must restore the jump")

func test_chef_obstacle() -> void:
	await setup_world()
	player.position = Vector2(450, 102)
	player.set_physics_process(false)
	var counter = load(PLATFORM).instantiate()
	counter.size = Vector2(105, 112)
	counter.position = Vector2(180, 44)
	world.add_child(counter)
	var chef = load(CHEF).instantiate()
	chef.position = Vector2(0, 100)
	chef.notice_distance = 6500
	world.add_child(chef)
	for _frame in range(300):
		await tick()
		if chef.position.x > 300:
			break
	check(chef.position.x > 300, "Chef must clear kitchen counters instead of getting stuck")

func test_locked_exit() -> void:
	await dispose_world()
	world = load("res://Escenas/Niveles/Nivel3.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Gato")
	for enemy in get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
	var portal := world.get_node("Salida")
	player.position = portal.position
	await tick(15)
	check(current_scene == world and not portal.used, "Kitchen exit must stay locked without levers")
	player.position = world.get_node("PalancaUno").position
	await tick(15)
	player.position = portal.position
	await tick(15)
	check(current_scene == world and not portal.used, "One lever must not unlock the kitchen exit")
