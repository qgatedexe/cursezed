extends Node2D
class_name DrownedCathedralsRoom

## Drowned Cathedrals Room - Submerged sacred biome with underwater mechanics and light caustics
## Features water volume physics, bubble particles, and caustic lighting effects

@export var bubble_count: int = 150
@export var drift_particle_count: int = 80
@export var water_level: float = 600.0
@export var underwater_movement_scale: float = 0.6
@export var underwater_jump_scale: float = 0.7

# Node references
@onready var parallax_bg: ParallaxController = $ParallaxBackground
@onready var ground_tilemap: TileMap = $GroundTiles
@onready var underwater_decor: TileMap = $UnderwaterDecorTiles
@onready var bubbles_particles: GPUParticles2D = $BubblesParticles
@onready var drift_particles: GPUParticles2D = $DriftParticles
@onready var caustics_shader_rect: ColorRect = $CausticsShader
@onready var fish_shadow: AnimatedSprite2D = $FishShadow
@onready var submerged_godrays: Light2D = $SubmergedGodrays
@onready var water_volume: Area2D = $WaterVolume
@onready var room_manager: RoomManager = $RoomManager

# Water mechanics
var player_in_water: bool = false
var original_player_settings: Dictionary = {}
var water_surface_particles: GPUParticles2D

# Shader materials
var caustics_material: ShaderMaterial
var underwater_filter_material: ShaderMaterial

# Audio
var underwater_audio_bus: String = "Underwater"

func _ready():
	_setup_parallax()
	_setup_particles()
	_setup_lighting()
	_setup_shaders()
	_setup_water_volume()
	_setup_room_manager()
	_create_water_surface()

func _setup_parallax():
	"""Configure parallax for underwater cathedral atmosphere"""
	if parallax_bg:
		parallax_bg.set_biome_config("Drowned Cathedrals")

func _setup_particles():
	"""Initialize bubble and drift particle systems"""
	_setup_bubble_particles()
	_setup_drift_particles()

func _setup_bubble_particles():
	"""Configure rising bubble particles"""
	if not bubbles_particles:
		return
		
	var material = ParticleProcessMaterial.new()
	
	# Basic properties
	material.direction = Vector3(0, -1, 0)  # Upward
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.angular_velocity_min = -45.0
	material.angular_velocity_max = 45.0
	
	# Gravity - negative for floating up
	material.gravity = Vector3(0, -20, 0)
	
	# Scale with size variation
	material.scale_min = 0.3
	material.scale_max = 1.2
	material.scale_random = 0.8
	
	# Color - transparent blue-white bubbles
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.9, 1.0, 0.8))  # Light blue
	gradient.add_point(0.5, Color(0.9, 0.95, 1.0, 0.6))  # Almost white
	gradient.add_point(1.0, Color(0.8, 0.9, 1.0, 0.0))  # Fade
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Emission from underwater areas
	material.emission = Emission.EMISSION_BOX
	material.emission_box_extents = Vector3(800, 50, 0)
	
	bubbles_particles.process_material = material
	bubbles_particles.amount = bubble_count
	bubbles_particles.lifetime = randf_range(2.0, 5.0)
	bubbles_particles.emitting = true
	
	if not bubbles_particles.texture:
		bubbles_particles.texture = _create_bubble_texture()

func _setup_drift_particles():
	"""Configure slow floating drift particles"""
	if not drift_particles:
		return
		
	var material = ParticleProcessMaterial.new()
	
	# Very slow, multi-directional movement
	material.direction = Vector3(0.3, 0.1, 0)
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.angular_velocity_min = -20.0
	material.angular_velocity_max = 20.0
	
	# Minimal gravity
	material.gravity = Vector3(0, 5, 0)
	
	# Larger, more visible particles
	material.scale_min = 0.8
	material.scale_max = 1.5
	
	# Blue-green underwater colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.2, 0.6, 0.8, 0.7))  # Deep blue
	gradient.add_point(0.5, Color(0.3, 0.8, 0.6, 0.5))  # Blue-green
	gradient.add_point(1.0, Color(0.2, 0.6, 0.8, 0.0))  # Fade
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Wide emission area
	material.emission = Emission.EMISSION_BOX
	material.emission_box_extents = Vector3(1200, 400, 0)
	
	drift_particles.process_material = material
	drift_particles.amount = drift_particle_count
	drift_particles.lifetime = randf_range(6.0, 12.0)
	drift_particles.emitting = true
	
	if not drift_particles.texture:
		drift_particles.texture = _create_drift_texture()

