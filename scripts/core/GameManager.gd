extends Node
class_name GameManager

## Main game manager that handles overall game state and progression
## Manages room transitions, player state, and game systems

signal player_died
signal level_completed
signal memory_fragments_changed(amount: int)

@export var starting_biome: String = "Forgotten Forest"
@export var max_health: int = 100

var current_level: int = 1
var memory_fragments: int = 0
var player_max_health: int = 100
var player_current_health: int = 100
var current_room: Node2D
var player: Player

@onready var room_generator: RoomGenerator = $RoomGenerator
@onready var ui_manager: UIManager = $UIManager
@onready var camera_controller: CameraController = get_node("../CameraController")
@onready var biome_controller: BiomeController = $BiomeController

func _ready():
	# Connect signals
	player_died.connect(_on_player_died)
	level_completed.connect(_on_level_completed)
	memory_fragments_changed.connect(_on_memory_fragments_changed)
	
	# Initialize game
	_initialize_game()

func _initialize_game():
	"""Initialize a new game session"""
	current_level = 1
	memory_fragments = 0
	player_current_health = player_max_health
	
	# Generate first level
	_generate_level()

func _generate_level():
	"""Generate a new level with procedural rooms"""
	print("Generating level: ", current_level, " - ", starting_biome)
	
	# Clear existing rooms if any
	if current_room:
		current_room.queue_free()
	
	# Generate new room layout
	var room_data = room_generator.generate_level(starting_biome, current_level)
	current_room = room_data.starting_room
	
	# Add room to scene
	add_child(current_room)
	
	# Spawn player in starting room
	_spawn_player()
	
	# Update UI
	ui_manager.update_level_name(starting_biome + " - Level " + str(current_level))

func _spawn_player():
	"""Spawn player in the current room"""
	if not player:
		# Load player scene
		var player_scene = preload("res://scenes/player/Player.tscn")
		player = player_scene.instantiate()
		add_child(player)
		
		# Connect player signals
		player.health_changed.connect(_on_player_health_changed)
		player.died.connect(_on_player_died)
	
	# Set player position to room spawn point
	if current_room and current_room.spawn_point:
		player.global_position = current_room.spawn_point.global_position
	
	# Reset player health
	player.current_health = player_current_health
	
	# Set camera to follow player
	if camera_controller:
		camera_controller.set_target(player)

func add_memory_fragments(amount: int):
	"""Add memory fragments to player collection"""
	memory_fragments += amount
	memory_fragments_changed.emit(memory_fragments)

func damage_player(amount: int):
	"""Damage the player"""
	if player:
		player.take_damage(amount)

func _on_player_health_changed(new_health: int):
	"""Handle player health changes"""
	player_current_health = new_health
	ui_manager.update_health(new_health, player_max_health)

func _on_player_died():
	"""Handle player death - restart level"""
	print("Player died - restarting level")
	player_current_health = player_max_health
	memory_fragments = max(0, memory_fragments - 10) # Lose some fragments on death
	_generate_level()

func _on_level_completed():
	"""Handle level completion - advance to next level"""
	print("Level completed - advancing to next level")
	current_level += 1
	_generate_level()

func _on_memory_fragments_changed(amount: int):
	"""Update UI when memory fragments change"""
	ui_manager.update_memory_fragments(amount)

func get_player_position() -> Vector2:
	"""Get current player position"""
	if player:
		return player.global_position
	return Vector2.ZERO

func handle_room_transition(exit_data: Dictionary):
	"""Handle room transition requests"""
	print("Room transition requested: ", exit_data)
	# This would integrate with the biome controller to handle transitions
	if biome_controller:
		# For now, just advance to next level
		_on_level_completed()

func transition_to_secret_area(destination: String):
	"""Handle transition to secret areas (like mirage doors)"""
	print("Transitioning to secret area: ", destination)
	# This could load special secret rooms or areas

func reveal_story_beat(story_beat: String):
	"""Handle story revelation from memory shards"""
	print("Story revealed: ", story_beat)
	# This would integrate with a story/dialogue system

func trigger_biome_event(event_name: String):
	"""Trigger special biome events"""
	if biome_controller:
		biome_controller.trigger_biome_special_event(event_name)