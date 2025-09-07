extends Node2D
class_name EndlessRoadsRoom

## Endless Roads Room - Desert biome with heat shimmer, mirages, and long horizontal spaces
## Features heat distortion effects, dust particles, and mirage mechanics

@export var dust_particle_count: int = 200
@export var heat_shimmer_strength: float = 0.02
@export var mirage_fade_distance: float = 300.0
@export var room_scroll_speed: float = 50.0

# Extended room size for desert feel
@export var extended_width: int = 6400
@export var extended_height: int = 1920

# Node references
@onready var parallax_bg: ParallaxController = $ParallaxBackground
@onready var road_tiles: TileMap = $RoadTiles
@onready var dust_particles: GPUParticles2D = $DustParticles
@onready var heat_shader_rect: ColorRect = $HeatShader
@onready var mirage_container: Node2D = $MirageContainer
@onready var room_manager: RoomManager = $RoomManager

# Mirage system
var mirage_objects: Array[Dictionary] = []
var active_mirages: Array[Node2D] = []

# Shader materials
var heat_shimmer_material: ShaderMaterial

# Wind system
var wind_strength: float = 1.0
var wind_direction: Vector2 = Vector2.RIGHT

func _ready():
	_setup_parallax()
	_setup_particles()
	_setup_shaders()
	_setup_mirages()
	_setup_room_manager()
	_setup_extended_room()

func _process(delta):
	_update_mirages(delta)
	_update_wind_effects(delta)

func _setup_parallax():
	"""Configure parallax for vast desert landscape"""
	if parallax_bg:
		parallax_bg.set_biome_config("Endless Roads")
		parallax_bg.auto_scroll = true
		parallax_bg.base_scroll_speed = room_scroll_speed

func _setup_particles():
	"""Initialize dust particle system"""
	_setup_dust_particles()

func _setup_dust_particles():
	"""Configure wind-blown dust particles"""
	if not dust_particles:
		return
		
	var material = ParticleProcessMaterial.new()
	
	# Horizontal wind movement
	material.direction = Vector3(1, 0.1, 0)
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 120.0
	material.angular_velocity_min = -90.0
	material.angular_velocity_max = 90.0
	
	# Light gravity for dust
	material.gravity = Vector3(0, 20, 0)
	
	# Small particle scale
	material.scale_min = 0.3
	material.scale_max = 0.8
	material.scale_random = 0.7
	
	# Sandy colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.9, 0.8, 0.6, 1.0))  # Sandy yellow
	gradient.add_point(0.5, Color(0.8, 0.7, 0.5, 0.7))  # Dusty brown
	gradient.add_point(1.0, Color(0.7, 0.6, 0.4, 0.0))  # Fade to transparent
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Emission along the road
	material.emission = Emission.EMISSION_BOX
	material.emission_box_extents = Vector3(extended_width/2, 100, 0)
	
	dust_particles.process_material = material
	dust_particles.amount = dust_particle_count
	dust_particles.lifetime = randf_range(2.0, 6.0)
	dust_particles.emitting = true
	
	if not dust_particles.texture:
		dust_particles.texture = _create_dust_texture()

func _setup_shaders():
	"""Initialize heat shimmer shader effects"""
	_setup_heat_shimmer()

func _setup_heat_shimmer():
	"""Create heat distortion shader effect"""
	if not heat_shader_rect:
		return
		
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float strength : hint_range(0.0, 0.1) = 0.02;
uniform float frequency : hint_range(1.0, 20.0) = 8.0;
uniform float speed : hint_range(0.0, 3.0) = 0.8;

float noise(vec2 p) {
    return sin(p.x * frequency + TIME * speed) * sin(p.y * frequency * 0.7 + TIME * speed * 1.3);
}

