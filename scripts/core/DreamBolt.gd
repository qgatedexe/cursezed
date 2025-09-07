extends Area2D
class_name DreamBolt

## Dream bolt projectile for ranged attacks
## Travels in a straight line and damages enemies

@export var speed: float = 600.0
@export var lifetime: float = 3.0

var direction: Vector2
var damage: int = 15

@onready var sprite: ColorRect = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	# Setup sprite (placeholder)
	sprite.color = Color.MAGENTA
	sprite.size = Vector2(16, 8)
	sprite.position = Vector2(-8, -4)
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta):
	# Move in direction
	position += direction * speed * delta

func setup(proj_direction: Vector2, proj_damage: int):
	"""Setup the projectile with direction and damage"""
	direction = proj_direction.normalized()
	damage = proj_damage
	
	# Rotate sprite to match direction
	rotation = direction.angle()

func _on_body_entered(body):
	"""Handle collision with other bodies"""
	# Don't hit the player who fired it
	if body is Player:
		return
	
	# Damage enemies
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Dream bolt hit: ", body.name, " for ", damage, " damage")
	
	# Destroy projectile on hit
	queue_free()