extends Node
class_name RoomManager

## Room Manager - Handles room transitions, music cues, and room-specific logic
## Manages loading/unloading of room scenes and pooling of enemies & particles

signal room_entered(room_name: String)
signal room_exited(room_name: String)
signal music_cue_triggered(cue_name: String)

@export var room_name: String = ""
@export var biome_type: String = ""
@export var music_cue: String = ""
@export var ambient_sound: String = ""

# Room properties
@export var room_width: int = 3000
@export var room_height: int = 2000
@export var tile_size: int = 32

# Performance settings
@export var max_particles_per_system: int = 300
@export var particle_lod_distance: float = 1000.0
@export var enable_particle_pooling: bool = true

var is_active: bool = false
var player_in_room: bool = false
var particle_systems: Array[GPUParticles2D] = []
var dynamic_objects: Array[Node] = []

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var exit_triggers: Array[Area2D] = []

func _ready():
	# Find all exit triggers in the room
	_find_exit_triggers()
	
	# Setup particle systems
	_setup_particle_systems()
	
	# Connect to visibility signals for performance optimization
	if has_node("VisibilityEnabler2D"):
		var vis_enabler = $VisibilityEnabler2D
		vis_enabler.screen_entered.connect(_on_screen_entered)
		vis_enabler.screen_exited.connect(_on_screen_exited)

func _find_exit_triggers():
	"""Find all Area2D nodes marked as exit triggers"""
	for child in get_children():
		if child is Area2D and child.has_meta("exit_trigger"):
			exit_triggers.append(child)
			child.body_entered.connect(_on_exit_trigger_entered)

func _setup_particle_systems():
	"""Initialize and configure particle systems"""
	for child in get_tree().get_nodes_in_group("particles"):
		if child.get_parent() == self and child is GPUParticles2D:
			particle_systems.append(child)
			# Apply LOD settings
			child.amount = min(child.amount, max_particles_per_system)

func enter_room(player: Player):
	"""Called when player enters this room"""
	if player_in_room:
		return
		
	player_in_room = true
	is_active = true
	
	# Enable particle systems
	_set_particles_active(true)
	
	# Trigger music cue
	if not music_cue.is_empty():
		music_cue_triggered.emit(music_cue)
	
	# Start ambient sounds
	if not ambient_sound.is_empty():
		_start_ambient_sound()
	
	room_entered.emit(room_name)
	print("Entered room: ", room_name, " (", biome_type, ")")

func exit_room(player: Player):
	"""Called when player exits this room"""
	if not player_in_room:
		return
		
	player_in_room = false
	is_active = false
	
	# Disable particle systems for performance
	_set_particles_active(false)
	
	# Stop ambient sounds
	_stop_ambient_sound()
	
	room_exited.emit(room_name)
	print("Exited room: ", room_name)

func _set_particles_active(active: bool):
	"""Enable/disable particle systems based on room activity"""
	for particle_system in particle_systems:
		if is_instance_valid(particle_system):
			particle_system.emitting = active
			if not active:
				particle_system.restart()

func _on_exit_trigger_entered(body):
	"""Handle player entering an exit trigger"""
	if body is Player:
		var exit_data = {
			"room_name": room_name,
			"exit_direction": "forward"  # Can be customized per trigger
		}
		# Signal to GameManager to handle room transition
		get_tree().call_group("game_manager", "handle_room_transition", exit_data)

func _on_screen_entered():
	"""Called when room becomes visible on screen"""
	if not is_active:
		_set_particles_active(true)

func _on_screen_exited():
	"""Called when room goes off screen"""
	if not player_in_room:
		_set_particles_active(false)

func _start_ambient_sound():
	"""Start ambient sound for this room"""
	# Implementation depends on your audio system
	pass

func _stop_ambient_sound():
	"""Stop ambient sound for this room"""
	# Implementation depends on your audio system
	pass

func add_dynamic_object(obj: Node):
	"""Add an object to be managed by this room"""
	dynamic_objects.append(obj)

func remove_dynamic_object(obj: Node):
	"""Remove an object from room management"""
	dynamic_objects.erase(obj)

func get_spawn_position() -> Vector2:
	"""Get the spawn position for this room"""
	if spawn_point:
		return spawn_point.global_position
	return global_position

func update_particle_lod(camera_position: Vector2):
	"""Update particle level of detail based on camera distance"""
	var distance = global_position.distance_to(camera_position)
	var lod_factor = 1.0
	
	if distance > particle_lod_distance:
		lod_factor = max(0.3, 1.0 - (distance - particle_lod_distance) / particle_lod_distance)
	
	for particle_system in particle_systems:
		if is_instance_valid(particle_system):
			var original_amount = particle_system.get_meta("original_amount", particle_system.amount)
			particle_system.amount = int(original_amount * lod_factor)