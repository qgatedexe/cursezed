extends CharacterBody2D
class_name Enemy

## Base enemy class for Ashes of Reverie
## Handles basic AI, movement, and combat

signal died(enemy: Enemy)
signal player_detected(player: Player)

@export var enemy_type: String = "basic"
@export var max_health: int = 50
@export var speed: float = 150.0
@export var damage: int = 20
@export var detection_range: float = 300.0
@export var attack_range: float = 60.0
@export var patrol_distance: float = 200.0

# AI States
enum AIState { PATROL, CHASE, ATTACK, STUNNED }
var current_state: AIState = AIState.PATROL

# State variables
var current_health: int
var player_target: Player
var patrol_origin: Vector2
var patrol_direction: int = 1
var last_player_position: Vector2

# Timers
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0
var stun_timer: float = 0.0

# References
@onready var sprite: ColorRect = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

func _ready():
	current_health = max_health
	patrol_origin = global_position
	
	# Setup sprite (placeholder)
	sprite.color = Color.RED
	sprite.size = Vector2(32, 48)
	sprite.position = Vector2(-16, -48)
	
	# Setup detection area
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	# Setup attack area
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)

func _physics_process(delta):
	_update_timers(delta)
	_handle_ai_state(delta)
	_handle_gravity(delta)
	
	move_and_slide()

func _update_timers(delta):
	"""Update all timers"""
	if attack_timer > 0:
		attack_timer -= delta
	
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			current_state = AIState.PATROL

func _handle_ai_state(delta):
	"""Handle AI behavior based on current state"""
	match current_state:
		AIState.PATROL:
			_handle_patrol_state(delta)
		AIState.CHASE:
			_handle_chase_state(delta)
		AIState.ATTACK:
			_handle_attack_state(delta)
		AIState.STUNNED:
			_handle_stunned_state(delta)

func _handle_patrol_state(delta):
	"""Handle patrol behavior"""
	# Simple back-and-forth patrol
	var target_x = patrol_origin.x + (patrol_distance * patrol_direction)
	
	if abs(global_position.x - target_x) < 10:
		patrol_direction *= -1
	
	velocity.x = patrol_direction * speed * 0.5
	
	# Update sprite direction
	sprite.scale.x = sign(velocity.x) if velocity.x != 0 else sprite.scale.x

func _handle_chase_state(delta):
	"""Handle chasing player"""
	if not player_target:
		current_state = AIState.PATROL
		return
	
	# Move towards player
	var direction = sign(player_target.global_position.x - global_position.x)
	velocity.x = direction * speed
	
	# Update sprite direction
	sprite.scale.x = direction if direction != 0 else sprite.scale.x
	
	# Check if player is in attack range
	var distance = global_position.distance_to(player_target.global_position)
	if distance <= attack_range and attack_timer <= 0:
		current_state = AIState.ATTACK

func _handle_attack_state(delta):
	"""Handle attacking player"""
	velocity.x = 0
	
	if player_target and attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_cooldown
	
	# Return to chase after attack
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(_return_to_chase_after_attack)

func _return_to_chase_after_attack():
	"""Return to chase state after attack"""
	if current_state == AIState.ATTACK:
		current_state = AIState.CHASE

func _handle_stunned_state(delta):
	"""Handle stunned state (brief pause after taking damage)"""
	velocity.x = 0

func _handle_gravity(delta):
	"""Apply gravity"""
	if not is_on_floor():
		velocity += get_gravity() * delta

func _perform_attack():
	"""Execute attack on player"""
	if player_target:
		player_target.take_damage(damage)
		print(enemy_type, " enemy attacked player for ", damage, " damage")

func _on_detection_area_entered(body):
	"""Handle player entering detection range"""
	if body is Player:
		player_target = body
		current_state = AIState.CHASE
		player_detected.emit(body)
		print(enemy_type, " enemy detected player")

func _on_detection_area_exited(body):
	"""Handle player leaving detection range"""
	if body is Player and body == player_target:
		# Don't immediately lose target - keep chasing for a bit
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(_lose_player_target)

func _lose_player_target():
	"""Lose player target after delay"""
	if current_state == AIState.CHASE:
		player_target = null
		current_state = AIState.PATROL

func _on_attack_area_entered(body):
	"""Handle contact damage to player"""
	if body is Player and attack_timer <= 0:
		body.take_damage(damage)
		attack_timer = attack_cooldown
		print(enemy_type, " enemy dealt contact damage to player")

func take_damage(amount: int):
	"""Take damage and handle health changes"""
	current_health = max(0, current_health - amount)
	
	# Brief stun when taking damage
	current_state = AIState.STUNNED
	stun_timer = 0.3
	
	# Visual feedback
	_damage_feedback()
	
	if current_health <= 0:
		die()

func _damage_feedback():
	"""Provide visual feedback when taking damage"""
	sprite.modulate = Color.WHITE
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func(): sprite.modulate = Color.RED)

func die():
	"""Handle enemy death"""
	print(enemy_type, " enemy died")
	died.emit(self)
	queue_free()