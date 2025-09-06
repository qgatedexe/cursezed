extends Camera2D
class_name CameraController

## Camera controller that follows the player smoothly
## Provides smooth camera movement and optional screen shake

@export var follow_speed: float = 5.0
@export var offset_ahead: float = 100.0
@export var vertical_offset: float = -50.0

var target: Node2D
var base_position: Vector2
var shake_strength: float = 0.0
var shake_duration: float = 0.0

func _ready():
	# Find and follow the player
	make_current()

func set_target(new_target: Node2D):
	"""Set the target to follow"""
	target = new_target

func _process(delta):
	if target:
		_follow_target(delta)
	
	_handle_screen_shake(delta)

func _follow_target(delta):
	"""Smoothly follow the target"""
	var target_pos = target.global_position
	
	# Add offset based on player facing direction if available
	if target.has_method("get_facing_direction"):
		target_pos.x += target.get_facing_direction() * offset_ahead
	
	target_pos.y += vertical_offset
	
	# Smooth movement
	global_position = global_position.lerp(target_pos, follow_speed * delta)

func _handle_screen_shake(delta):
	"""Handle screen shake effect"""
	if shake_duration > 0:
		shake_duration -= delta
		
		# Random shake offset
		var shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		
		offset = shake_offset
		
		# Reduce shake strength over time
		shake_strength = lerp(shake_strength, 0.0, delta * 5.0)
	else:
		offset = Vector2.ZERO

func add_screen_shake(strength: float, duration: float):
	"""Add screen shake effect"""
	shake_strength = max(shake_strength, strength)
	shake_duration = max(shake_duration, duration)