func _setup_lighting():
	"""Configure underwater lighting with godrays"""
	if submerged_godrays:
		submerged_godrays.color = Color(0.4, 0.7, 1.0, 1.0)  # Blue underwater light
		submerged_godrays.energy = 0.8
		submerged_godrays.texture_scale = 4.0
		
		# Animate godray intensity
		_animate_godrays()

func _animate_godrays():
	"""Create gentle pulsing godray effect"""
	if not submerged_godrays:
		return
		
	var tween = create_tween()
	tween.set_loops()
	
	var base_energy = submerged_godrays.energy
	tween.tween_property(submerged_godrays, "energy", base_energy * 1.3, 3.0)
	tween.tween_property(submerged_godrays, "energy", base_energy * 0.7, 3.0)

func _setup_shaders():
	"""Initialize caustics and underwater filter shaders"""
	_setup_caustics_shader()
	_setup_underwater_filter()

func _setup_caustics_shader():
	"""Create animated caustics light pattern shader"""
	if not caustics_shader_rect:
		return
		
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float speed : hint_range(0.0, 2.0) = 0.6;
uniform float scale : hint_range(0.5, 5.0) = 2.5;
uniform vec3 caustic_color : source_color = vec3(0.2, 0.35, 0.45);

float noise(vec2 p) {
    return sin(p.x * 8.0 + TIME * speed) * sin(p.y * 6.0 + TIME * speed * 0.7) * 0.5 + 0.5;
}

void fragment() {
    vec2 uv = UV;
    float n1 = noise(uv * scale + vec2(TIME * speed, TIME * speed * 0.5));
    float n2 = noise(uv * scale * 1.3 + vec2(TIME * speed * -0.7, TIME * speed * 0.3));
    float combined = (n1 + n2) * 0.5;
    float intensity = smoothstep(0.45, 0.65, combined);
    COLOR = vec4(caustic_color * intensity, intensity * 0.6);
}
"""
	
	caustics_material = ShaderMaterial.new()
	caustics_material.shader = shader
	caustics_material.set_shader_parameter("speed", 0.6)
	caustics_material.set_shader_parameter("scale", 2.5)
	caustics_material.set_shader_parameter("caustic_color", Vector3(0.2, 0.35, 0.45))
	
	caustics_shader_rect.material = caustics_material

func _setup_underwater_filter():
	"""Setup underwater color filter effect"""
	var filter_rect = ColorRect.new()
	filter_rect.color = Color(0.3, 0.5, 0.8, 0.3)  # Blue tint
	filter_rect.size = Vector2(1920, 1080)
	filter_rect.position = Vector2.ZERO
	
	# Add to VFX layer if it exists
	var vfx_layer = get_node_or_null("VFXLayer")
	if vfx_layer:
		vfx_layer.add_child(filter_rect)
	else:
		add_child(filter_rect)
	
	# Animate breathing effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(filter_rect, "color:a", 0.4, 2.0)
	tween.tween_property(filter_rect, "color:a", 0.2, 2.0)

func _setup_water_volume():
	"""Configure water volume area for physics changes"""
	if not water_volume:
		return
		
	# Connect signals
	water_volume.body_entered.connect(_on_water_entered)
	water_volume.body_exited.connect(_on_water_exited)
	
	# Position water volume at appropriate height
	water_volume.position.y = water_level

func _create_water_surface():
	"""Create water surface particle effects"""
	water_surface_particles = GPUParticles2D.new()
	add_child(water_surface_particles)
	
	water_surface_particles.position.y = water_level
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, 0)
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3(0, 0, 0)
	material.scale_min = 0.5
	material.scale_max = 1.0
	
	# Surface ripple colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.8, 1.0, 0.6))
	gradient.add_point(1.0, Color(0.6, 0.8, 1.0, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	water_surface_particles.process_material = material
	water_surface_particles.amount = 50
	water_surface_particles.lifetime = 3.0
	water_surface_particles.emitting = true

func _on_water_entered(body: Node2D):
	"""Handle player entering water"""
	if not body.is_in_group("player"):
		return
		
	player_in_water = true
	
	# Store original player settings
	if body.has_method("get_movement_speed"):
		original_player_settings["movement_speed"] = body.get_movement_speed()
	if body.has_method("get_jump_velocity"):
		original_player_settings["jump_velocity"] = body.get_jump_velocity()
	
	# Apply underwater physics
	if body.has_method("set_movement_scale"):
		body.set_movement_scale(underwater_movement_scale)
	if body.has_method("set_jump_scale"):
		body.set_jump_scale(underwater_jump_scale)
	
	# Start bubble effects around player
	_start_player_bubbles(body)
	
	# Apply audio filter
	_apply_underwater_audio()
	
	print("Player entered water - underwater physics active")

func _on_water_exited(body: Node2D):
	"""Handle player exiting water"""
	if not body.is_in_group("player") or not player_in_water:
		return
		
	player_in_water = false
	
	# Restore original player settings
	if body.has_method("set_movement_scale"):
		body.set_movement_scale(1.0)
	if body.has_method("set_jump_scale"):
		body.set_jump_scale(1.0)
	
	# Stop player bubble effects
	_stop_player_bubbles()
	
	# Remove audio filter
	_remove_underwater_audio()
	
	print("Player exited water - normal physics restored")

func _start_player_bubbles(player: Node2D):
	"""Create bubble effect around player when underwater"""
	var player_bubbles = GPUParticles2D.new()
	player.add_child(player_bubbles)
	player_bubbles.name = "UnderwaterBubbles"
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3(0, -30, 0)
	material.scale_min = 0.2
	material.scale_max = 0.8
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.9, 0.95, 1.0, 0.8))
	gradient.add_point(1.0, Color(0.9, 0.95, 1.0, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	player_bubbles.process_material = material
	player_bubbles.amount = 30
	player_bubbles.lifetime = 1.5
	player_bubbles.emitting = true
	
	player_bubbles.texture = _create_bubble_texture()

func _stop_player_bubbles():
	"""Remove player bubble effects"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var bubbles = player.get_node_or_null("UnderwaterBubbles")
		if bubbles:
			bubbles.queue_free()

