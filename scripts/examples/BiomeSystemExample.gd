extends Node
## Example script demonstrating how to use the biome system components

# This script shows how to integrate all the biome system components
# and provides example usage patterns for developers

@onready var biome_controller: BiomeController = $BiomeController
@onready var particle_pool: ParticlePool = $ParticlePool

func _ready():
	_setup_biome_system_example()

func _setup_biome_system_example():
	"""Example of setting up the biome system"""
	print("=== Biome System Example ===")
	
	# Connect to biome events
	if biome_controller:
		biome_controller.biome_changed.connect(_on_biome_changed)
		biome_controller.biome_transition_started.connect(_on_biome_transition_started)
		biome_controller.biome_transition_completed.connect(_on_biome_transition_completed)
	
	# Show initial biome status
	_show_biome_progress()
	
	# Example of triggering biome events
	await get_tree().create_timer(2.0).timeout
	_demonstrate_biome_features()

func _on_biome_changed(new_biome: String):
	"""Handle biome change events"""
	print("Biome changed to: ", new_biome)
	
	# Example: Adjust game systems based on biome
	match new_biome:
		"Forgotten Forest":
			_setup_forest_ambience()
		"Ruined City":
			_setup_city_ambience()
		"Drowned Cathedrals":
			_setup_underwater_ambience()
		"Endless Roads":
			_setup_desert_ambience()
		"Infernal Depths":
			_setup_infernal_ambience()
		"Reverie's Heart":
			_setup_dream_ambience()

func _on_biome_transition_started(from_biome: String, to_biome: String):
	"""Handle start of biome transition"""
	print("Transitioning from ", from_biome, " to ", to_biome)
	
	# Example: Show loading screen or transition effect
	_show_transition_effect(from_biome, to_biome)

func _on_biome_transition_completed(biome: String):
	"""Handle completion of biome transition"""
	print("Transition to ", biome, " completed")
	
	# Example: Hide loading screen, start biome music
	_complete_transition(biome)

func _show_biome_progress():
	"""Display current biome progress"""
	if not biome_controller:
		return
		
	var progress = biome_controller.get_biome_progress()
	print("\n=== Biome Progress ===")
	
	for biome_name in progress:
		var data = progress[biome_name]
		print(biome_name, ":")
		print("  Unlocked: ", data.unlocked)
		print("  Visited: ", data.visited)  
		print("  Completed: ", data.completed)
		print("  Progress: ", data.progress_percent, "%")

func _demonstrate_biome_features():
	"""Demonstrate various biome system features"""
	print("\n=== Demonstrating Biome Features ===")
	
	# Example 1: Trigger special biome events
	_demonstrate_special_events()
	
	# Example 2: Show particle pool usage
	await get_tree().create_timer(3.0).timeout
	_demonstrate_particle_system()
	
	# Example 3: Show biome transitions
	await get_tree().create_timer(3.0).timeout
	_demonstrate_biome_transitions()

func _demonstrate_special_events():
	"""Show how to trigger biome-specific events"""
	print("Triggering biome special events...")
	
	if biome_controller:
		# These would trigger different effects based on current biome
		biome_controller.trigger_biome_special_event("spore_burst")
		
		await get_tree().create_timer(2.0).timeout
		biome_controller.trigger_biome_special_event("wind_gust")
		
		await get_tree().create_timer(2.0).timeout
		biome_controller.trigger_biome_special_event("light_pulse")

func _demonstrate_particle_system():
	"""Show how to use the particle pool system"""
	print("Demonstrating particle pool system...")
	
	if not particle_pool:
		return
	
	# Get particle systems from pool
	var spore_particles = particle_pool.get_particle_system("spore", Vector2(100, 100))
	var ember_particles = particle_pool.get_particle_system("ember", Vector2(200, 100))
	var bubble_particles = particle_pool.get_particle_system("bubble", Vector2(300, 100))
	
	# Show pool statistics
	await get_tree().create_timer(1.0).timeout
	var stats = particle_pool.get_pool_stats()
	print("Particle Pool Stats:")
	for particle_type in stats:
		var data = stats[particle_type]
		print("  ", particle_type, ": ", data.active_count, "/", data.total_capacity, " (", data.utilization * 100, "% used)")

