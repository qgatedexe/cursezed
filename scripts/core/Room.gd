extends Node2D
class_name Room

## Base room class for all game rooms
## Handles room setup, enemy spawning, and player interactions

signal room_cleared
signal player_entered
signal player_exited

@export var room_id: int = 0
@export var biome: String = "Ashen Courtyard"
@export var is_cleared: bool = false

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var platforms_container: Node2D = $Platforms
@onready var enemies_container: Node2D = $Enemies
@onready var pickups_container: Node2D = $Pickups
@onready var room_bounds: Area2D = $RoomBounds

var enemies: Array[Enemy] = []
var active_player: Player

func _ready():
	# Setup room bounds detection
	if room_bounds:
		room_bounds.body_entered.connect(_on_room_entered)
		room_bounds.body_exited.connect(_on_room_exited)
	
	# Connect to enemy death signals
	_connect_enemy_signals()
	
	# Add some default enemies for testing
	call_deferred("_setup_default_enemies")

func add_platform(pos: Vector2, size: Vector2):
	"""Add a platform to the room"""
	var platform = preload("res://scenes/rooms/Platform.tscn").instantiate()
	platform.position = pos
	platform.setup_size(size)
	platforms_container.add_child(platform)

func add_enemy(pos: Vector2, enemy_type: String):
	"""Add an enemy to the room"""
	var enemy_scene = preload("res://scenes/enemies/BasicEnemy.tscn")
	var enemy = enemy_scene.instantiate() as Enemy
	enemy.position = pos
	enemy.enemy_type = enemy_type
	enemies_container.add_child(enemy)
	enemies.append(enemy)
	
	# Connect enemy death signal
	enemy.died.connect(_on_enemy_died)

func add_pickup(pos: Vector2, pickup_type: String):
	"""Add a pickup to the room"""
	var pickup_scene = preload("res://scenes/pickups/MemoryFragment.tscn")
	var pickup = pickup_scene.instantiate()
	pickup.position = pos
	pickups_container.add_child(pickup)

func _connect_enemy_signals():
	"""Connect signals from existing enemies"""
	for enemy in enemies:
		if not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)

func _on_room_entered(body):
	"""Handle player entering room"""
	if body is Player:
		active_player = body
		player_entered.emit()
		print("Player entered room: ", room_id)

func _on_room_exited(body):
	"""Handle player leaving room"""
	if body is Player and body == active_player:
		active_player = null
		player_exited.emit()
		print("Player exited room: ", room_id)

func _on_enemy_died(enemy: Enemy):
	"""Handle enemy death"""
	enemies.erase(enemy)
	
	# Check if room is cleared
	if enemies.is_empty() and not is_cleared:
		is_cleared = true
		room_cleared.emit()
		_spawn_level_door()
		print("Room cleared: ", room_id)

func get_enemy_count() -> int:
	"""Get number of living enemies in room"""
	return enemies.size()

func get_spawn_position() -> Vector2:
	"""Get the spawn position for this room"""
	if spawn_point:
		return spawn_point.global_position
	return global_position + Vector2(100, 100) # Fallback position

func _setup_default_enemies():
	"""Setup some default enemies for testing"""
	# Add 2-3 enemies at random positions
	var enemy_count = randi_range(1, 3)
	
	for i in range(enemy_count):
		var pos_x = randf_range(300, 1600)
		var pos_y = randf_range(200, 900)
		add_enemy(Vector2(pos_x, pos_y), "basic")

func _spawn_level_door():
	"""Spawn the level door when room is cleared"""
	var door_scene = preload("res://scenes/rooms/LevelDoor.tscn")
	var door = door_scene.instantiate()
	
	# Position door at the right side of the room
	door.global_position = Vector2(1700, 900)
	
	# Set next level name based on current biome
	var next_levels = {
		"Ashen Courtyard": "Luminous Abyss",
		"Luminous Abyss": "Whispering Halls", 
		"Whispering Halls": "Oblivion Root",
		"Oblivion Root": "The Final Dream"
	}
	
	var next_level = next_levels.get(biome, "Unknown Realm")
	door.set_next_level(next_level)
	
	add_child(door)
	door.appear_when_room_cleared()
	
	# Connect door signal to game manager
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		door.door_activated.connect(game_manager._on_level_door_activated)