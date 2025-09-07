extends Node
class_name ParticlePool

## Particle Pool - Manages reusable particle systems for better performance
## Pools GPUParticles2D instances to avoid frequent instantiation/destruction

signal pool_exhausted(particle_type: String)

# Pool configuration
@export var max_pool_size: int = 50
@export var initial_pool_size: int = 10

# Particle pools by type
var particle_pools: Dictionary = {}
var active_particles: Dictionary = {}

# Particle type definitions
enum ParticleType {
	SPORE,
	LEAF,
	ASH,
	EMBER,
	BUBBLE,
	DRIFT,
	DUST,
	SMOKE,
	DREAM_HAZE,
	MEMORY_ECHO,
	EXPLOSION,
	SPARK
}

var particle_type_names: Dictionary = {
	ParticleType.SPORE: "spore",
	ParticleType.LEAF: "leaf",
	ParticleType.ASH: "ash",
	ParticleType.EMBER: "ember",
	ParticleType.BUBBLE: "bubble",
	ParticleType.DRIFT: "drift",
	ParticleType.DUST: "dust",
	ParticleType.SMOKE: "smoke",
	ParticleType.DREAM_HAZE: "dream_haze",
	ParticleType.MEMORY_ECHO: "memory_echo",
	ParticleType.EXPLOSION: "explosion",
	ParticleType.SPARK: "spark"
}

func _ready():
	_initialize_pools()

func _initialize_pools():
	"""Initialize particle pools for each type"""
	for particle_type in ParticleType.values():
		var type_name = particle_type_names[particle_type]
		particle_pools[type_name] = []
		active_particles[type_name] = []
		
		# Pre-populate pools
		for i in range(initial_pool_size):
			var particle = _create_particle_system(particle_type)
			particle_pools[type_name].append(particle)

func _create_particle_system(particle_type: ParticleType) -> GPUParticles2D:
	"""Create a new particle system of the specified type"""
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	
	# Configure based on particle type
	match particle_type:
		ParticleType.SPORE:
			_configure_spore_particles(particles, material)
		ParticleType.LEAF:
			_configure_leaf_particles(particles, material)
		ParticleType.ASH:
			_configure_ash_particles(particles, material)
		ParticleType.EMBER:
			_configure_ember_particles(particles, material)
		ParticleType.BUBBLE:
			_configure_bubble_particles(particles, material)
		ParticleType.DRIFT:
			_configure_drift_particles(particles, material)
		ParticleType.DUST:
			_configure_dust_particles(particles, material)
		ParticleType.SMOKE:
			_configure_smoke_particles(particles, material)
		ParticleType.DREAM_HAZE:
			_configure_dream_haze_particles(particles, material)
		ParticleType.MEMORY_ECHO:
			_configure_memory_echo_particles(particles, material)
		ParticleType.EXPLOSION:
			_configure_explosion_particles(particles, material)
		ParticleType.SPARK:
			_configure_spark_particles(particles, material)
	
	particles.process_material = material
	particles.emitting = false
	add_child(particles)
	
	return particles

func get_particle_system(particle_type: String, position: Vector2 = Vector2.ZERO) -> GPUParticles2D:
	"""Get an available particle system from the pool"""
	var pool = particle_pools.get(particle_type, [])
	
	if pool.is_empty():
		# Try to create new one if under max limit
		var active = active_particles.get(particle_type, [])
		if active.size() < max_pool_size:
			var type_enum = _get_particle_type_enum(particle_type)
			var new_particle = _create_particle_system(type_enum)
			return _activate_particle(new_particle, particle_type, position)
		else:
			pool_exhausted.emit(particle_type)
			return null
	
	var particle = pool.pop_back()
	return _activate_particle(particle, particle_type, position)

func _activate_particle(particle: GPUParticles2D, particle_type: String, position: Vector2) -> GPUParticles2D:
	"""Activate a particle system"""
	particle.position = position
	particle.emitting = true
	particle.restart()
	
	# Move to active list
	active_particles[particle_type].append(particle)
	
	# Auto-return to pool after lifetime (using timer instead of await)
	var lifetime = particle.lifetime
	var timer = get_tree().create_timer(lifetime + 1.0)
	timer.timeout.connect(_return_particle_delayed.bind(particle, particle_type))
	
	return particle

