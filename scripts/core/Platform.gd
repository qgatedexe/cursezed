extends StaticBody2D
class_name Platform

## Simple platform for rooms
## Can be resized and positioned dynamically

@onready var sprite: ColorRect = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

func setup_size(size: Vector2):
	"""Setup platform with specific size"""
	if sprite:
		sprite.size = size
		sprite.position = Vector2(-size.x / 2, -size.y / 2)
	
	if collision and collision.shape is RectangleShape2D:
		collision.shape.size = size