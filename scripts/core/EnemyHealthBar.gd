extends Control
class_name EnemyHealthBar

## Health bar that appears above enemies
## Shows current health and damage feedback

@onready var background: ColorRect = $Background
@onready var health_fill: ColorRect = $HealthFill
@onready var damage_flash: ColorRect = $DamageFlash

var target_enemy: Enemy
var max_health: int = 100
var current_health: int = 100
var is_visible_timer: float = 0.0
var show_duration: float = 3.0

func _ready():
	# Setup visual elements
	_setup_health_bar()
	
	# Initially hidden
	modulate = Color.TRANSPARENT

func _setup_health_bar():
	"""Setup the visual appearance of the health bar"""
	# Background
	background.color = Color.BLACK
	background.size = Vector2(60, 8)
	background.position = Vector2(-30, -4)
	
	# Health fill
	health_fill.color = Color.GREEN
	health_fill.size = Vector2(58, 6)
	health_fill.position = Vector2(-29, -3)
	
	# Damage flash
	damage_flash.color = Color.RED
	damage_flash.size = Vector2(58, 6)
	damage_flash.position = Vector2(-29, -3)
	damage_flash.modulate = Color.TRANSPARENT

func setup_for_enemy(enemy: Enemy):
	"""Setup this health bar for a specific enemy"""
	target_enemy = enemy
	max_health = enemy.max_health
	current_health = enemy.current_health
	
	# Connect to enemy's health changes
	if enemy.has_signal("health_changed"):
		enemy.health_changed.connect(_on_enemy_health_changed)
	
	# Connect to enemy death
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _process(delta):
	"""Update health bar position and visibility"""
	if target_enemy and is_instance_valid(target_enemy):
		# Follow enemy position
		global_position = target_enemy.global_position + Vector2(0, -60)
		
		# Handle visibility timer
		if is_visible_timer > 0:
			is_visible_timer -= delta
			if is_visible_timer <= 0:
				_hide_health_bar()
	else:
		# Enemy is gone, remove health bar
		queue_free()

func _on_enemy_health_changed(new_health: int):
	"""Handle enemy health changes"""
	current_health = new_health
	_update_health_display()
	_show_health_bar()
	_flash_damage()

func _on_enemy_died(enemy: Enemy):
	"""Handle enemy death"""
	_hide_health_bar()
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _update_health_display():
	"""Update the visual health bar"""
	var health_percent = float(current_health) / float(max_health)
	var new_width = 58 * health_percent
	
	# Animate health bar shrinking
	var tween = create_tween()
	tween.tween_property(health_fill, "size:x", new_width, 0.3)
	
	# Color coding based on health
	if health_percent <= 0.25:
		health_fill.color = Color.RED
	elif health_percent <= 0.5:
		health_fill.color = Color.YELLOW
	else:
		health_fill.color = Color.GREEN

func _show_health_bar():
	"""Show the health bar with fade in"""
	is_visible_timer = show_duration
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func _hide_health_bar():
	"""Hide the health bar with fade out"""
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)

func _flash_damage():
	"""Flash red when taking damage"""
	var tween = create_tween()
	tween.tween_property(damage_flash, "modulate", Color(1, 0, 0, 0.7), 0.1)
	tween.tween_property(damage_flash, "modulate", Color.TRANSPARENT, 0.3)

func force_show():
	"""Force show the health bar (used when enemy is first detected)"""
	_show_health_bar()