void fragment() {
    vec2 uv = UV;
    float n = noise(uv * 2.0) * strength;
    vec2 coord = uv + vec2(n, n * 0.5);
    COLOR = texture(SCREEN_TEXTURE, coord);
}
"""
	
	heat_shimmer_material = ShaderMaterial.new()
	heat_shimmer_material.shader = shader
	heat_shimmer_material.set_shader_parameter("strength", heat_shimmer_strength)
	heat_shimmer_material.set_shader_parameter("frequency", 8.0)
	heat_shimmer_material.set_shader_parameter("speed", 0.8)
	
	heat_shader_rect.material = heat_shimmer_material

func _setup_mirages():
	"""Initialize mirage system with phantom objects"""
	_create_mirage_objects()

func _create_mirage_objects():
	"""Create mirage objects that appear and disappear"""
	var mirage_types = [
		{"name": "oasis", "texture_size": Vector2(200, 150), "color": Color(0.3, 0.8, 0.4, 0.6)},
		{"name": "city", "texture_size": Vector2(300, 200), "color": Color(0.7, 0.7, 0.9, 0.5)},
		{"name": "wagon", "texture_size": Vector2(150, 100), "color": Color(0.6, 0.4, 0.3, 0.7)},
		{"name": "skeleton", "texture_size": Vector2(100, 120), "color": Color(0.9, 0.9, 0.8, 0.4)}
	]
	
	# Create mirage spawn points along the road
	var spawn_points = [
		Vector2(1500, 800),
		Vector2(3200, 700),
		Vector2(4800, 850),
		Vector2(5500, 750)
	]
	
	for i in range(spawn_points.size()):
		var mirage_type = mirage_types[i % mirage_types.size()]
		var spawn_point = spawn_points[i]
		
		var mirage_data = {
			"type": mirage_type.name,
			"position": spawn_point,
			"texture_size": mirage_type.texture_size,
			"color": mirage_type.color,
			"fade_timer": 0.0,
			"visible": false,
			"node": null
		}
		
		mirage_objects.append(mirage_data)

func _update_mirages(delta):
	"""Update mirage visibility and effects"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	for mirage_data in mirage_objects:
		var distance = player.global_position.distance_to(mirage_data.position)
		
		# Show mirage when player is at medium distance
		if distance < mirage_fade_distance * 2 and distance > mirage_fade_distance:
			if not mirage_data.visible:
				_show_mirage(mirage_data)
		# Hide when too close or too far
		elif mirage_data.visible and (distance <= mirage_fade_distance or distance > mirage_fade_distance * 3):
			_hide_mirage(mirage_data)
		
		# Update existing mirage
		if mirage_data.visible and mirage_data.node:
			_update_mirage_effect(mirage_data, distance, delta)

func _show_mirage(mirage_data: Dictionary):
	"""Make a mirage visible"""
	if mirage_data.node:
		return
		
	var mirage_sprite = Sprite2D.new()
	mirage_container.add_child(mirage_sprite)
	
	mirage_sprite.position = mirage_data.position
	mirage_sprite.modulate = mirage_data.color
	mirage_sprite.texture = _create_mirage_texture(mirage_data.type, mirage_data.texture_size)
	
	# Add wavering effect
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float wave_speed : hint_range(0.0, 5.0) = 2.0;
uniform float wave_amount : hint_range(0.0, 0.1) = 0.03;

