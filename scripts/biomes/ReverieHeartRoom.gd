extends Node2D
class_name ReverieHeartRoom

## Reverie's Heart Room - Final dream nexus biome with morphing geometry and surreal effects
## Features shifting fragments, space warp effects, dream haze particles, and dynamic room morphing

@export var dream_haze_count: int = 350
@export var fragment_count: int = 50
@export var morph_interval: float = 12.0
@export var warp_intensity: float = 0.03

# Node references
@onready var parallax_bg: ParallaxController = $ParallaxBackground
@onready var fragment_multimesh: MultiMeshInstance2D = $FloatingFragments
@onready var surreal_tiles: TileMap = $SurrealGroundTiles
@onready var dream_haze_particles: GPUParticles2D = $DreamHazeParticles
@onready var space_warp_rect: ColorRect = $SpaceWarpShader
@onready var pulse_light: Light2D = $PulseLight
@onready var memory_echo_container: Node2D = $MemoryEchoContainer
@onready var room_morph_animation: AnimationPlayer = $RoomMorphAnimation
@onready var room_manager: RoomManager = $RoomManager

# Fragment system
var fragment_transforms: Array[Transform2D] = []
var fragment_velocities: Array[Vector2] = []
var fragment_rotation_speeds: Array[float] = []

# Morphing system
var morph_timer: float = 0.0
var is_morphing: bool = false
var morph_targets: Array[Vector2] = []

# Memory echo system
var memory_echoes: Array[Dictionary] = []
var echo_spawn_timer: float = 0.0
var echo_spawn_interval: float = 3.0

# Shader materials
var space_warp_material: ShaderMaterial
var fragment_shimmer_material: ShaderMaterial

# Audio cues for memory echoes
var memory_audio_clips: Array[String] = [
	"whisper_1", "whisper_2", "distant_voice", "echo_laugh", "forgotten_word"
]

func _ready():
	_setup_parallax()
	_setup_particles()
	_setup_lighting()
	_setup_shaders()
	_setup_fragments()
	_setup_morphing_system()
	_setup_memory_echoes()
	_setup_room_manager()

func _process(delta):
	_update_fragments(delta)
	_update_morphing(delta)
	_update_memory_echoes(delta)

func _setup_parallax():
	"""Configure parallax for dream nexus atmosphere"""
	if parallax_bg:
		parallax_bg.set_biome_config("Reverie's Heart")

func _setup_particles():
	"""Initialize dream haze particle system"""
	_setup_dream_haze_particles()

func _setup_dream_haze_particles():
	"""Configure ethereal dream haze particles"""
	if not dream_haze_particles:
		return
		
	var material = ParticleProcessMaterial.new()
	
	# Very slow, multi-directional movement
	material.direction = Vector3(0, 0, 0)
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 20.0
	material.angular_velocity_min = -30.0
	material.angular_velocity_max = 30.0
	
	# Minimal gravity
	material.gravity = Vector3(0, -5, 0)
	
	# Large, ethereal particles
	material.scale_min = 1.2
	material.scale_max = 2.5
	material.scale_random = 0.8
	
	# Dream colors - purple to blue with additive glow
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.3, 0.9, 0.8))  # Purple
	gradient.add_point(0.3, Color(0.4, 0.6, 1.0, 0.7))  # Blue
	gradient.add_point(0.7, Color(0.8, 0.5, 0.9, 0.5))  # Pink
	gradient.add_point(1.0, Color(0.5, 0.7, 1.0, 0.0))  # Fade to transparent blue
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Wide emission area
	material.emission = Emission.EMISSION_BOX
	material.emission_box_extents = Vector3(1500, 800, 0)
	
	dream_haze_particles.process_material = material
	dream_haze_particles.amount = dream_haze_count
	dream_haze_particles.lifetime = randf_range(6.0, 12.0)
	dream_haze_particles.emitting = true
	
	if not dream_haze_particles.texture:
		dream_haze_particles.texture = _create_dream_haze_texture()

