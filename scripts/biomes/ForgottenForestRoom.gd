extends Node2D
class_name ForgottenForestRoom

## Forgotten Forest Room - Dreamlike forest biome with glowing spores and depth
## Handles forest-specific particle effects, lighting, and atmospheric elements

@export var spore_count: int = 200
@export var leaf_count: int = 100
@export var light_flicker_intensity: float = 0.3
@export var fog_density: float = 0.5

# Node references
@onready var parallax_bg: ParallaxController = $ParallaxBackground
@onready var ground_tiles: TileMap = $GroundTiles
@onready var decoration_tiles: TileMap = $DecorationTiles
@onready var spores_particles: GPUParticles2D = $SporesParticles
@onready var leaf_particles: GPUParticles2D = $LeafParticles
@onready var global_light: Light2D = $GlobalLight
@onready var vfx_layer: CanvasLayer = $VFXLayer
@onready var floating_motes: AnimatedSprite2D = $VFXLayer/FloatingMotes
@onready var volumetric_fog: ColorRect = $VFXLayer/VolumetricFog
@onready var room_manager: RoomManager = $RoomManager

# Shader materials
var fog_shader_material: ShaderMaterial
var tree_sway_material: ShaderMaterial

func _ready():
	_setup_parallax()
	_setup_particles()
	_setup_lighting()
	_setup_shaders()
	_setup_room_manager()

func _setup_parallax():
	"""Configure parallax background for forest atmosphere"""
	if parallax_bg:
		parallax_bg.set_biome_config("Forgotten Forest")
		
		# Setup individual layers if they exist
		var layers = parallax_bg.get_children()
		for i in range(layers.size()):
			var layer = layers[i]
			if layer is ParallaxLayer:
				match i:
					0: # Far sky
						layer.motion_scale = Vector2(0.2, 0.2)
						layer.motion_mirroring = Vector2(1920, 0)
					1: # Distant trees
						layer.motion_scale = Vector2(0.5, 0.5)
						layer.motion_mirroring = Vector2(3840, 0)
					2: # Mid trees
						layer.motion_scale = Vector2(0.8, 0.8)
						layer.motion_mirroring = Vector2(2560, 0)
					3: # Foreground
						layer.motion_scale = Vector2(1.0, 1.0)
						layer.motion_mirroring = Vector2(1920, 0)

func _setup_particles():
	"""Initialize particle systems for forest atmosphere"""
	_setup_spore_particles()
	_setup_leaf_particles()

func _setup_spore_particles():
	"""Configure glowing spore particles"""
	if not spores_particles:
		return
		
	# Create particle material
	var material = ParticleProcessMaterial.new()
	
	# Basic properties
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.angular_velocity_min = -45.0
	material.angular_velocity_max = 45.0
	
	# Gravity and forces
	material.gravity = Vector3(0, -10, 0)  # Slight upward float
	
	# Scale
	material.scale_min = 0.4
	material.scale_max = 1.0
	material.scale_random = 0.5
	
	# Color
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.4, 0.8, 0.9, 1.0))  # Pale cyan
	gradient.add_point(1.0, Color(0.4, 0.8, 0.9, 0.0))  # Fade to transparent
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Emission
	material.emission = Emission.EMISSION_SPHERE
	var emission_box = material as ParticleProcessMaterial
	material.emission_box_extents = Vector3(960, 50, 0)  # Screen width
	
	# Apply to particle system
	spores_particles.process_material = material
	spores_particles.amount = spore_count
	spores_particles.lifetime = randf_range(4.0, 8.0)
	spores_particles.preprocess = 0.5
	spores_particles.emitting = true
	
	# Create simple spore texture if none exists
	if not spores_particles.texture:
		spores_particles.texture = _create_spore_texture()

func _setup_leaf_particles():
	"""Configure falling leaf particles"""
	if not leaf_particles:
		return
		
	var material = ParticleProcessMaterial.new()
	
	# Basic properties
	material.direction = Vector3(0.3, 1, 0)  # Slight drift
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.angular_velocity_min = -90.0
	material.angular_velocity_max = 90.0
	
	# Gravity
	material.gravity = Vector3(0, 98, 0)  # Gentle fall
	
	# Scale
	material.scale_min = 0.6
	material.scale_max = 1.2
	
	# Color - forest leaf colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.2, 0.6, 0.1, 1.0))  # Forest green
	gradient.add_point(0.5, Color(0.4, 0.3, 0.1, 1.0))  # Brown
	gradient.add_point(1.0, Color(0.4, 0.3, 0.1, 0.0))  # Fade
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Emission
	material.emission = Emission.EMISSION_BOX
	material.emission_box_extents = Vector3(1500, 100, 0)
	
	leaf_particles.process_material = material
	leaf_particles.amount = leaf_count
	leaf_particles.lifetime = randf_range(3.0, 6.0)
	leaf_particles.emitting = true
	
	if not leaf_particles.texture:
		leaf_particles.texture = _create_leaf_texture()

func _setup_lighting():
	"""Configure atmospheric lighting"""
	if global_light:
		global_light.color = Color(0.7, 0.9, 0.8, 1.0)  # Soft greenish tint
		global_light.energy = 0.6
		global_light.texture_scale = 2.0
		
		# Add subtle flicker
		_start_light_flicker()