void fragment() {
    vec2 uv = UV;
    float wave = sin(uv.y * 10.0 + TIME * wave_speed) * wave_amount;
    vec2 coord = uv + vec2(wave, 0.0);
    COLOR = texture(TEXTURE, coord);
}
"""
	
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("wave_speed", 2.0)
	material.set_shader_parameter("wave_amount", 0.03)
	mirage_sprite.material = material
	
	mirage_data.node = mirage_sprite
	mirage_data.visible = true
	
	# Fade in
	mirage_sprite.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(mirage_sprite, "modulate:a", mirage_data.color.a, 1.0)

func _hide_mirage(mirage_data: Dictionary):
	"""Hide a mirage"""
	if not mirage_data.node:
		return
		
	var mirage_node = mirage_data.node
	mirage_data.visible = false
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(mirage_node, "modulate:a", 0.0, 0.5)
	tween.tween_callback(mirage_node.queue_free)
	
	mirage_data.node = null

func _update_mirage_effect(mirage_data: Dictionary, distance: float, delta: float):
	"""Update mirage visual effects based on distance"""
	if not mirage_data.node:
		return
		
	var mirage_node = mirage_data.node
	
	# Adjust opacity based on distance
	var opacity_factor = 1.0 - clamp((distance - mirage_fade_distance) / mirage_fade_distance, 0.0, 1.0)
	mirage_node.modulate.a = mirage_data.color.a * opacity_factor
	
	# Add subtle floating motion
	mirage_node.position.y = mirage_data.position.y + sin(Time.get_time_dict_from_system().second * 2.0) * 10.0

func _update_wind_effects(delta):
	"""Update wind-based effects"""
	# Vary wind strength over time
	wind_strength = 1.0 + sin(Time.get_time_dict_from_system().second * 0.3) * 0.5
	
	# Update dust particle emission based on wind
	if dust_particles and dust_particles.process_material:
		var material = dust_particles.process_material as ParticleProcessMaterial
		material.initial_velocity_max = 120.0 * wind_strength

func _setup_extended_room():
	"""Configure room for extended desert dimensions"""
	# Extend road tilemap if it exists
	if road_tiles:
		# This would normally be done in the scene editor, but we can set properties here
		pass

func _setup_room_manager():
	"""Configure room-specific settings"""
	if room_manager:
		room_manager.room_name = "Endless Roads Room"
		room_manager.biome_type = "Endless Roads"
		room_manager.music_cue = "desert_winds"
		room_manager.ambient_sound = "desert_ambience"
		room_manager.room_width = extended_width
		room_manager.room_height = extended_height

func _create_dust_texture() -> ImageTexture:
	"""Create dust particle texture"""
	var image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	
	# Create irregular dust particle
	for x in range(6):
		for y in range(6):
			var noise_val = sin(x * 0.5) * cos(y * 0.7) * 0.5 + 0.5
			if noise_val > 0.3:
				image.set_pixel(x, y, Color(0.8, 0.7, 0.5, noise_val))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_mirage_texture(mirage_type: String, size: Vector2) -> ImageTexture:
	"""Create texture for specific mirage type"""
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	
	match mirage_type:
		"oasis":
			# Green oasis shape
			image.fill(Color(0.2, 0.7, 0.3, 0.6))
		"city":
			# City silhouette
			image.fill(Color(0.6, 0.6, 0.8, 0.5))
		"wagon":
			# Wagon shape
			image.fill(Color(0.5, 0.3, 0.2, 0.7))
		"skeleton":
			# Skeletal remains
			image.fill(Color(0.9, 0.9, 0.8, 0.4))
		_:
			image.fill(Color(0.7, 0.7, 0.7, 0.5))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func trigger_sandstorm():
	"""Special effect: intense sandstorm"""
	if not dust_particles:
		return
		
	var original_amount = dust_particles.amount
	var original_velocity = (dust_particles.process_material as ParticleProcessMaterial).initial_velocity_max
	
	# Increase particle intensity
	dust_particles.amount = original_amount * 3
	(dust_particles.process_material as ParticleProcessMaterial).initial_velocity_max = original_velocity * 2
	
	# Increase heat shimmer
	if heat_shimmer_material:
		heat_shimmer_material.set_shader_parameter("strength", heat_shimmer_strength * 2)
	
	# Hide all mirages during storm
	for mirage_data in mirage_objects:
		if mirage_data.visible:
			_hide_mirage(mirage_data)
	
	# Restore after storm
	var restore_timer = get_tree().create_timer(8.0)
	restore_timer.timeout.connect(_restore_after_sandstorm.bind(original_amount, original_velocity))

func _restore_after_sandstorm(original_amount: int, original_velocity: float):
	"""Restore normal conditions after sandstorm"""
	dust_particles.amount = original_amount
	(dust_particles.process_material as ParticleProcessMaterial).initial_velocity_max = original_velocity
	
	if heat_shimmer_material:
		heat_shimmer_material.set_shader_parameter("strength", heat_shimmer_strength)

func set_time_of_day(time: float):
	"""Adjust desert atmosphere based on time (0.0 = night, 1.0 = day)"""
	# Adjust heat shimmer (stronger during day)
	var shimmer_strength = heat_shimmer_strength * time
	if heat_shimmer_material:
		heat_shimmer_material.set_shader_parameter("strength", shimmer_strength)
	
	# Adjust dust particle color (cooler at night)
	if dust_particles and dust_particles.process_material:
		var material = dust_particles.process_material as ParticleProcessMaterial
		var gradient = Gradient.new()
		
		if time > 0.5:  # Day
			gradient.add_point(0.0, Color(0.9, 0.8, 0.6, 1.0))
			gradient.add_point(1.0, Color(0.7, 0.6, 0.4, 0.0))
		else:  # Night
			gradient.add_point(0.0, Color(0.6, 0.7, 0.8, 1.0))
			gradient.add_point(1.0, Color(0.4, 0.5, 0.6, 0.0))
		
		var gradient_texture = GradientTexture1D.new()
		gradient_texture.gradient = gradient
		material.color_ramp = gradient_texture

func create_secret_mirage_door(destination: String):
	"""Create a special mirage that acts as a secret door"""
	var secret_mirage = {
		"type": "secret_door",
		"position": Vector2(extended_width - 500, 800),
		"texture_size": Vector2(120, 200),
		"color": Color(0.8, 0.6, 1.0, 0.3),
		"fade_timer": 0.0,
		"visible": false,
		"node": null,
		"destination": destination
	}
	
	mirage_objects.append(secret_mirage)
	
	# Create interaction area
	var interaction_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(150, 250)
	collision.shape = shape
	
	interaction_area.add_child(collision)
	interaction_area.position = secret_mirage.position
	add_child(interaction_area)
	
	interaction_area.body_entered.connect(_on_secret_mirage_entered.bind(secret_mirage))

func _on_secret_mirage_entered(mirage_data: Dictionary, body: Node2D):
	"""Handle player entering secret mirage door"""
	if body.is_in_group("player"):
		print("Player discovered secret mirage door to: ", mirage_data.destination)
		# Trigger transition to secret area
		get_tree().call_group("game_manager", "transition_to_secret_area", mirage_data.destination)