func _setup_lighting():
	"""Configure pulsing dream light"""
	if pulse_light:
		pulse_light.color = Color(0.7, 0.5, 1.0, 1.0)  # Purple-pink dream light
		pulse_light.energy = 1.0
		pulse_light.texture_scale = 6.0
		
		# Animate pulsing
		_animate_pulse_light()

func _animate_pulse_light():
	"""Create rhythmic pulsing light effect"""
	if not pulse_light:
		return
		
	var tween = create_tween()
	tween.set_loops()
	
	var base_energy = pulse_light.energy
	# Heartbeat-like rhythm
	tween.tween_property(pulse_light, "energy", base_energy * 1.8, 0.3)
	tween.tween_property(pulse_light, "energy", base_energy * 0.6, 0.4)
	tween.tween_property(pulse_light, "energy", base_energy * 1.5, 0.2)
	tween.tween_property(pulse_light, "energy", base_energy, 0.8)
	tween.tween_delay(1.2)

func _setup_shaders():
	"""Initialize space warp and fragment shimmer shaders"""
	_setup_space_warp_shader()
	_setup_fragment_shimmer()

func _setup_space_warp_shader():
	"""Create space warping/swirl shader effect"""
	if not space_warp_rect:
		return
		
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float speed : hint_range(0.0, 2.0) = 0.4;
uniform float strength : hint_range(0.0, 0.1) = 0.03;
uniform float swirl_center_x : hint_range(0.0, 1.0) = 0.5;
uniform float swirl_center_y : hint_range(0.0, 1.0) = 0.5;

float noise(vec2 p) {
    return sin(p.x * 6.0 + TIME * speed) * sin(p.y * 4.0 + TIME * speed * 0.7) * 0.5 + 0.5;
}

void fragment() {
    vec2 uv = UV - vec2(swirl_center_x, swirl_center_y);
    float r = length(uv);
    float angle = TIME * speed + noise(uv * 3.0 + TIME * 0.1) * 6.2831;
    vec2 offset = vec2(cos(angle), sin(angle)) * (strength * (1.0 - r));
    vec2 coord = UV + offset;
    COLOR = texture(SCREEN_TEXTURE, coord);
}
"""
	
	space_warp_material = ShaderMaterial.new()
	space_warp_material.shader = shader
	space_warp_material.set_shader_parameter("speed", 0.4)
	space_warp_material.set_shader_parameter("strength", warp_intensity)
	space_warp_material.set_shader_parameter("swirl_center_x", 0.5)
	space_warp_material.set_shader_parameter("swirl_center_y", 0.5)
	
	space_warp_rect.material = space_warp_material

func _setup_fragment_shimmer():
	"""Create shimmer effect for floating fragments"""
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float shimmer_speed : hint_range(0.0, 5.0) = 1.5;
uniform float hue_shift : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 uv = UV;
    vec4 base = texture(TEXTURE, uv);
    
    float shimmer = sin(TIME * shimmer_speed + uv.x * 10.0) * 0.5 + 0.5;
    float hue_offset = sin(TIME * shimmer_speed * 0.7) * hue_shift;
    
    // Simple hue shift approximation
    vec3 shifted = base.rgb;
    shifted.r += hue_offset;
    shifted.g += hue_offset * 0.5;
    shifted.b += hue_offset * -0.5;
    
    COLOR = vec4(shifted, base.a) + vec4(vec3(shimmer * 0.3), 0.0);
}
"""
	
	fragment_shimmer_material = ShaderMaterial.new()
	fragment_shimmer_material.shader = shader
	fragment_shimmer_material.set_shader_parameter("shimmer_speed", 1.5)
	fragment_shimmer_material.set_shader_parameter("hue_shift", 0.1)

func _setup_fragments():
	"""Initialize floating fragment system"""
	if not fragment_multimesh:
		return
		
	# Create MultiMesh for efficient rendering of many fragments
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.instance_count = fragment_count
	multimesh.mesh = _create_fragment_mesh()
	
	fragment_multimesh.multimesh = multimesh
	
	# Initialize fragment data
	_initialize_fragment_transforms()

func _create_fragment_mesh() -> Mesh:
	"""Create mesh for fragment instances"""
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(32, 32)
	return quad_mesh

