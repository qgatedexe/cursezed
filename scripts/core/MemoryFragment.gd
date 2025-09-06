extends Area2D
class_name MemoryFragment

## Memory Fragment pickup - currency for the game
## Automatically collected when player touches it

@export var fragment_value: int = 1
@export var float_amplitude: float = 10.0
@export var float_speed: float = 2.0

@onready var sprite: ColorRect = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

var starting_position: Vector2
var time_elapsed: float = 0.0

func _ready():
	starting_position = position
	
	# Setup sprite (placeholder)
	sprite.color = Color.CYAN
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	
	# Connect pickup signal
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Floating animation
	time_elapsed += delta
	position.y = starting_position.y + sin(time_elapsed * float_speed) * float_amplitude

func _on_body_entered(body):
	"""Handle pickup by player"""
	if body is Player:
		# Notify game manager
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager:
			game_manager.add_memory_fragments(fragment_value)
		
		# Notify player directly
		body.collect_memory_fragment(fragment_value)
		
		# Visual/audio feedback could go here
		_pickup_feedback()
		
		# Remove pickup
		queue_free()

func _pickup_feedback():
	"""Provide feedback when picked up"""
	# Could add particle effects, sound, etc.
	print("Memory fragment collected!")