func _return_particle_delayed(particle: GPUParticles2D, particle_type: String):
	"""Return particle to pool after delay"""
	return_particle_system(particle, particle_type)

func return_particle_system(particle: GPUParticles2D, particle_type: String):
	"""Return a particle system to the pool"""
	if not is_instance_valid(particle):
		return
		
	particle.emitting = false
	
	# Move from active to pool
	var active = active_particles.get(particle_type, [])
	active.erase(particle)
	
	var pool = particle_pools.get(particle_type, [])
	pool.append(particle)

func clear_all_particles():
	"""Clear all active particles"""
	for particle_type in active_particles:
		var active = active_particles[particle_type]
		for particle in active:
			if is_instance_valid(particle):
				return_particle_system(particle, particle_type)

func get_pool_stats() -> Dictionary:
	"""Get statistics about pool usage"""
	var stats = {}
	
	for particle_type in particle_pools:
		var pool_size = particle_pools[particle_type].size()
		var active_size = active_particles[particle_type].size()
		
		stats[particle_type] = {
			"pool_size": pool_size,
			"active_count": active_size,
			"total_capacity": pool_size + active_size,
			"utilization": active_size / float(max_pool_size)
		}
	
	return stats

func _get_particle_type_enum(type_name: String) -> ParticleType:
	"""Get ParticleType enum from string name"""
	for type_enum in particle_type_names:
		if particle_type_names[type_enum] == type_name:
			return type_enum
	return ParticleType.SPORE  # Default fallback

# Particle configuration methods
func _configure_spore_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 50
	particles.lifetime = 6.0
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3(0, -10, 0)
	material.scale_min = 0.4
	material.scale_max = 1.0

func _configure_leaf_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 30
	particles.lifetime = 4.0
	material.direction = Vector3(0.3, 1, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, 98, 0)
	material.scale_min = 0.6
	material.scale_max = 1.2

func _configure_ash_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 80
	particles.lifetime = 8.0
	material.direction = Vector3(0.2, 1, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3(0, 50, 0)
	material.scale_min = 0.2
	material.scale_max = 0.6

func _configure_ember_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 40
	particles.lifetime = 1.2
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, -50, 0)
	material.scale_min = 0.4
	material.scale_max = 1.2

func _configure_bubble_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 25
	particles.lifetime = 3.0
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.3
	material.scale_max = 1.2

func _configure_drift_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 20
	particles.lifetime = 10.0
	material.direction = Vector3(0.3, 0.1, 0)
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3(0, 5, 0)
	material.scale_min = 0.8
	material.scale_max = 1.5

func _configure_dust_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 60
	particles.lifetime = 4.0
	material.direction = Vector3(1, 0.1, 0)
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 120.0
	material.gravity = Vector3(0, 20, 0)
	material.scale_min = 0.3
	material.scale_max = 0.8

func _configure_smoke_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 35
	particles.lifetime = 5.0
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, -10, 0)
	material.scale_min = 1.5
	material.scale_max = 3.0

func _configure_dream_haze_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 45
	particles.lifetime = 8.0
	material.direction = Vector3(0, 0, 0)
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 20.0
	material.gravity = Vector3(0, -5, 0)
	material.scale_min = 1.2
	material.scale_max = 2.5

func _configure_memory_echo_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 15
	particles.lifetime = 3.0
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 30.0
	material.gravity = Vector3(0, -15, 0)
	material.scale_min = 0.5
	material.scale_max = 1.0

func _configure_explosion_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 100
	particles.lifetime = 2.0
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0
	material.gravity = Vector3(0, 200, 0)
	material.spread = 45.0
	material.scale_min = 0.5
	material.scale_max = 1.5

func _configure_spark_particles(particles: GPUParticles2D, material: ParticleProcessMaterial):
	particles.amount = 30
	particles.lifetime = 0.8
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 120.0
	material.initial_velocity_max = 200.0
	material.gravity = Vector3(0, 150, 0)
	material.spread = 60.0
	material.scale_min = 0.2
	material.scale_max = 0.6