extends CanvasLayer

@onready var progress_bar: ProgressBar = $HealthBarContainer/HealthBar
@onready var label: Label = $HealthBarContainer/HealthLabel
@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	if player and player.has_method("get_stats"):
		var stats = player.get_stats()
		set_max_health(stats.max_health)
		player.health_changed.connect(_on_health_changed)
	else:
		set_max_health(100)

func set_max_health(max_health: int) -> void:
	progress_bar.max_value = max_health
	progress_bar.value = max_health
	update_label()

func set_health(health: int) -> void:
	progress_bar.value = health
	update_label()

func update_label() -> void:
	label.text = "%d / %d" % [progress_bar.value, progress_bar.max_value]

func _on_health_changed(health: int) -> void:
	set_health(health)