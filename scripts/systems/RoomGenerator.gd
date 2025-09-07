extends Node
class_name RoomGenerator

## Procedural room generation system for Ashes of Reverie
## Generates connected rooms with different layouts and enemy placements

signal room_generated(room: Node2D)

@export var room_width: int = 1920
@export var room_height: int = 1080
@export var max_rooms_per_level: int = 5
@export var min_rooms_per_level: int = 3

# Room templates for different biomes
var room_templates: Dictionary = {
	"Ashen Courtyard": [
		"res://scenes/rooms/AshenRoom1.tscn",
		"res://scenes/rooms/AshenRoom2.tscn", 
		"res://scenes/rooms/AshenRoom3.tscn"
	],
	"Forgotten Forest": [
		"res://scenes/biomes/forgotten_forest/ForestRoom1.tscn",
		"res://scenes/biomes/forgotten_forest/ForestRoom2.tscn",
		"res://scenes/biomes/forgotten_forest/ForestRoom3.tscn"
	],
	"Ruined City": [
		"res://scenes/biomes/ruined_city/CityRoom1.tscn",
		"res://scenes/biomes/ruined_city/CityRoom2.tscn",
		"res://scenes/biomes/ruined_city/CityRoom3.tscn"
	],
	"Drowned Cathedrals": [
		"res://scenes/biomes/drowned_cathedrals/CathedralRoom1.tscn",
		"res://scenes/biomes/drowned_cathedrals/CathedralRoom2.tscn",
		"res://scenes/biomes/drowned_cathedrals/CathedralRoom3.tscn"
	],
	"Endless Roads": [
		"res://scenes/biomes/endless_roads/DesertRoom1.tscn",
		"res://scenes/biomes/endless_roads/DesertRoom2.tscn",
		"res://scenes/biomes/endless_roads/DesertRoom3.tscn"
	],
	"Infernal Depths": [
		"res://scenes/biomes/infernal_depths/InfernalRoom1.tscn",
		"res://scenes/biomes/infernal_depths/InfernalRoom2.tscn",
		"res://scenes/biomes/infernal_depths/InfernalRoom3.tscn"
	],
	"Reverie's Heart": [
		"res://scenes/biomes/reverie_heart/HeartRoom1.tscn",
		"res://scenes/biomes/reverie_heart/HeartRoom2.tscn",
		"res://scenes/biomes/reverie_heart/BossArena.tscn"
	]
}

var current_biome: String
var generated_rooms: Array[Node2D] = []

func generate_level(biome: String, level: int) -> Dictionary:
	"""Generate a complete level with connected rooms"""
	current_biome = biome
	generated_rooms.clear()
	
	# Determine number of rooms for this level
	var room_count = randi_range(min_rooms_per_level, max_rooms_per_level)
	
	# Generate room layout
	var room_layout = _generate_room_layout(room_count)
	
	# Create starting room
	var starting_room = _create_room(0, Vector2.ZERO, level)
	generated_rooms.append(starting_room)
	
	return {
		"starting_room": starting_room,
		"room_count": room_count,
		"biome": biome
	}

func _generate_room_layout(room_count: int) -> Array:
	"""Generate the layout pattern for rooms"""
	var layout = []
	
	# Simple linear layout for now - can be expanded later
	for i in range(room_count):
		layout.append({
			"id": i,
			"position": Vector2(i * room_width, 0),
			"connections": []
		})
	
	# Add connections between adjacent rooms
	for i in range(room_count - 1):
		layout[i].connections.append(i + 1)
		layout[i + 1].connections.append(i)
	
	return layout

func _create_room(room_id: int, position: Vector2, level: int) -> Node2D:
	"""Create a room instance with the specified parameters"""
	
	# Select random room template for current biome
	var templates = room_templates.get(current_biome, [])
	if templates.is_empty():
		# Fallback to basic room if no templates found
		return _create_basic_room(room_id, position, level)
	
	var template_path = templates[randi() % templates.size()]
	
	# Try to load the template, fallback to basic room if it doesn't exist
	if ResourceLoader.exists(template_path):
		var room_scene = load(template_path)
		var room = room_scene.instantiate() as Node2D
		room.position = position
		room.room_id = room_id
		room.biome = current_biome
		return room
	else:
		return _create_basic_room(room_id, position, level)

func _create_basic_room(room_id: int, position: Vector2, level: int) -> Node2D:
	"""Create a basic procedural room when templates aren't available"""
	var room_scene = preload("res://scenes/rooms/BasicRoom.tscn")
	var room = room_scene.instantiate() as Node2D
	
	room.position = position
	room.room_id = room_id
	room.biome = current_biome
	
	# Add some procedural elements
	_add_platforms_to_room(room, level)
	_add_enemies_to_room(room, level)
	
	return room

func _add_platforms_to_room(room: Room, level: int):
	"""Add procedural platforms to a room"""
	var platform_count = randi_range(2, 5)
	
	for i in range(platform_count):
		var platform_x = randf_range(200, room_width - 200)
		var platform_y = randf_range(300, room_height - 200)
		
		# Create platform (will be handled by room's setup)
		room.add_platform(Vector2(platform_x, platform_y), Vector2(200, 32))

func _add_enemies_to_room(room: Room, level: int):
	"""Add enemies to a room based on level difficulty"""
	var enemy_count = min(2 + (level - 1), 6) # Scale with level
	
	for i in range(enemy_count):
		var enemy_x = randf_range(100, room_width - 100)
		var enemy_y = randf_range(200, room_height - 100)
		
		room.add_enemy(Vector2(enemy_x, enemy_y), "basic")