func _initialize_fragment_transforms():
	"""Initialize positions and movement for fragments"""
	fragment_transforms.clear()
	fragment_velocities.clear()
	fragment_rotation_speeds.clear()
	
	for i in range(fragment_count):
		# Random positions across the room
		var transform = Transform2D()
		transform.origin = Vector2(
			randf_range(0, 3000),
			randf_range(0, 2000)
		)
		transform = transform.rotated(randf() * TAU)
		transform = transform.scaled(Vector2(randf_range(0.5, 2.0), randf_range(0.5, 2.0)))
		
		fragment_transforms.append(transform)
		
		# Random velocities
		fragment_velocities.append(Vector2(
			randf_range(-20, 20),
			randf_range(-15, 15)
		))
		
		# Random rotation speeds
		fragment_rotation_speeds.append(randf_range(-1.0, 1.0))
		
		# Set initial transform in MultiMesh
		if fragment_multimesh.multimesh:
			fragment_multimesh.multimesh.set_instance_transform_2d(i, transform)

func _update_fragments(delta):
	"""Update floating fragment positions and rotations"""
	if not fragment_multimesh.multimesh:
		return
		
	for i in range(fragment_transforms.size()):
		# Update position
		fragment_transforms[i].origin += fragment_velocities[i] * delta
		
		# Update rotation
		fragment_transforms[i] = fragment_transforms[i].rotated(fragment_rotation_speeds[i] * delta)
		
		# Wrap around screen boundaries
		if fragment_transforms[i].origin.x > 3200:
			fragment_transforms[i].origin.x = -200
		elif fragment_transforms[i].origin.x < -200:
			fragment_transforms[i].origin.x = 3200
			
		if fragment_transforms[i].origin.y > 2200:
			fragment_transforms[i].origin.y = -200
		elif fragment_transforms[i].origin.y < -200:
			fragment_transforms[i].origin.y = 2200
		
		# Apply transform to MultiMesh
		fragment_multimesh.multimesh.set_instance_transform_2d(i, fragment_transforms[i])

func _setup_morphing_system():
	"""Initialize room morphing system"""
	_create_morph_targets()

func _create_morph_targets():
	"""Create target positions for morphing fragments"""
	morph_targets.clear()
	
	# Create interesting patterns for fragments to move to
	var patterns = [
		_create_spiral_pattern(),
		_create_wave_pattern(),
		_create_circle_pattern(),
		_create_random_pattern()
	]
	
	morph_targets = patterns[randi() % patterns.size()]

func _create_spiral_pattern() -> Array[Vector2]:
	"""Create spiral pattern for fragment morphing"""
	var pattern: Array[Vector2] = []
	var center = Vector2(1500, 1000)
	
	for i in range(fragment_count):
		var angle = (i / float(fragment_count)) * TAU * 3  # 3 full rotations
		var radius = 200 + (i / float(fragment_count)) * 400
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		pattern.append(pos)
	
	return pattern

func _create_wave_pattern() -> Array[Vector2]:
	"""Create wave pattern for fragment morphing"""
	var pattern: Array[Vector2] = []
	
	for i in range(fragment_count):
		var x = (i / float(fragment_count)) * 3000
		var y = 1000 + sin(x * 0.01) * 300
		pattern.append(Vector2(x, y))
	
	return pattern

func _create_circle_pattern() -> Array[Vector2]:
	"""Create circular pattern for fragment morphing"""
	var pattern: Array[Vector2] = []
	var center = Vector2(1500, 1000)
	var radius = 400
	
	for i in range(fragment_count):
		var angle = (i / float(fragment_count)) * TAU
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		pattern.append(pos)
	
	return pattern

func _create_random_pattern() -> Array[Vector2]:
	"""Create random pattern for fragment morphing"""
	var pattern: Array[Vector2] = []
	
	for i in range(fragment_count):
		pattern.append(Vector2(
			randf_range(200, 2800),
			randf_range(200, 1800)
		))
	
	return pattern

