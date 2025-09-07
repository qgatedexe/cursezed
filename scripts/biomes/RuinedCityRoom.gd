extends Node2D
class_name RuinedCityRoom

## Ruined City of Ash Room - Industrial post-apocalyptic biome with ash particles and collapsing structures
## Features dynamic collapsing floors, ash/ember particles, and flickering neon lights

@export var ash_particle_count: int = 300
@export var ember_count: int = 60
@export var collapse_delay: float = 0.6
@export var respawn_time: float = 10.0

# Node references
@onready var parallax_bg: ParallaxController = $ParallaxBackground
@onready var walls_tilemap: TileMap = $WallsTiles
@onready var platforms_tilemap: TileMap = $PlatformsTiles
@onready var decor_tilemap: TileMap = $DecorTiles
@onready var ash_particles: GPUParticles2D = $AshParticles
@onready var ember_particles: GPUParticles2D = $EmberParticles
@onready var flicker_lights: Array[Light2D] = []
@onready var broken_neon: AnimatedSprite2D = $BrokenNeon
@onready var smoke_shader_rect: ColorRect = $SmokeShader
@onready var room_manager: RoomManager = $RoomManager

# Collapsing floor system
var collapsing_areas: Array[Dictionary] = []
var original_tile_data: Dictionary = {}

# Shader materials
var smoke_shader_material: ShaderMaterial
var neon_flicker_material: ShaderMaterial

func _ready():
	_setup_parallax()
	_setup_particles()
	_setup_lighting()
	_setup_shaders()
	_setup_collapsing_floors()
	_setup_room_manager()
	_find_flicker_lights()

func _setup_parallax():
	"""Configure parallax for industrial cityscape"""
	if parallax_bg:
		parallax_bg.set_biome_config("Ruined City")

func _setup_particles():
	"""Initialize ash and ember particle systems"""
	_setup_ash_particles()
	_setup_ember_particles()

func _setup_ash_particles():
	"""Configure falling ash particles"""
	if not ash_particles:
		return
		
	var material = ParticleProcessMaterial.new()
	
	# Basic properties
	material.direction = Vector3(0.2, 1, 0)  # Slight drift downward
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.angular_velocity_min = -30.0
	material.angular_velocity_max = 30.0
	
	# Gravity
	material.gravity = Vector3(0, 50, 0)  # Slow fall
	
	# Scale
	material.scale_min = 0.2
	material.scale_max = 0.6
	material.scale_random = 0.8
	
	# Color - grayscale ash
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.7, 0.7, 0.7, 1.0))  # Light gray
	gradient.add_point(0.5, Color(0.4, 0.4, 0.4, 0.8))  # Medium gray
	gradient.add_point(1.0, Color(0.2, 0.2, 0.2, 0.0))  # Dark gray fade
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Emission
	material.emission = Emission.EMISSION_BOX
	material.emission_box_extents = Vector3(1500, 100, 0)
	
	ash_particles.process_material = material
	ash_particles.amount = ash_particle_count
	ash_particles.lifetime = randf_range(4.0, 10.0)
	ash_particles.emitting = true
	
	if not ash_particles.texture:
		ash_particles.texture = _create_ash_texture()

func _setup_ember_particles():
	"""Configure glowing ember particles"""
	if not ember_particles:
		return
		
	var material = ParticleProcessMaterial.new()
	
	# Basic properties
	material.direction = Vector3(0, -1, 0)  # Upward
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 120.0
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	
	# Gravity - negative for floating up
	material.gravity = Vector3(0, -30, 0)
	
	# Scale
	material.scale_min = 0.3
	material.scale_max = 0.8
	
	# Color - orange to yellow glow
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.6, 0.2, 1.0))  # Orange
	gradient.add_point(0.7, Color(1.0, 0.9, 0.4, 0.8))  # Yellow
	gradient.add_point(1.0, Color(0.8, 0.3, 0.1, 0.0))  # Red fade
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Emission from specific points (near fires/sparks)
	material.emission = Emission.EMISSION_POINT
	
	ember_particles.process_material = material
	ember_particles.amount = ember_count
	ember_particles.lifetime = randf_range(0.8, 1.8)
	ember_particles.emitting = true
	
	if not ember_particles.texture:
		ember_particles.texture = _create_ember_texture()

func _setup_lighting():
	"""Configure flickering industrial lighting"""
	# Create some point lights for atmosphere
	_create_industrial_lights()
	
	# Start flicker animation
	_start_light_flicker()

func _create_industrial_lights():
	"""Create flickering lights at key positions"""
	var light_positions = [
		Vector2(500, 400),
		Vector2(1200, 600),
		Vector2(2000, 300),
		Vector2(2800, 500)
	]
	
	for pos in light_positions:
		var light = Light2D.new()
		light.position = pos
		light.color = Color(1.0, 0.7, 0.4, 1.0)  # Warm industrial light
		light.energy = randf_range(0.6, 1.0)
		light.texture_scale = 3.0
		add_child(light)
		flicker_lights.append(light)