func _demonstrate_biome_transitions():
	"""Show how to handle biome transitions"""
	print("Demonstrating biome transitions...")
	
	if not biome_controller:
		return
	
	# Get available biomes from current one
	var available = biome_controller.get_available_biomes()
	print("Available biomes from current: ", available)
	
	# Example transition (would normally be triggered by player action)
	if available.size() > 0:
		var target_biome = available[0]
		print("Attempting transition to: ", biome_controller.biome_names[target_biome])
		
		# This would normally check if biome is unlocked
		biome_controller.unlock_biome(target_biome)
		biome_controller.transition_to_biome(target_biome)

# Biome-specific setup functions
func _setup_forest_ambience():
	"""Setup forest-specific ambience"""
	print("Setting up forest ambience...")
	# Example: Load forest music, adjust lighting, etc.

func _setup_city_ambience():
	"""Setup city-specific ambience"""  
	print("Setting up city ambience...")
	# Example: Load industrial sounds, adjust particle effects

func _setup_underwater_ambience():
	"""Setup underwater-specific ambience"""
	print("Setting up underwater ambience...")
	# Example: Apply audio filters, adjust movement physics

func _setup_desert_ambience():
	"""Setup desert-specific ambience"""
	print("Setting up desert ambience...")
	# Example: Increase heat effects, adjust wind

func _setup_infernal_ambience():
	"""Setup infernal-specific ambience"""
	print("Setting up infernal ambience...")
	# Example: Intense lighting, heat effects

func _setup_dream_ambience():
	"""Setup dream-specific ambience"""
	print("Setting up dream ambience...")
	# Example: Surreal effects, morphing elements

func _show_transition_effect(from_biome: String, to_biome: String):
	"""Show transition visual effect"""
	print("Showing transition effect from ", from_biome, " to ", to_biome)
	
	# Example transition effect
	var screen_fade = ColorRect.new()
	screen_fade.color = Color.BLACK
	screen_fade.size = Vector2(1920, 1080)
	get_tree().current_scene.add_child(screen_fade)
	
	var tween = create_tween()
	screen_fade.modulate.a = 0.0
	tween.tween_property(screen_fade, "modulate:a", 1.0, 0.5)
	tween.tween_delay(1.0)
	tween.tween_property(screen_fade, "modulate:a", 0.0, 0.5)
	tween.tween_callback(screen_fade.queue_free)

func _complete_transition(biome: String):
	"""Complete biome transition"""
	print("Completing transition to ", biome)
	
	# Example: Start biome-specific music
	match biome:
		"Forgotten Forest":
			print("Starting forest music...")
		"Ruined City":
			print("Starting industrial music...")
		"Drowned Cathedrals":
			print("Starting underwater music...")
		"Endless Roads":
			print("Starting desert music...")
		"Infernal Depths":
			print("Starting infernal music...")
		"Reverie's Heart":
			print("Starting dream music...")

# Example input handling for testing biome features
func _input(event):
	"""Example input handling for biome system testing"""
	if not event.is_pressed():
		return
	
	match event.keycode:
		KEY_1:
			# Trigger special event
			if biome_controller:
				biome_controller.trigger_biome_special_event("special_effect")
		
		KEY_2:
			# Get particle system
			if particle_pool:
				var particles = particle_pool.get_particle_system("ember", get_global_mouse_position())
				print("Spawned ember particles at mouse position")
		
		KEY_3:
			# Show biome progress
			_show_biome_progress()
		
		KEY_4:
			# Clear all particles
			if particle_pool:
				particle_pool.clear_all_particles()
				print("Cleared all particles")
		
		KEY_5:
			# Attempt biome transition
			if biome_controller:
				var available = biome_controller.get_available_biomes()
				if available.size() > 0:
					biome_controller.unlock_biome(available[0])
					biome_controller.transition_to_biome(available[0])

func _notification(what):
	"""Handle system notifications"""
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			# Cleanup on exit
			if particle_pool:
				particle_pool.clear_all_particles()
			print("Biome system cleanup completed")
			get_tree().quit()