func _update_morphing(delta):
	"""Update room morphing system"""
	morph_timer += delta
	
	if morph_timer >= morph_interval and not is_morphing:
		_trigger_room_morph()

func _trigger_room_morph():
	"""Trigger room morphing sequence"""
	is_morphing = true
	morph_timer = 0.0
	
	print("Reverie's Heart is morphing...")
	
	# Create new morph targets
	_create_morph_targets()
	
	# Animate fragments to new positions
	var tween = create_tween()
	tween.set_parallel(true)
	
	for i in range(min(fragment_transforms.size(), morph_targets.size())):
		var start_pos = fragment_transforms[i].origin
		var target_pos = morph_targets[i]
		
		tween.tween_method(
			_update_fragment_position.bind(i),
			start_pos,
			target_pos,
			2.0
		)
	
	# Visual effects during morph
	_add_morph_effects()
	
	# Complete morph
	tween.tween_callback(_complete_morph).set_delay(2.0)

func _update_fragment_position(index: int, position: Vector2):
	"""Update specific fragment position during morphing"""
	if index < fragment_transforms.size():
		fragment_transforms[index].origin = position
		if fragment_multimesh.multimesh:
			fragment_multimesh.multimesh.set_instance_transform_2d(index, fragment_transforms[index])

func _add_morph_effects():
	"""Add visual effects during room morphing"""
	# Intensify space warp
	if space_warp_material:
		var tween = create_tween()
		tween.tween_method(
			_set_warp_strength,
			warp_intensity,
			warp_intensity * 3.0,
			1.0
		)
		tween.tween_method(
			_set_warp_strength,
			warp_intensity * 3.0,
			warp_intensity,
			1.0
		)
	
	# Pulse light intensely
	if pulse_light:
		var tween = create_tween()
		tween.tween_property(pulse_light, "energy", pulse_light.energy * 2.0, 0.5)
		tween.tween_property(pulse_light, "energy", pulse_light.energy, 1.5)

func _set_warp_strength(strength: float):
	"""Set space warp shader strength"""
	if space_warp_material:
		space_warp_material.set_shader_parameter("strength", strength)

func _complete_morph():
	"""Complete room morphing sequence"""
	is_morphing = false
	print("Room morph complete")

func _setup_memory_echoes():
	"""Initialize memory echo system"""
	_create_memory_echo_spawn_points()

func _create_memory_echo_spawn_points():
	"""Create spawn points for memory echoes"""
	# These would be locations where memory fragments appear with audio
	pass

func _update_memory_echoes(delta):
	"""Update memory echo system"""
	echo_spawn_timer += delta
	
	if echo_spawn_timer >= echo_spawn_interval:
		echo_spawn_timer = 0.0
		_spawn_memory_echo()

func _spawn_memory_echo():
	"""Spawn a memory echo with visual and audio"""
	var echo_position = Vector2(
		randf_range(300, 2700),
		randf_range(300, 1700)
	)
	
	_create_memory_echo(echo_position)

func _create_memory_echo(position: Vector2):
	"""Create a memory echo at the specified position"""
	var echo_sprite = Sprite2D.new()
	memory_echo_container.add_child(echo_sprite)
	
	echo_sprite.position = position
	echo_sprite.texture = _create_memory_echo_texture()
	echo_sprite.modulate = Color(0.8, 0.6, 1.0, 0.6)
	
	# Apply shimmer effect
	echo_sprite.material = fragment_shimmer_material
	
	# Fade in, hold, fade out
	var tween = create_tween()
	echo_sprite.modulate.a = 0.0
	tween.tween_property(echo_sprite, "modulate:a", 0.6, 0.5)
	tween.tween_delay(2.0)
	tween.tween_property(echo_sprite, "modulate:a", 0.0, 1.0)
	tween.tween_callback(echo_sprite.queue_free)
	
	# Play audio cue (would integrate with audio system)
	var audio_cue = memory_audio_clips[randi() % memory_audio_clips.size()]
	print("Memory echo plays: ", audio_cue)

