extends CharacterBody2D
class_name Player

## The Wanderer - Main player character for Ashes of Reverie
## Handles movement, combat, and abilities

signal health_changed(new_health: int)
signal died
signal memory_collected(amount: int)

# Movement constants
@export var speed: float = 400.0
@export var jump_velocity: float = -600.0
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

# Combat constants
@export var max_health: int = 100
@export var melee_damage: int = 25
@export var melee_range: float = 80.0
@export var ranged_damage: int = 15
@export var attack_cooldown: float = 0.5

# State variables
var current_health: int
var can_double_jump: bool = true
var is_dashing: bool = false
var can_dash: bool = true
var can_attack: bool = true
var facing_direction: int = 1 # 1 for right, -1 for left

# Timers
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var attack_cooldown_timer: float = 0.0

# References
@onready var sprite: ColorRect = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var melee_area: Area2D = $MeleeArea
@onready var melee_collision: CollisionShape2D = $MeleeArea/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Projectile scene
var dream_bolt_scene = preload("res://scenes/player/DreamBolt.tscn")

func _ready():
	current_health = max_health
	
	# Setup melee area
	melee_area.body_entered.connect(_on_melee_area_entered)
	
	# Setup sprite (placeholder colored rectangle)
	sprite.color = Color.CYAN
	sprite.size = Vector2(40, 60)
	sprite.position = Vector2(-20, -60)

func _physics_process(delta):
	_handle_timers(delta)
	_handle_input()
	_handle_movement(delta)
	_handle_gravity(delta)
	
	move_and_slide()
	
	_update_sprite_direction()

func _handle_timers(delta):
	"""Update all timers"""
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true
	
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true

func _handle_input():
	"""Process player input"""
	# Dash
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		_perform_dash()
	
	# Melee attack
	if Input.is_action_just_pressed("melee_attack") and can_attack:
		_perform_melee_attack()
	
	# Ranged attack
	if Input.is_action_just_pressed("ranged_attack") and can_attack:
		_perform_ranged_attack()

func _handle_movement(delta):
	"""Handle player movement"""
	if is_dashing:
		# During dash, maintain dash velocity
		velocity.x = dash_speed * facing_direction
		return
	
	# Horizontal movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = direction * speed
		facing_direction = sign(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 3 * delta)
	
	# Jumping
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
			can_double_jump = true
		elif can_double_jump:
			velocity.y = jump_velocity * 0.8
			can_double_jump = false

func _handle_gravity(delta):
	"""Apply gravity when not on floor"""
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		can_double_jump = true

func _perform_dash():
	"""Execute dash ability"""
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Brief invincibility during dash could be added here
	print("Dash!")

func _perform_melee_attack():
	"""Execute melee slash attack"""
	can_attack = false
	attack_cooldown_timer = attack_cooldown
	
	# Enable melee hitbox briefly
	melee_collision.disabled = false
	
	# Disable hitbox after brief moment
	await get_tree().create_timer(0.1).timeout
	melee_collision.disabled = true
	
	print("Melee attack!")

func _perform_ranged_attack():
	"""Execute ranged dream-bolt attack"""
	can_attack = false
	attack_cooldown_timer = attack_cooldown
	
	# Create dream bolt projectile
	var dream_bolt = dream_bolt_scene.instantiate()
	get_tree().current_scene.add_child(dream_bolt)
	
	# Position and aim the projectile
	dream_bolt.global_position = global_position + Vector2(0, -20)
	
	# Aim towards mouse cursor
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - dream_bolt.global_position).normalized()
	dream_bolt.setup(direction, ranged_damage)
	
	print("Dream bolt fired!")

func _update_sprite_direction():
	"""Update sprite to face movement direction"""
	if facing_direction > 0:
		sprite.scale.x = 1
	else:
		sprite.scale.x = -1

func _on_melee_area_entered(body):
	"""Handle melee attack hitting something"""
	if body.has_method("take_damage") and body != self:
		body.take_damage(melee_damage)
		print("Melee hit: ", body.name)

func take_damage(amount: int):
	"""Take damage and handle health changes"""
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	
	# Visual feedback (could add screen shake, damage numbers, etc.)
	_damage_feedback()
	
	if current_health <= 0:
		die()

func _damage_feedback():
	"""Provide visual feedback when taking damage"""
	# Flash red briefly
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

func heal(amount: int):
	"""Heal the player"""
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func die():
	"""Handle player death"""
	print("Player died!")
	died.emit()

func collect_memory_fragment(amount: int = 1):
	"""Collect memory fragments"""
	memory_collected.emit(amount)
	print("Collected ", amount, " memory fragment(s)")

func reset_health():
	"""Reset player to full health"""
	current_health = max_health
	health_changed.emit(current_health)

func get_facing_direction() -> int:
	"""Get the direction the player is facing"""
	return facing_direction