extends Node
class_name BiomeController

## Biome Controller - Manages biome progression, transitions, and biome-specific mechanics
## Handles the graph-based connection of biomes and rooms within each biome

signal biome_changed(new_biome: String)
signal biome_transition_started(from_biome: String, to_biome: String)
signal biome_transition_completed(biome: String)

# Biome definitions
enum BiomeType {
	FORGOTTEN_FOREST,
	RUINED_CITY,
	DROWNED_CATHEDRALS,
	ENDLESS_ROADS,
	INFERNAL_DEPTHS,
	REVERIE_HEART
}

var biome_names: Dictionary = {
	BiomeType.FORGOTTEN_FOREST: "Forgotten Forest",
	BiomeType.RUINED_CITY: "Ruined City",
	BiomeType.DROWNED_CATHEDRALS: "Drowned Cathedrals",
	BiomeType.ENDLESS_ROADS: "Endless Roads",
	BiomeType.INFERNAL_DEPTHS: "Infernal Depths",
	BiomeType.REVERIE_HEART: "Reverie's Heart"
}

# Biome progression graph
var biome_connections: Dictionary = {
	BiomeType.FORGOTTEN_FOREST: [BiomeType.RUINED_CITY, BiomeType.DROWNED_CATHEDRALS],
	BiomeType.RUINED_CITY: [BiomeType.ENDLESS_ROADS, BiomeType.INFERNAL_DEPTHS],
	BiomeType.DROWNED_CATHEDRALS: [BiomeType.ENDLESS_ROADS, BiomeType.INFERNAL_DEPTHS],
	BiomeType.ENDLESS_ROADS: [BiomeType.REVERIE_HEART],
	BiomeType.INFERNAL_DEPTHS: [BiomeType.REVERIE_HEART],
	BiomeType.REVERIE_HEART: []  # Final biome
}

# Room templates per biome
var biome_room_templates: Dictionary = {
	BiomeType.FORGOTTEN_FOREST: [
		"res://scenes/biomes/forgotten_forest/ForestRoom1.tscn",
		"res://scenes/biomes/forgotten_forest/ForestRoom2.tscn",
		"res://scenes/biomes/forgotten_forest/ForestRoom3.tscn"
	],
	BiomeType.RUINED_CITY: [
		"res://scenes/biomes/ruined_city/CityRoom1.tscn",
		"res://scenes/biomes/ruined_city/CityRoom2.tscn",
		"res://scenes/biomes/ruined_city/CityRoom3.tscn"
	],
	BiomeType.DROWNED_CATHEDRALS: [
		"res://scenes/biomes/drowned_cathedrals/CathedralRoom1.tscn",
		"res://scenes/biomes/drowned_cathedrals/CathedralRoom2.tscn",
		"res://scenes/biomes/drowned_cathedrals/CathedralRoom3.tscn"
	],
	BiomeType.ENDLESS_ROADS: [
		"res://scenes/biomes/endless_roads/DesertRoom1.tscn",
		"res://scenes/biomes/endless_roads/DesertRoom2.tscn",
		"res://scenes/biomes/endless_roads/DesertRoom3.tscn"
	],
	BiomeType.INFERNAL_DEPTHS: [
		"res://scenes/biomes/infernal_depths/InfernalRoom1.tscn",
		"res://scenes/biomes/infernal_depths/InfernalRoom2.tscn",
		"res://scenes/biomes/infernal_depths/InfernalRoom3.tscn"
	],
	BiomeType.REVERIE_HEART: [
		"res://scenes/biomes/reverie_heart/HeartRoom1.tscn",
		"res://scenes/biomes/reverie_heart/HeartRoom2.tscn",
		"res://scenes/biomes/reverie_heart/BossArena.tscn"
	]
}

# Current state
var current_biome: BiomeType = BiomeType.FORGOTTEN_FOREST
var visited_biomes: Array[BiomeType] = []
var unlocked_biomes: Array[BiomeType] = [BiomeType.FORGOTTEN_FOREST]
var biome_completion_status: Dictionary = {}

# Room management
var current_room: Node2D
var room_history: Array[Dictionary] = []

func _ready():
	_initialize_biome_system()