func _apply_underwater_audio():
	"""Apply underwater audio filtering"""
	# This would integrate with your audio system
	# AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(underwater_audio_bus), 0, true)
	pass

func _remove_underwater_audio():
	"""Remove underwater audio filtering"""
	# AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(underwater_audio_bus), 0, false)
	pass

func _setup_room_manager():
	"""Configure room-specific settings"""
	if room_manager:
		room_manager.room_name = "Drowned Cathedral Room"
		room_manager.biome_type = "Drowned Cathedrals"
		room_manager.music_cue = "cathedral_underwater"
		room_manager.ambient_sound = "water_ambience"

func _create_bubble_texture() -> ImageTexture:
	"""Create bubble particle texture"""
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	
	# Create circular bubble
	for x in range(8):
		for y in range(8):
			var center = Vector2(4, 4)
			var pos = Vector2(x, y)
			var dist = (pos - center).length()
			
			if dist <= 3:
				var alpha = 1.0 - (dist / 3.0) * 0.5
				image.set_pixel(x, y, Color(0.9, 0.95, 1.0, alpha))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_drift_texture() -> ImageTexture:
	"""Create drift particle texture"""
	var image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	
	# Create soft organic shape
	for x in range(10):
		for y in range(10):
			var center = Vector2(5, 5)
			var pos = Vector2(x, y)
			var dist = (pos - center).length()
			
			if dist <= 4:
				var alpha = 0.7 - (dist / 4.0) * 0.4
				image.set_pixel(x, y, Color(0.3, 0.7, 0.8, alpha))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func set_water_level(new_level: float):
	"""Dynamically adjust water level"""
	water_level = new_level
	if water_volume:
		water_volume.position.y = water_level
	if water_surface_particles:
		water_surface_particles.position.y = water_level

func trigger_tidal_wave():
	"""Special effect: temporary water level change"""
	var original_level = water_level
	var tween = create_tween()
	
	# Rise quickly
	tween.tween_method(set_water_level, original_level, original_level - 200, 1.0)
	# Hold high
	tween.tween_delay(3.0)
	# Recede slowly
	tween.tween_method(set_water_level, original_level - 200, original_level, 4.0)

func animate_fish_shadows():
	"""Animate fish shadows swimming by"""
	if fish_shadow:
		var tween = create_tween()
		tween.set_loops()
		
		# Swim across screen
		fish_shadow.position.x = -200
		tween.tween_property(fish_shadow, "position:x", 2200, 8.0)
		tween.tween_delay(randf_range(5.0, 15.0))
		
		# Vary swimming height
		tween.parallel().tween_property(fish_shadow, "position:y", 
			fish_shadow.position.y + randf_range(-100, 100), 4.0)

func set_cathedral_lighting(sacred: bool):
	"""Toggle between sacred and drowned lighting"""
	if submerged_godrays:
		if sacred:
			submerged_godrays.color = Color(1.0, 0.9, 0.7, 1.0)  # Golden sacred light
			submerged_godrays.energy = 1.2
		else:
			submerged_godrays.color = Color(0.4, 0.7, 1.0, 1.0)  # Blue underwater
			submerged_godrays.energy = 0.8