func _start_light_flicker():
	"""Create flickering effect for industrial lights"""
	for light in flicker_lights:
		var tween = create_tween()
		tween.set_loops()
		
		var base_energy = light.energy
		var flicker_intensity = randf_range(0.3, 0.6)
		
		# Random flicker pattern
		tween.tween_property(light, "energy", base_energy * flicker_intensity, randf_range(0.1, 0.3))
		tween.tween_property(light, "energy", base_energy, randf_range(0.2, 0.5))
		tween.tween_delay(randf_range(0.5, 2.0))

func _find_flicker_lights():
	"""Find existing Light2D nodes to add to flicker system"""
	for child in get_children():
		if child is Light2D and child.name.contains("flicker"):
			flicker_lights.append(child)

func _setup_shaders():
	"""Initialize shader effects for smoke and atmosphere"""
	_setup_smoke_shader()
	_setup_neon_flicker()

func _setup_smoke_shader():
	"""Create tiling smoke shader effect"""
	if not smoke_shader_rect:
		return
		
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float speed : hint_range(0.0, 1.0) = 0.1;
uniform float scale : hint_range(0.5, 5.0) = 2.0;
uniform vec3 smoke_color : source_color = vec3(0.05, 0.05, 0.06);

float noise(vec2 p) {
    return sin(p.x * 12.0 + TIME * speed * 3.0) * sin(p.y * 8.0 + TIME * speed * 2.0) * 0.5 + 0.5;
}

