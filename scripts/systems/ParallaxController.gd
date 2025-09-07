extends ParallaxBackground
class_name ParallaxController

## Parallax Controller - Manages parallax background layers with wind effects and dynamic scrolling
## Handles per-biome scrolling values and player-responsive camera movement

@export var base_scroll_speed: float = 100.0
@export var wind_strength: float = 0.0
@export var wind_direction: Vector2 = Vector2.RIGHT
@export var player_influence: float = 0.1
@export var auto_scroll: bool = false

# Layer configuration
var layer_configs: Array[Dictionary] = []
var original_motion_scales: Array[Vector2] = []

@onready var camera: Camera2D = get_viewport().get_camera_2d()

func _ready():
	_initialize_layers()
	
func _process(delta):
	if auto_scroll:
		_update_auto_scroll(delta)
	
	if wind_strength > 0:
		_apply_wind_effect(delta)
	
	_update_player_influence()

func _initialize_layers():
	"""Store original layer configurations for restoration"""
	layer_configs.clear()
	original_motion_scales.clear()
	
	for i in range(get_child_count()):
		var layer = get_child(i)
		if layer is ParallaxLayer:
			original_motion_scales.append(layer.motion_scale)
			layer_configs.append({
				"layer": layer,
				"original_motion_scale": layer.motion_scale,
				"original_motion_offset": layer.motion_offset,
				"scroll_multiplier": 1.0
			})

func set_biome_config(biome_name: String):
	"""Configure parallax for specific biome"""
	match biome_name:
		"Forgotten Forest":
			_setup_forest_config()
		"Ruined City":
			_setup_city_config()
		"Drowned Cathedrals":
			_setup_underwater_config()
		"Endless Roads":
			_setup_desert_config()
		"Infernal Depths":
			_setup_infernal_config()
		"Reverie's Heart":
			_setup_nexus_config()
		_:
			_setup_default_config()

func _setup_forest_config():
	"""Configure parallax for forest biome"""
	base_scroll_speed = 50.0
	wind_strength = 30.0
	wind_direction = Vector2(1.0, -0.2)
	player_influence = 0.15
	
	# Set layer-specific multipliers
	for i in range(layer_configs.size()):
		match i:
			0: # Far sky
				layer_configs[i].scroll_multiplier = 0.1
			1: # Distant trees
				layer_configs[i].scroll_multiplier = 0.3
			2: # Mid trees
				layer_configs[i].scroll_multiplier = 0.6
			3: # Foreground
				layer_configs[i].scroll_multiplier = 0.9

func _setup_city_config():
	"""Configure parallax for ruined city biome"""
	base_scroll_speed = 80.0
	wind_strength = 50.0
	wind_direction = Vector2(1.0, 0.1)
	player_influence = 0.1
	
	for i in range(layer_configs.size()):
		match i:
			0: # Ash sky
				layer_configs[i].scroll_multiplier = 0.2
			1: # Distant buildings
				layer_configs[i].scroll_multiplier = 0.4
			2: # Foreground ruins
				layer_configs[i].scroll_multiplier = 0.8

func _setup_underwater_config():
	"""Configure parallax for underwater biome"""
	base_scroll_speed = 30.0
	wind_strength = 15.0
	wind_direction = Vector2(0.8, -0.3)
	player_influence = 0.2
	
	for i in range(layer_configs.size()):
		match i:
			0: # Deep sky
				layer_configs[i].scroll_multiplier = 0.1
			1: # Sea surface light
				layer_configs[i].scroll_multiplier = 0.3
			2: # Drowned arches
				layer_configs[i].scroll_multiplier = 0.7

func _setup_desert_config():
	"""Configure parallax for desert biome"""
	base_scroll_speed = 120.0
	wind_strength = 80.0
	wind_direction = Vector2(1.0, 0.0)
	player_influence = 0.05
	auto_scroll = true
	
	for i in range(layer_configs.size()):
		match i:
			0: # Distant horizon
				layer_configs[i].scroll_multiplier = 0.1
			1: # Mid ruins
				layer_configs[i].scroll_multiplier = 0.4
			2: # Road foreground
				layer_configs[i].scroll_multiplier = 0.9

func _setup_infernal_config():
	"""Configure parallax for infernal biome"""
	base_scroll_speed = 60.0
	wind_strength = 100.0
	wind_direction = Vector2(0.5, -1.0)
	player_influence = 0.1
	
	for i in range(layer_configs.size()):
		match i:
			0: # Deep glow
				layer_configs[i].scroll_multiplier = 0.2
			1: # Lava ridges
				layer_configs[i].scroll_multiplier = 0.6

func _setup_nexus_config():
	"""Configure parallax for dream nexus biome"""
	base_scroll_speed = 40.0
	wind_strength = 60.0
	wind_direction = Vector2(0.7, -0.7)
	player_influence = 0.3
	
	for i in range(layer_configs.size()):
		match i:
			0: # Starfield
				layer_configs[i].scroll_multiplier = 0.05
			1: # Shifting fragments
				layer_configs[i].scroll_multiplier = 0.8

func _setup_default_config():
	"""Default parallax configuration"""
	base_scroll_speed = 100.0
	wind_strength = 0.0
	player_influence = 0.1

func _update_auto_scroll(delta):
	"""Update automatic scrolling for desert biome"""
	for config in layer_configs:
		var layer = config.layer
		layer.motion_offset.x += base_scroll_speed * config.scroll_multiplier * delta

func _apply_wind_effect(delta):
	"""Apply wind effect to all layers"""
	var wind_offset = wind_direction * wind_strength * delta
	
	for config in layer_configs:
		var layer = config.layer
		var wind_influence = config.scroll_multiplier * wind_offset
		layer.motion_offset += wind_influence

func _update_player_influence():
	"""Update parallax based on player movement"""
	if not camera:
		return
		
	var camera_velocity = Vector2.ZERO
	if camera.has_method("get_velocity"):
		camera_velocity = camera.get_velocity() * player_influence
	
	for config in layer_configs:
		var layer = config.layer
		var influence = camera_velocity * config.scroll_multiplier * player_influence
		layer.motion_offset += influence * get_process_delta_time()

func set_wind(direction: Vector2, strength: float):
	"""Set wind parameters dynamically"""
	wind_direction = direction.normalized()
	wind_strength = strength

func add_layer_shake(intensity: float, duration: float):
	"""Add screen shake effect to parallax layers"""
	var tween = create_tween()
	var shake_offset = Vector2.ZERO
	
	for i in range(int(duration * 60)): # 60 FPS assumption
		shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		
		for config in layer_configs:
			var layer = config.layer
			layer.motion_offset += shake_offset
		
		tween.tween_delay(1.0/60.0)
	
	# Restore original positions
	tween.tween_callback(_restore_layer_positions)

func _restore_layer_positions():
	"""Restore layers to their original positions after shake"""
	for config in layer_configs:
		var layer = config.layer
		layer.motion_offset = config.original_motion_offset

func reset_to_biome(biome_name: String):
	"""Reset and reconfigure for a new biome"""
	# Restore original configurations
	for i in range(layer_configs.size()):
		var config = layer_configs[i]
		var layer = config.layer
		layer.motion_scale = original_motion_scales[i]
		layer.motion_offset = config.original_motion_offset
	
	# Apply new biome configuration
	set_biome_config(biome_name)