func _setup_room_manager():
	"""Configure room-specific settings"""
	if room_manager:
		room_manager.room_name = "Reverie's Heart"
		room_manager.biome_type = "Reverie's Heart"
		room_manager.music_cue = "reverie_heart_theme"
		room_manager.ambient_sound = "dream_ambience"

func _create_dream_haze_texture() -> ImageTexture:
	"""Create ethereal dream haze texture"""
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	
	# Create soft, organic shape
	for x in range(24):
		for y in range(24):
			var center = Vector2(12, 12)
			var pos = Vector2(x, y)
			var dist = (pos - center).length()
			
			if dist <= 10:
				var alpha = 1.0 - (dist / 10.0)
				alpha *= 0.7  # Overall transparency
				var noise = sin(x * 0.3) * cos(y * 0.4) * 0.2 + 0.8
				image.set_pixel(x, y, Color(0.6, 0.4, 0.9, alpha * noise))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_memory_echo_texture() -> ImageTexture:
	"""Create memory echo texture"""
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	# Create crystalline memory fragment shape
	for x in range(16):
		for y in range(16):
			var center = Vector2(8, 8)
			var pos = Vector2(x, y)
			var dist = (pos - center).length()
			
			if dist <= 6:
				var facet = int((atan2(pos.y - center.y, pos.x - center.x) + PI) / (PI/3)) % 6
				var alpha = 0.8 - (dist / 6.0) * 0.3
				var brightness = 0.7 + (facet % 2) * 0.3
				image.set_pixel(x, y, Color(brightness, brightness * 0.8, brightness, alpha))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func trigger_final_boss_mode():
	"""Activate final boss arena mode with intense effects"""
	print("Reverie's Heart enters final boss mode!")
	
	# Intensify all effects
	if dream_haze_particles:
		dream_haze_particles.amount = dream_haze_count * 2
	
	# Accelerate morphing
	morph_interval = 6.0
	
	# Increase warp intensity
	warp_intensity = 0.06
	if space_warp_material:
		space_warp_material.set_shader_parameter("strength", warp_intensity)
	
	# More frequent memory echoes
	echo_spawn_interval = 1.5
	
	# Dramatic lighting
	if pulse_light:
		pulse_light.energy = 2.0

func set_dream_intensity(intensity: float):
	"""Adjust overall dream atmosphere intensity"""
	# Adjust particle count
	if dream_haze_particles:
		dream_haze_particles.amount = int(dream_haze_count * intensity)
	
	# Adjust warp strength
	var warp_strength = warp_intensity * intensity
	if space_warp_material:
		space_warp_material.set_shader_parameter("strength", warp_strength)
	
	# Adjust lighting
	if pulse_light:
		pulse_light.energy = 1.0 * intensity
	
	# Adjust fragment movement speed
	for i in range(fragment_velocities.size()):
		fragment_velocities[i] = fragment_velocities[i].normalized() * (20.0 * intensity)

func reveal_memory_shard(position: Vector2, story_beat: String):
	"""Reveal a story memory shard at the specified position"""
	var shard = Sprite2D.new()
	add_child(shard)
	
	shard.position = position
	shard.texture = _create_memory_echo_texture()
	shard.modulate = Color(1.0, 0.9, 0.6, 0.8)  # Golden memory
	shard.scale = Vector2(2.0, 2.0)
	
	# Add interaction area
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50
	collision.shape = shape
	
	area.add_child(collision)
	shard.add_child(area)
	
	area.body_entered.connect(_on_memory_shard_collected.bind(story_beat, shard))
	
	# Gentle floating animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(shard, "position:y", position.y - 20, 2.0)
	tween.tween_property(shard, "position:y", position.y + 20, 2.0)

func _on_memory_shard_collected(story_beat: String, shard: Node2D, body: Node2D):
	"""Handle memory shard collection"""
	if body.is_in_group("player"):
		print("Memory shard collected: ", story_beat)
		
		# Trigger story revelation
		get_tree().call_group("game_manager", "reveal_story_beat", story_beat)
		
		# Visual collection effect
		var tween = create_tween()
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(shard, "scale", Vector2(4.0, 4.0), 0.5)
		tween.tween_callback(shard.queue_free)