void fragment() {
    vec2 uv = UV;
    float n = noise(uv * scale + vec2(TIME * speed, 0.0));
    float alpha = smoothstep(0.4, 0.7, n) * 0.4;
    COLOR = vec4(smoke_color, alpha);
}
"""
	
	smoke_shader_material = ShaderMaterial.new()
	smoke_shader_material.shader = shader
	smoke_shader_material.set_shader_parameter("speed", 0.1)
	smoke_shader_material.set_shader_parameter("scale", 2.0)
	smoke_shader_material.set_shader_parameter("smoke_color", Vector3(0.05, 0.05, 0.06))
	
	smoke_shader_rect.material = smoke_shader_material

func _setup_neon_flicker():
	"""Setup flickering neon sign effect"""
	if broken_neon:
		var tween = create_tween()
		tween.set_loops()
		
		# Intermittent flicker pattern
		tween.tween_property(broken_neon, "modulate", Color(1, 1, 1, 1), 0.1)
		tween.tween_property(broken_neon, "modulate", Color(1, 1, 1, 0.3), 0.1)
		tween.tween_property(broken_neon, "modulate", Color(1, 1, 1, 1), 0.05)
		tween.tween_property(broken_neon, "modulate", Color(1, 1, 1, 0.1), 0.2)
		tween.tween_delay(randf_range(1.0, 3.0))

func _setup_collapsing_floors():
	"""Initialize collapsing floor system"""
	_scan_for_collapsing_areas()
	_backup_tile_data()

func _scan_for_collapsing_areas():
	"""Find areas marked for collapsing floors"""
	# Look for Area2D nodes with "collapse" in their name or metadata
	for child in get_children():
		if child is Area2D and (child.name.contains("collapse") or child.has_meta("collapsing_floor")):
			var collapse_data = {
				"area": child,
				"tilemap": platforms_tilemap,
				"fallen": false,
				"original_tiles": []
			}
			collapsing_areas.append(collapse_data)
			child.body_entered.connect(_on_collapse_area_entered.bind(collapse_data))

func _backup_tile_data():
	"""Backup original tile data for respawning"""
	if not platforms_tilemap:
		return
		
	for collapse_data in collapsing_areas:
		var area = collapse_data.area
		var shape = area.get_child(0) as CollisionShape2D
		if not shape:
			continue
			
		var rect = shape.shape as RectangleShape2D
		if not rect:
			continue
			
		# Get tiles in the collapse area
		var area_rect = Rect2(area.position - rect.size/2, rect.size)
		var tiles_in_area = []
		
		for x in range(int(area_rect.position.x / 32), int((area_rect.position.x + area_rect.size.x) / 32)):
			for y in range(int(area_rect.position.y / 32), int((area_rect.position.y + area_rect.size.y) / 32)):
				var tile_pos = Vector2i(x, y)
				var source_id = platforms_tilemap.get_cell_source_id(0, tile_pos)
				if source_id != -1:
					tiles_in_area.append({
						"position": tile_pos,
						"source_id": source_id,
						"atlas_coords": platforms_tilemap.get_cell_atlas_coords(0, tile_pos),
						"alternative_tile": platforms_tilemap.get_cell_alternative_tile(0, tile_pos)
					})
		
		collapse_data.original_tiles = tiles_in_area

func _on_collapse_area_entered(collapse_data: Dictionary, body: Node2D):
	"""Handle player entering a collapsing floor area"""
	if collapse_data.fallen or not body.is_in_group("player"):
		return
		
	# Start collapse sequence
	_trigger_floor_collapse(collapse_data)

func _trigger_floor_collapse(collapse_data: Dictionary):
	"""Trigger floor collapse with delay and effects"""
	collapse_data.fallen = true
	
	# Visual warning (could add cracks, shaking, etc.)
	_show_collapse_warning(collapse_data)
	
	# Wait for collapse delay
	await get_tree().create_timer(collapse_delay).timeout
	
	# Remove tiles
	_remove_collapse_tiles(collapse_data)
	
	# Add collapse effects
	_add_collapse_effects(collapse_data)
	
	# Schedule respawn
	await get_tree().create_timer(respawn_time).timeout
	_respawn_collapse_tiles(collapse_data)

func _show_collapse_warning(collapse_data: Dictionary):
	"""Show visual warning before collapse"""
	var area = collapse_data.area
	
	# Create warning particles or visual effect
	var warning_particles = GPUParticles2D.new()
	area.add_child(warning_particles)
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 0.5
	material.scale_max = 1.0
	
	# Dust color
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.5, 0.4, 1.0))
	gradient.add_point(1.0, Color(0.6, 0.5, 0.4, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	warning_particles.process_material = material
	warning_particles.amount = 30
	warning_particles.lifetime = 2.0
	warning_particles.emitting = true
	
	# Remove after collapse
	await get_tree().create_timer(collapse_delay + 0.5).timeout
	warning_particles.queue_free()

func _remove_collapse_tiles(collapse_data: Dictionary):
	"""Remove tiles in collapse area"""
	var tilemap = collapse_data.tilemap
	
	for tile_data in collapse_data.original_tiles:
		tilemap.set_cell(0, tile_data.position, -1)

func _add_collapse_effects(collapse_data: Dictionary):
	"""Add visual/audio effects for collapse"""
	var area = collapse_data.area
	
	# Camera shake (if available)
	if get_tree().has_group("camera_controller"):
		get_tree().call_group("camera_controller", "add_shake", 5.0, 0.3)
	
	# Dust cloud effect
	var dust_particles = GPUParticles2D.new()
	area.add_child(dust_particles)
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 120.0
	material.gravity = Vector3(0, 50, 0)
	material.scale_min = 1.0
	material.scale_max = 2.0
	
	dust_particles.process_material = material
	dust_particles.amount = 100
	dust_particles.lifetime = 3.0
	dust_particles.emitting = true
	dust_particles.one_shot = true

func _respawn_collapse_tiles(collapse_data: Dictionary):
	"""Respawn collapsed tiles after delay"""
	var tilemap = collapse_data.tilemap
	
	for tile_data in collapse_data.original_tiles:
		tilemap.set_cell(0, tile_data.position, tile_data.source_id, tile_data.atlas_coords, tile_data.alternative_tile)
	
	collapse_data.fallen = false

func _setup_room_manager():
	"""Configure room-specific settings"""
	if room_manager:
		room_manager.room_name = "Ruined City Room"
		room_manager.biome_type = "Ruined City"
		room_manager.music_cue = "city_industrial"
		room_manager.ambient_sound = "ash_wind"

func _create_ash_texture() -> ImageTexture:
	"""Create simple ash particle texture"""
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.6, 0.6, 0.8))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_ember_texture() -> ImageTexture:
	"""Create glowing ember texture"""
	var image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.6, 0.2, 1.0))
	
	# Create glow effect
	for x in range(6):
		for y in range(6):
			var dist = Vector2(x - 3, y - 3).length()
			if dist > 2:
				image.set_pixel(x, y, Color.TRANSPARENT)
			elif dist > 1:
				image.set_pixel(x, y, Color(1.0, 0.8, 0.4, 0.6))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func trigger_ash_storm():
	"""Trigger intense ash particle effect"""
	if ash_particles:
		var original_amount = ash_particles.amount
		ash_particles.amount = original_amount * 2
		await get_tree().create_timer(5.0).timeout
		ash_particles.amount = original_amount

func set_industrial_atmosphere(intensity: float):
	"""Adjust overall industrial atmosphere intensity"""
	# Adjust particle emission
	if ash_particles:
		ash_particles.amount = int(ash_particle_count * intensity)
	
	if ember_particles:
		ember_particles.amount = int(ember_count * intensity)
	
	# Adjust lighting
	for light in flicker_lights:
		light.energy = light.energy * intensity
	
	# Adjust smoke shader
	if smoke_shader_material:
		smoke_shader_material.set_shader_parameter("speed", 0.1 * intensity)
		var alpha = 0.4 * intensity
		smoke_shader_material.set_shader_parameter("smoke_color", Vector3(0.05, 0.05, 0.06) * alpha)