func _initialize_biome_system():
	"""Initialize the biome progression system"""
	# Initialize completion status
	for biome in BiomeType.values():
		biome_completion_status[biome] = {
			"completed": false,
			"rooms_cleared": 0,
			"total_rooms": 3,  # Default, can be overridden
			"secrets_found": 0,
			"boss_defeated": false
		}
	
	print("Biome system initialized - Starting in ", biome_names[current_biome])

func get_current_biome_name() -> String:
	"""Get the name of the current biome"""
	return biome_names[current_biome]

func get_available_biomes() -> Array[BiomeType]:
	"""Get list of biomes that can be accessed from current biome"""
	return biome_connections.get(current_biome, [])

func can_access_biome(biome: BiomeType) -> bool:
	"""Check if a biome can be accessed"""
	return biome in unlocked_biomes

func unlock_biome(biome: BiomeType):
	"""Unlock a new biome for access"""
	if biome not in unlocked_biomes:
		unlocked_biomes.append(biome)
		print("Biome unlocked: ", biome_names[biome])

func transition_to_biome(target_biome: BiomeType):
	"""Transition to a different biome"""
	if not can_access_biome(target_biome):
		print("Cannot access biome: ", biome_names[target_biome])
		return false
	
	var previous_biome = current_biome
	biome_transition_started.emit(biome_names[previous_biome], biome_names[target_biome])
	
	# Add current biome to visited list
	if current_biome not in visited_biomes:
		visited_biomes.append(current_biome)
	
	# Change biome
	current_biome = target_biome
	
	# Load first room of new biome
	_load_biome_starting_room()
	
	biome_changed.emit(biome_names[current_biome])
	biome_transition_completed.emit(biome_names[current_biome])
	
	print("Transitioned to biome: ", biome_names[current_biome])
	return true

func _load_biome_starting_room():
	"""Load the starting room for the current biome"""
	var room_templates = biome_room_templates.get(current_biome, [])
	if room_templates.is_empty():
		print("No room templates found for biome: ", biome_names[current_biome])
		return
	
	var starting_room_path = room_templates[0]  # First room is starting room
	load_room(starting_room_path)

func load_room(room_path: String) -> bool:
	"""Load a specific room scene"""
	if not ResourceLoader.exists(room_path):
		print("Room template not found: ", room_path)
		return false
	
	# Clean up current room
	if current_room:
		_save_room_state()
		current_room.queue_free()
		current_room = null
	
	# Load new room
	var room_scene = load(room_path)
	current_room = room_scene.instantiate()
	
	# Add to scene tree
	get_tree().current_scene.add_child(current_room)
	
	# Configure room for current biome
	_configure_room_for_biome(current_room)
	
	print("Loaded room: ", room_path)
	return true

func _configure_room_for_biome(room: Node2D):
	"""Configure room-specific settings for the current biome"""
	# Set biome-specific properties
	match current_biome:
		BiomeType.FORGOTTEN_FOREST:
			_configure_forest_room(room)
		BiomeType.RUINED_CITY:
			_configure_city_room(room)
		BiomeType.DROWNED_CATHEDRALS:
			_configure_cathedral_room(room)
		BiomeType.ENDLESS_ROADS:
			_configure_desert_room(room)
		BiomeType.INFERNAL_DEPTHS:
			_configure_infernal_room(room)
		BiomeType.REVERIE_HEART:
			_configure_heart_room(room)

func _configure_forest_room(room: Node2D):
	"""Configure room for forest biome"""
	# Apply forest-specific settings
	if room.has_method("set_time_of_day"):
		room.set_time_of_day(0.7)  # Twilight forest

func _configure_city_room(room: Node2D):
	"""Configure room for city biome"""
	# Apply city-specific settings
	if room.has_method("set_industrial_atmosphere"):
		room.set_industrial_atmosphere(1.0)

func _configure_cathedral_room(room: Node2D):
	"""Configure room for cathedral biome"""
	# Apply cathedral-specific settings
	if room.has_method("set_water_level"):
		room.set_water_level(600.0)

func _configure_desert_room(room: Node2D):
	"""Configure room for desert biome"""
	# Apply desert-specific settings
	if room.has_method("set_time_of_day"):
		room.set_time_of_day(1.0)  # Harsh daylight