func _start_light_flicker():
	"""Create subtle light flickering effect"""
	var tween = create_tween()
	tween.set_loops()
	
	var base_energy = global_light.energy
	var flicker_amount = light_flicker_intensity
	
	tween.tween_method(_update_light_energy, 
		base_energy, 
		base_energy + flicker_amount, 
		randf_range(0.5, 1.5))
	tween.tween_method(_update_light_energy, 
		base_energy + flicker_amount, 
		base_energy - flicker_amount, 
		randf_range(0.3, 1.0))
	tween.tween_method(_update_light_energy, 
		base_energy - flicker_amount, 
		base_energy, 
		randf_range(0.5, 1.2))

func _update_light_energy(energy: float):
	"""Update light energy for flicker effect"""
	if global_light:
		global_light.energy = energy

func _setup_shaders():
	"""Initialize shader effects"""
	_setup_fog_shader()
	_setup_tree_sway_shader()

func _setup_fog_shader():
	"""Create volumetric fog shader effect"""
	if not volumetric_fog:
		return
		
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec3 fog_color : source_color = vec3(0.05, 0.08, 0.06);
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float time_speed : hint_range(0.0, 2.0) = 0.2;
uniform float noise_scale : hint_range(0.1, 5.0) = 1.5;

float noise(vec2 p) {
    return sin(p.x * 10.0 + TIME * time_speed) * sin(p.y * 8.0 + TIME * time_speed * 0.7) * 0.5 + 0.5;
}

void fragment() {
    vec2 uv = UV;
    float n = noise(uv * noise_scale);
    float fog = smoothstep(0.25, 0.75, n) * density;
    COLOR = vec4(fog_color, fog);
}
"""
	
	fog_shader_material = ShaderMaterial.new()
	fog_shader_material.shader = shader
	fog_shader_material.set_shader_parameter("fog_color", Vector3(0.05, 0.08, 0.06))
	fog_shader_material.set_shader_parameter("density", fog_density)
	fog_shader_material.set_shader_parameter("time_speed", 0.2)
	fog_shader_material.set_shader_parameter("noise_scale", 1.5)
	
	volumetric_fog.material = fog_shader_material

func _setup_tree_sway_shader():
	"""Create tree swaying shader for mid-ground trees"""
	# This would be applied to the mid_trees ParallaxLayer sprite
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 20.0) = 6.0;
uniform float speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec2 uv = UV;
    float sway = sin((uv.y * 10.0) + TIME * speed) * amplitude / 1000.0;
    vec2 coord = uv + vec2(sway, 0.0);
    COLOR = texture(TEXTURE, coord);
}
"""
	
	tree_sway_material = ShaderMaterial.new()
	tree_sway_material.shader = shader
	tree_sway_material.set_shader_parameter("amplitude", 6.0)
	tree_sway_material.set_shader_parameter("speed", 1.0)
	
	# Apply to mid-trees layer if it exists
	if parallax_bg and parallax_bg.get_child_count() > 2:
		var mid_layer = parallax_bg.get_child(2)
		if mid_layer is ParallaxLayer:
			for child in mid_layer.get_children():
				if child is Sprite2D:
					child.material = tree_sway_material

func _setup_room_manager():
	"""Configure room-specific settings"""
	if room_manager:
		room_manager.room_name = "Forgotten Forest Room"
		room_manager.biome_type = "Forgotten Forest"
		room_manager.music_cue = "forest_ambient"
		room_manager.ambient_sound = "forest_atmosphere"

func _create_spore_texture() -> ImageTexture:
	"""Create a simple spore texture"""
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.8, 0.9, 0.8))
	
	# Create circular shape
	for x in range(8):
		for y in range(8):
			var dist = Vector2(x - 4, y - 4).length()
			if dist > 3:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_leaf_texture() -> ImageTexture:
	"""Create a simple leaf texture"""
	var image = Image.create(12, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.6, 0.1, 0.9))
	
	# Create leaf shape (simple oval)
	for x in range(12):
		for y in range(16):
			var center = Vector2(6, 8)
			var pos = Vector2(x, y)
			var dist = (pos - center).length()
			if dist > 6:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func set_time_of_day(time: float):
	"""Adjust lighting and atmosphere based on time (0.0 = night, 1.0 = day)"""
	if global_light:
		global_light.energy = lerp(0.3, 0.8, time)
		global_light.color = Color.from_hsv(
			lerp(0.5, 0.4, time),  # Hue: blue-green to green
			0.3,  # Saturation
			lerp(0.7, 1.0, time)  # Value: darker at night
		)
	
	if fog_shader_material:
		var fog_alpha = lerp(0.8, 0.3, time)
		fog_shader_material.set_shader_parameter("density", fog_alpha)

func trigger_special_effect(effect_name: String):
	"""Trigger special forest effects"""
	match effect_name:
		"spore_burst":
			_trigger_spore_burst()
		"wind_gust":
			_trigger_wind_gust()
		"light_pulse":
			_trigger_light_pulse()

func _trigger_spore_burst():
	"""Temporary increase in spore particle emission"""
	if spores_particles:
		var original_amount = spores_particles.amount
		spores_particles.amount = original_amount * 3
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func(): spores_particles.amount = original_amount)

func _trigger_wind_gust():
	"""Strong wind effect through parallax"""
	if parallax_bg:
		parallax_bg.set_wind(Vector2(1.5, -0.3), 150.0)
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): parallax_bg.set_wind(Vector2(1.0, -0.2), 30.0))

func _trigger_light_pulse():
	"""Bright light pulse effect"""
	if global_light:
		var tween = create_tween()
		var original_energy = global_light.energy
		tween.tween_property(global_light, "energy", original_energy * 2.0, 0.3)
		tween.tween_property(global_light, "energy", original_energy, 1.0)