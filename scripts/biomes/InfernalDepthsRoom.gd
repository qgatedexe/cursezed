extends Node2D
class_name InfernalDepthsRoom

## Infernal Depths Room - Lava-filled hellish biome with intense heat and dangerous platforming
## Features lava damage areas, ember particles, magma bursts, and timed platform collapses

@export var ember_count: int = 250
@export var smoke_count: int = 100
@export var lava_damage: int = 30
@export var lava_damage_interval: float = 0.5
@export var platform_collapse_warning_time: float = 2.0

# Node references
@onready var parallax_bg: ParallaxController = $ParallaxBackground
@onready var rock_tiles: TileMap = $RockTiles
@onready var lava_tiles: TileMap = $LavaTiles
@onready var ember_particles: GPUParticles2D = $EmberParticles
@onready var smoke_particles: GPUParticles2D = $SmokeParticles
@onready var lava_glow_light: Light2D = $LavaGlowLight
@onready var magma_burst_container: Node2D = $MagmaBurstContainer
@onready var scanline_heat_rect: ColorRect = $ScanlineHeat
@onready var room_manager: RoomManager = $RoomManager

# Lava damage system
var lava_damage_areas: Array[Area2D] = []
var players_in_lava: Array[Node2D] = []
var lava_damage_timers: Dictionary = {}

# Timed platform system
var timed_platforms: Array[Dictionary] = []

# Magma burst system
var burst_locations: Array[Vector2] = []
var burst_timer: float = 0.0
var burst_interval: float = 8.0

# Shader materials
var lava_glow_material: ShaderMaterial
var scanline_material: ShaderMaterial

func _ready():
	_setup_parallax()
	_setup_particles()
	_setup_lighting()
	_setup_shaders()
	_setup_lava_damage()
	_setup_timed_platforms()
	_setup_magma_bursts()
	_setup_room_manager()

func _process(delta):
	_update_lava_damage(delta)
	_update_magma_bursts(delta)
	_update_timed_platforms(delta)

func _setup_parallax():
	"""Configure parallax for hellish underground atmosphere"""
	if parallax_bg:
		parallax_bg.set_biome_config("Infernal Depths")

func _setup_particles():
	"""Initialize ember and smoke particle systems"""
	_setup_ember_particles()
	_setup_smoke_particles()

func _setup_ember_particles():
	"""Configure intense ember particles"""
	if not ember_particles:
		return
		
	var material = ParticleProcessMaterial.new()
	
	# Upward and outward movement
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	
	# Spread for more chaotic movement
	material.spread = 30.0
	
	# Negative gravity for floating up
	material.gravity = Vector3(0, -50, 0)
	
	# Varied scale
	material.scale_min = 0.4
	material.scale_max = 1.2
	material.scale_random = 0.8
	
	# Bright orange to red colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.8, 0.2, 1.0))  # Bright yellow-orange
	gradient.add_point(0.3, Color(1.0, 0.5, 0.1, 1.0))  # Orange
	gradient.add_point(0.7, Color(0.9, 0.2, 0.1, 0.8))  # Red
	gradient.add_point(1.0, Color(0.6, 0.1, 0.0, 0.0))  # Dark red fade
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Multiple emission points near lava
	material.emission = Emission.EMISSION_BOX
	material.emission_box_extents = Vector3(1200, 100, 0)
	
	ember_particles.process_material = material
	ember_particles.amount = ember_count
	ember_particles.lifetime = randf_range(0.6, 1.6)
	ember_particles.emitting = true
	
	if not ember_particles.texture:
		ember_particles.texture = _create_ember_texture()

func _setup_smoke_particles():
	"""Configure dense smoke particles"""
	if not smoke_particles:
		return
		
	var material = ParticleProcessMaterial.new()
	
	# Slow upward movement
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.angular_velocity_min = -45.0
	material.angular_velocity_max = 45.0
	
	# Very light gravity
	material.gravity = Vector3(0, -10, 0)
	
	# Large smoke particles
	material.scale_min = 1.5
	material.scale_max = 3.0
	material.scale_random = 0.6
	
	# Dark smoke colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.2, 0.1, 0.1, 0.8))  # Dark red-brown
	gradient.add_point(0.5, Color(0.15, 0.1, 0.1, 0.6))  # Darker
	gradient.add_point(1.0, Color(0.1, 0.05, 0.05, 0.0))  # Almost black fade
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	smoke_particles.process_material = material
	smoke_particles.amount = smoke_count
	smoke_particles.lifetime = randf_range(3.0, 6.0)
	smoke_particles.emitting = true
	
	if not smoke_particles.texture:
		smoke_particles.texture = _create_smoke_texture()

