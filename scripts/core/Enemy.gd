extends CharacterBody2D
class_name Enemy

## Base enemy class for Ashes of Reverie
## Handles basic AI, movement, and combat

signal died(enemy: Enemy)
signal player_detected(player: Player)
signal health_changed(new_health: int)

@export var enemy_type: String = "basic"
@export var max_health: int = 50
@export var speed: float = 150.0
@export var damage: int = 20
@export var detection_range: float = 300.0
@export var attack_range: float = 60.0
@export var patrol_distance: float = 200.0
@export var fragment_drop_chance: float = 0.7  # 70% chance to drop fragment
@export var can_dash: bool = true
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 5.0

# AI States
enum AIState { PATROL, CHASE, ATTACK, STUNNED, DASHING }
var current_state: AIState = AIState.PATROL

# State variables
var current_health: int
var player_target: Player
var patrol_origin: Vector2
var patrol_direction: int = 1
var last_player_position: Vector2

# Dash variables
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# Timers
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0
var stun_timer: float = 0.0

# Health bar reference
var health_bar: EnemyHealthBar

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
	
	# Create health bar
	_create_health_bar()

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
	
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			current_state = AIState.CHASE
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

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
		AIState.DASHING:
			_handle_dash_state(delta)

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
	
	var distance = global_position.distance_to(player_target.global_position)
	
	# Try to dash if player is far enough and dash is available
	if can_dash and dash_cooldown_timer <= 0 and distance > 150 and distance < 400:
		_perform_dash()
		return
	
	# Move towards player
	var direction = sign(player_target.global_position.x - global_position.x)
	velocity.x = direction * speed
	
	# Update sprite direction
	sprite.scale.x = direction if direction != 0 else sprite.scale.x
	
	# Check if player is in attack range
	if distance <= attack_range and attack_timer <= 0:
		current_state = AIState.ATTACK

func _handle_attack_state(delta):
	"""Handle attacking player"""
	velocity.x = 0
	
	if player_target and attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_cooldown
	
	# Return to chase after attack
	await get_tree().create_timer(0.5).timeout
	if current_state == AIState.ATTACK:
		current_state = AIState.CHASE

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
		await get_tree().create_timer(2.0).timeout
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
	health_changed.emit(current_health)
	
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
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.RED

func die():
	"""Handle enemy death"""
	print(enemy_type, " enemy died")
	
	# Random chance to drop memory fragment
	if randf() < fragment_drop_chance:
		_drop_memory_fragment()
	
	died.emit(self)
	queue_free()

func _create_health_bar():
	"""Create health bar for this enemy"""
	var health_bar_scene = preload("res://scenes/enemies/EnemyHealthBar.tscn")
	health_bar = health_bar_scene.instantiate()
	get_tree().current_scene.add_child(health_bar)
	health_bar.setup_for_enemy(self)

func _drop_memory_fragment():
	"""Drop a memory fragment at enemy position"""
	var fragment_scene = preload("res://scenes/pickups/MemoryFragment.tscn")
	var fragment = fragment_scene.instantiate()
	fragment.global_position = global_position
	get_tree().current_scene.add_child(fragment)

func _perform_dash():
	"""Perform dash attack towards player"""
	if not player_target or dash_cooldown_timer > 0:
		return
	
	# Calculate dash direction
	dash_direction = (player_target.global_position - global_position).normalized()
	
	# Start dash
	is_dashing = true
	current_state = AIState.DASHING
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Visual effect - change color during dash
	sprite.modulate = Color.YELLOW
	
	print(enemy_type, " enemy dashes!")

func _handle_dash_state(delta):
	"""Handle dash movement"""
	velocity.x = dash_direction.x * dash_speed
	
	# Return to normal color when dash ends
	if dash_timer <= 0:
		sprite.modulate = Color.RED

func _handle_stunned_state(delta):
	"""Handle stunned state (brief pause after taking damage)"""
	velocity.x = 0