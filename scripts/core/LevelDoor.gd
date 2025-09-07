extends Area2D
class_name LevelDoor

## Level progression door that appears when room is cleared
## Shows next level name and handles transitions

signal door_activated(next_level_name: String)

@export var next_level_name: String = "Luminous Abyss"
@export var is_unlocked: bool = false

@onready var door_sprite: ColorRect = $DoorSprite
@onready var door_collision: CollisionShape2D = $CollisionShape2D
@onready var level_name_label: Label = $LevelNameLabel
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var door_glow: ColorRect = $DoorGlow
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player_in_range: bool = false
var is_transitioning: bool = false

func _ready():
	# Setup door appearance
	_setup_door_visuals()
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Initially hidden
	visible = false
	set_collision_mask_value(1, false)

func _setup_door_visuals():
	"""Setup the visual appearance of the door"""
	# Door sprite (tall rectangle representing door)
	door_sprite.size = Vector2(80, 120)
	door_sprite.position = Vector2(-40, -120)
	door_sprite.color = Color(0.3, 0.2, 0.1, 1.0) if not is_unlocked else Color(0.2, 0.6, 0.8, 1.0)
	
	# Door glow effect
	door_glow.size = Vector2(100, 140)
	door_glow.position = Vector2(-50, -130)
	door_glow.color = Color(0.2, 0.6, 0.8, 0.3)
	door_glow.visible = false
	
	# Level name label above door
	level_name_label.text = next_level_name
	level_name_label.position = Vector2(-100, -160)
	level_name_label.size = Vector2(200, 30)
	level_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_name_label.theme_override_font_sizes["font_size"] = 18
	level_name_label.modulate = Color.CYAN
	
	# Interaction prompt
	interaction_prompt.text = "Press E to Enter"
	interaction_prompt.position = Vector2(-80, 10)
	interaction_prompt.size = Vector2(160, 20)
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.theme_override_font_sizes["font_size"] = 14
	interaction_prompt.visible = false

func appear_when_room_cleared():
	"""Make the door appear with animation when room is cleared"""
	is_unlocked = true
	visible = true
	set_collision_mask_value(1, true)
	
	# Update visuals
	door_sprite.color = Color(0.2, 0.6, 0.8, 1.0)
	door_glow.visible = true
	
	# Entrance animation
	var tween = create_tween()
	scale = Vector2(0.1, 0.1)
	modulate = Color.TRANSPARENT
	
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 1.0)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 1.0)
	
	# Pulsing glow animation
	_start_glow_animation()

func _start_glow_animation():
	"""Start the pulsing glow effect"""
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(door_glow, "modulate:a", 0.6, 1.5)
	glow_tween.tween_property(door_glow, "modulate:a", 0.2, 1.5)

func _process(delta):
	"""Handle input when player is in range"""
	if player_in_range and is_unlocked and not is_transitioning:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
			_activate_door()

func _on_body_entered(body):
	"""Handle player entering door area"""
	if body is Player and is_unlocked:
		player_in_range = true
		interaction_prompt.visible = true
		
		# Highlight effect
		var tween = create_tween()
		tween.tween_property(level_name_label, "scale", Vector2(1.1, 1.1), 0.3)

func _on_body_exited(body):
	"""Handle player leaving door area"""
	if body is Player:
		player_in_range = false
		interaction_prompt.visible = false
		
		# Remove highlight
		var tween = create_tween()
		tween.tween_property(level_name_label, "scale", Vector2.ONE, 0.3)

func _activate_door():
	"""Activate the door transition"""
	if is_transitioning:
		return
	
	is_transitioning = true
	interaction_prompt.visible = false
	
	# Door opening animation
	var tween = create_tween()
	tween.tween_property(door_sprite, "modulate", Color.WHITE, 0.5)
	tween.parallel().tween_property(door_glow, "scale", Vector2(2.0, 2.0), 0.5)
	tween.parallel().tween_property(door_glow, "modulate:a", 1.0, 0.5)
	
	await tween.finished
	
	# Emit signal for level transition
	door_activated.emit(next_level_name)

func set_next_level(level_name: String):
	"""Set the next level name"""
	next_level_name = level_name
	if level_name_label:
		level_name_label.text = level_name