func _setup_lighting():
	"""Configure lava glow lighting"""
	if lava_glow_light:
		lava_glow_light.color = Color(1.0, 0.4, 0.1, 1.0)  # Orange-red glow
		lava_glow_light.energy = 1.5
		lava_glow_light.texture_scale = 5.0
		
		# Animate lava glow pulsing
		_animate_lava_glow()

func _animate_lava_glow():
	"""Create pulsing lava glow effect"""
	if not lava_glow_light:
		return
		
	var tween = create_tween()
	tween.set_loops()
	
	var base_energy = lava_glow_light.energy
	tween.tween_property(lava_glow_light, "energy", base_energy * 1.4, 1.5)
	tween.tween_property(lava_glow_light, "energy", base_energy * 0.8, 1.2)

func _setup_shaders():
	"""Initialize lava and heat effect shaders"""
	_setup_lava_glow_shader()
	_setup_scanline_shader()

func _setup_lava_glow_shader():
	"""Create animated lava glow shader for lava tiles"""
	if not lava_tiles:
		return
		
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float glow_speed : hint_range(0.0, 5.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.25;
uniform vec3 glow_color : source_color = vec3(1.0, 0.4, 0.0);

void fragment() {
    vec2 uv = UV;
    float glow = sin(uv.x * 10.0 + TIME * glow_speed) * sin(uv.y * 8.0 + TIME * glow_speed * 0.7) * 0.5 + 0.5;
    vec4 base = texture(TEXTURE, uv);
    vec3 glow_effect = glow_color * glow * glow_intensity;
    COLOR = base + vec4(glow_effect, 0.0);
}
"""
	
	lava_glow_material = ShaderMaterial.new()
	lava_glow_material.shader = shader
	lava_glow_material.set_shader_parameter("glow_speed", 2.0)
	lava_glow_material.set_shader_parameter("glow_intensity", 0.25)
	lava_glow_material.set_shader_parameter("glow_color", Vector3(1.0, 0.4, 0.0))
	
	lava_tiles.material = lava_glow_material

func _setup_scanline_shader():
	"""Create subtle scanline heat effect"""
	if not scanline_heat_rect:
		return
		
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float scanline_speed : hint_range(0.0, 10.0) = 3.0;
uniform float intensity : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    vec2 uv = UV;
    float scanline = sin((uv.y * 100.0) + TIME * scanline_speed) * 0.5 + 0.5;
    float flicker = scanline * intensity;
    COLOR = vec4(vec3(1.0, 0.3, 0.1) * flicker, flicker);
}
"""
	
	scanline_material = ShaderMaterial.new()
	scanline_material.shader = shader
	scanline_material.set_shader_parameter("scanline_speed", 3.0)
	scanline_material.set_shader_parameter("intensity", 0.1)
	
	scanline_heat_rect.material = scanline_material

func _setup_lava_damage():
	"""Initialize lava damage areas"""
	_find_lava_damage_areas()

func _find_lava_damage_areas():
	"""Find all Area2D nodes marked as lava damage zones"""
	for child in get_children():
		if child is Area2D and (child.name.contains("lava") or child.has_meta("lava_damage")):
			lava_damage_areas.append(child)
			child.body_entered.connect(_on_lava_entered.bind(child))
			child.body_exited.connect(_on_lava_exited.bind(child))

func _on_lava_entered(lava_area: Area2D, body: Node2D):
	"""Handle entity entering lava"""
	if body.is_in_group("player"):
		players_in_lava.append(body)
		lava_damage_timers[body] = 0.0
		print("Player entered lava - taking damage!")
		
		# Immediate damage
		if body.has_method("take_damage"):
			body.take_damage(lava_damage)
		
		# Screen flash effect
		_trigger_lava_damage_flash()

func _on_lava_exited(lava_area: Area2D, body: Node2D):
	"""Handle entity exiting lava"""
	if body in players_in_lava:
		players_in_lava.erase(body)
		lava_damage_timers.erase(body)
		print("Player exited lava")

func _update_lava_damage(delta):
	"""Apply continuous lava damage"""
	for player in players_in_lava:
		if player in lava_damage_timers:
			lava_damage_timers[player] += delta
			
			if lava_damage_timers[player] >= lava_damage_interval:
				lava_damage_timers[player] = 0.0
				
				if player.has_method("take_damage"):
					player.take_damage(lava_damage)
					_trigger_lava_damage_flash()

func _trigger_lava_damage_flash():
	"""Create screen flash effect for lava damage"""
	# Use CanvasModulate for screen flash
	var canvas_modulate = get_tree().get_first_node_in_group("canvas_modulate")
	if canvas_modulate:
		var tween = create_tween()
		tween.tween_property(canvas_modulate, "color", Color.RED, 0.1)
		tween.tween_property(canvas_modulate, "color", Color.WHITE, 0.2)

func _setup_timed_platforms():
	"""Initialize timed collapsing platforms"""
	_find_timed_platforms()

func _find_timed_platforms():
	"""Find platforms marked for timed collapse"""
	for child in get_children():
		if child is Area2D and (child.name.contains("timed_platform") or child.has_meta("timed_platform")):
			var platform_data = {
				"area": child,
				"warning_time": platform_collapse_warning_time,
				"collapse_timer": 0.0,
				"warning_active": false,
				"collapsed": false,
				"original_tiles": []
			}
			
			timed_platforms.append(platform_data)
			child.body_entered.connect(_on_timed_platform_entered.bind(platform_data))

func _on_timed_platform_entered(platform_data: Dictionary, body: Node2D):
	"""Handle player stepping on timed platform"""
	if platform_data.collapsed or platform_data.warning_active:
		return
		
	if body.is_in_group("player"):
		platform_data.warning_active = true
		_start_platform_warning(platform_data)

func _start_platform_warning(platform_data: Dictionary):
	"""Start visual warning for platform collapse"""
	var area = platform_data.area
	
	# Create warning particles
	var warning_particles = GPUParticles2D.new()
	area.add_child(warning_particles)
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, 100, 0)
	
	# Warning color (bright orange/red)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.5, 0.0, 1.0))
	gradient.add_point(1.0, Color(1.0, 0.2, 0.0, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	warning_particles.process_material = material
	warning_particles.amount = 50
	warning_particles.lifetime = 2.0
	warning_particles.emitting = true

func _update_timed_platforms(delta):
	"""Update timed platform collapse system"""
	for platform_data in timed_platforms:
		if platform_data.warning_active and not platform_data.collapsed:
			platform_data.collapse_timer += delta
			
			if platform_data.collapse_timer >= platform_data.warning_time:
				_collapse_platform(platform_data)

func _collapse_platform(platform_data: Dictionary):
	"""Collapse a timed platform"""
	platform_data.collapsed = true
	
	# Remove tiles (this would need proper tilemap integration)
	# For now, just disable the collision
	var area = platform_data.area
	var collision = area.get_child(0) as CollisionShape2D
	if collision:
		collision.disabled = true
	
	# Create collapse effect
	_create_platform_collapse_effect(platform_data)
	
	# Schedule respawn after some time
	await get_tree().create_timer(15.0).timeout
	_respawn_platform(platform_data)

func _create_platform_collapse_effect(platform_data: Dictionary):
	"""Create visual effects for platform collapse"""
	var area = platform_data.area
	
	# Explosion particles
	var explosion_particles = GPUParticles2D.new()
	area.add_child(explosion_particles)
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0
	material.gravity = Vector3(0, 200, 0)
	material.spread = 45.0
	
	# Rock/lava colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.3, 0.2, 1.0))  # Rock
	gradient.add_point(0.5, Color(1.0, 0.5, 0.1, 1.0))  # Lava
	gradient.add_point(1.0, Color(0.4, 0.2, 0.1, 0.0))  # Fade
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	explosion_particles.process_material = material
	explosion_particles.amount = 80
	explosion_particles.lifetime = 2.0
	explosion_particles.emitting = true
	explosion_particles.one_shot = true
	
	# Camera shake
	if get_tree().has_group("camera_controller"):
		get_tree().call_group("camera_controller", "add_shake", 8.0, 0.5)

func _respawn_platform(platform_data: Dictionary):
	"""Respawn a collapsed platform"""
	platform_data.collapsed = false
	platform_data.warning_active = false
	platform_data.collapse_timer = 0.0
	
	var area = platform_data.area
	var collision = area.get_child(0) as CollisionShape2D
	if collision:
		collision.disabled = false

func _setup_magma_bursts():
	"""Initialize magma burst locations"""
	burst_locations = [
		Vector2(800, 900),
		Vector2(1500, 850),
		Vector2(2200, 920),
		Vector2(2800, 880)
	]

func _update_magma_bursts(delta):
	"""Update magma burst timing"""
	burst_timer += delta
	
	if burst_timer >= burst_interval:
		burst_timer = 0.0
		_trigger_random_magma_burst()

func _trigger_random_magma_burst():
	"""Trigger a magma burst at a random location"""
	if burst_locations.is_empty():
		return
		
	var burst_pos = burst_locations[randi() % burst_locations.size()]
	_create_magma_burst(burst_pos)

func _create_magma_burst(position: Vector2):
	"""Create a magma burst effect at the specified position"""
	var burst_sprite = AnimatedSprite2D.new()
	magma_burst_container.add_child(burst_sprite)
	burst_sprite.position = position
	
	# Create burst particles
	var burst_particles = GPUParticles2D.new()
	burst_sprite.add_child(burst_particles)
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 150.0
	material.initial_velocity_max = 300.0
	material.gravity = Vector3(0, 200, 0)
	material.spread = 60.0
	
	# Bright lava colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.9, 0.3, 1.0))  # Bright yellow
	gradient.add_point(0.3, Color(1.0, 0.5, 0.1, 1.0))  # Orange
	gradient.add_point(0.7, Color(0.8, 0.2, 0.0, 0.8))  # Red
	gradient.add_point(1.0, Color(0.4, 0.1, 0.0, 0.0))  # Dark fade
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	burst_particles.process_material = material
	burst_particles.amount = 100
	burst_particles.lifetime = 1.5
	burst_particles.emitting = true
	burst_particles.one_shot = true
	
	# Add light effect
	var burst_light = Light2D.new()
	burst_sprite.add_child(burst_light)
	burst_light.color = Color(1.0, 0.6, 0.2, 1.0)
	burst_light.energy = 2.0
	burst_light.texture_scale = 3.0
	
	# Animate light intensity
	var tween = create_tween()
	tween.tween_property(burst_light, "energy", 0.0, 2.0)
	tween.tween_callback(burst_sprite.queue_free)

func _setup_room_manager():
	"""Configure room-specific settings"""
	if room_manager:
		room_manager.room_name = "Infernal Depths Room"
		room_manager.biome_type = "Infernal Depths"
		room_manager.music_cue = "infernal_depths"
		room_manager.ambient_sound = "lava_bubbling"

func _create_ember_texture() -> ImageTexture:
	"""Create glowing ember texture with bright center"""
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	
	for x in range(8):
		for y in range(8):
			var center = Vector2(4, 4)
			var pos = Vector2(x, y)
			var dist = (pos - center).length()
			
			if dist <= 2:
				image.set_pixel(x, y, Color(1.0, 0.8, 0.2, 1.0))  # Bright center
			elif dist <= 3:
				image.set_pixel(x, y, Color(1.0, 0.4, 0.1, 0.8))  # Orange edge
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_smoke_texture() -> ImageTexture:
	"""Create wispy smoke texture"""
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	# Create irregular smoke shape
	for x in range(16):
		for y in range(16):
			var noise_val = sin(x * 0.3) * cos(y * 0.4) * 0.5 + 0.5
			if noise_val > 0.2:
				var alpha = noise_val * 0.6
				image.set_pixel(x, y, Color(0.2, 0.1, 0.1, alpha))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func trigger_eruption():
	"""Special effect: massive eruption with multiple bursts"""
	# Trigger multiple simultaneous bursts
	for pos in burst_locations:
		_create_magma_burst(pos)
		await get_tree().create_timer(0.2).timeout
	
	# Intensify all particle effects temporarily
	var original_ember_amount = ember_particles.amount
	var original_smoke_amount = smoke_particles.amount
	
	ember_particles.amount = original_ember_amount * 3
	smoke_particles.amount = original_smoke_amount * 2
	
	# Restore after eruption
	await get_tree().create_timer(8.0).timeout
	ember_particles.amount = original_ember_amount
	smoke_particles.amount = original_smoke_amount

func set_infernal_intensity(intensity: float):
	"""Adjust overall infernal atmosphere intensity"""
	# Adjust particle counts
	if ember_particles:
		ember_particles.amount = int(ember_count * intensity)
	if smoke_particles:
		smoke_particles.amount = int(smoke_count * intensity)
	
	# Adjust lighting
	if lava_glow_light:
		lava_glow_light.energy = 1.5 * intensity
	
	# Adjust shader effects
	if lava_glow_material:
		lava_glow_material.set_shader_parameter("glow_intensity", 0.25 * intensity)
	
	if scanline_material:
		scanline_material.set_shader_parameter("intensity", 0.1 * intensity)