extends Control
class_name UIManager

## UI Manager for Ashes of Reverie
## Handles all UI elements including health bar, memory fragments, and level info

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label
@onready var memory_label: Label = $MemoryFragments/Label
@onready var level_label: Label = $LevelInfo/Label

func _ready():
	# Setup initial UI state
	setup_ui()

func setup_ui():
	"""Initialize UI elements"""
	# Health bar setup
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = 100
		health_bar.value = 100
	
	update_health(100, 100)
	update_memory_fragments(0)
	update_level_name("Ashen Courtyard - Level 1")

func update_health(current: int, maximum: int):
	"""Update health display"""
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
		
		# Color coding for health bar
		if current <= maximum * 0.25:
			health_bar.modulate = Color.RED
		elif current <= maximum * 0.5:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.GREEN
	
	if health_label:
		health_label.text = str(current) + " / " + str(maximum)

func update_memory_fragments(amount: int):
	"""Update memory fragments display"""
	if memory_label:
		memory_label.text = "Memory Fragments: " + str(amount)

func update_level_name(level_name: String):
	"""Update level name display"""
	if level_label:
		level_label.text = level_name

func show_damage_number(position: Vector2, damage: int):
	"""Show floating damage number at position"""
	var damage_label = Label.new()
	damage_label.text = "-" + str(damage)
	damage_label.modulate = Color.RED
	damage_label.position = position
	add_child(damage_label)
	
	# Animate damage number
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position", position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(damage_label.queue_free)

func show_memory_pickup(position: Vector2, amount: int):
	"""Show memory fragment pickup notification"""
	var pickup_label = Label.new()
	pickup_label.text = "+" + str(amount) + " Memory"
	pickup_label.modulate = Color.CYAN
	pickup_label.position = position
	add_child(pickup_label)
	
	# Animate pickup notification
	var tween = create_tween()
	tween.parallel().tween_property(pickup_label, "position", position + Vector2(0, -30), 0.8)
	tween.parallel().tween_property(pickup_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(pickup_label.queue_free)