func _configure_infernal_room(room: Node2D):
	"""Configure room for infernal biome"""
	# Apply infernal-specific settings
	if room.has_method("set_infernal_intensity"):
		room.set_infernal_intensity(1.0)

func _configure_heart_room(room: Node2D):
	"""Configure room for heart biome"""
	# Apply heart-specific settings
	if room.has_method("set_dream_intensity"):
		room.set_dream_intensity(1.0)

func _save_room_state():
	"""Save current room state for potential restoration"""
	if not current_room:
		return
		
	var room_state = {
		"biome": current_biome,
		"room_path": current_room.scene_file_path,
		"player_position": Vector2.ZERO,
		"enemies_defeated": [],
		"pickups_collected": [],
		"secrets_found": []
	}
	
	# Get player position if available
	var player = get_tree().get_first_node_in_group("player")
	if player:
		room_state.player_position = player.global_position
	
	room_history.append(room_state)

func complete_room():
	"""Mark current room as completed"""
	if current_biome in biome_completion_status:
		biome_completion_status[current_biome].rooms_cleared += 1
		
		# Check if biome is complete
		var status = biome_completion_status[current_biome]
		if status.rooms_cleared >= status.total_rooms:
			_complete_biome()

func _complete_biome():
	"""Mark current biome as completed and unlock next biomes"""
	biome_completion_status[current_biome].completed = true
	
	# Unlock connected biomes
	var next_biomes = biome_connections.get(current_biome, [])
	for biome in next_biomes:
		unlock_biome(biome)
	
	print("Biome completed: ", biome_names[current_biome])
	
	# Special handling for final biome
	if current_biome == BiomeType.REVERIE_HEART:
		_trigger_game_completion()

func _trigger_game_completion():
	"""Handle game completion"""
	print("All biomes completed - Game finished!")
	# Signal to game manager or trigger ending sequence

func get_biome_progress() -> Dictionary:
	"""Get progress information for all biomes"""
	var progress = {}
	
	for biome in BiomeType.values():
		var biome_name = biome_names[biome]
		var status = biome_completion_status[biome]
		
		progress[biome_name] = {
			"unlocked": biome in unlocked_biomes,
			"visited": biome in visited_biomes,
			"completed": status.completed,
			"rooms_cleared": status.rooms_cleared,
			"total_rooms": status.total_rooms,
			"progress_percent": (status.rooms_cleared / float(status.total_rooms)) * 100.0
		}
	
	return progress

func get_random_room_for_biome(biome: BiomeType) -> String:
	"""Get a random room template for the specified biome"""
	var templates = biome_room_templates.get(biome, [])
	if templates.is_empty():
		return ""
	
	return templates[randi() % templates.size()]

func trigger_biome_special_event(event_name: String):
	"""Trigger biome-specific special events"""
	if not current_room:
		return
		
	match current_biome:
		BiomeType.FORGOTTEN_FOREST:
			if current_room.has_method("trigger_special_effect"):
				current_room.trigger_special_effect(event_name)
		BiomeType.RUINED_CITY:
			if event_name == "ash_storm" and current_room.has_method("trigger_ash_storm"):
				current_room.trigger_ash_storm()
		BiomeType.DROWNED_CATHEDRALS:
			if event_name == "tidal_wave" and current_room.has_method("trigger_tidal_wave"):
				current_room.trigger_tidal_wave()
		BiomeType.ENDLESS_ROADS:
			if event_name == "sandstorm" and current_room.has_method("trigger_sandstorm"):
				current_room.trigger_sandstorm()
		BiomeType.INFERNAL_DEPTHS:
			if event_name == "eruption" and current_room.has_method("trigger_eruption"):
				current_room.trigger_eruption()
		BiomeType.REVERIE_HEART:
			if event_name == "final_boss" and current_room.has_method("trigger_final_boss_mode"):
				current_room.trigger_final_boss_mode()

func get_biome_type_from_name(biome_name: String) -> BiomeType:
	"""Get BiomeType enum from biome name string"""
	for biome_type in biome_names:
		if biome_names[biome_type] == biome_name:
			return biome_type
	return BiomeType.FORGOTTEN_FOREST  # Default fallback