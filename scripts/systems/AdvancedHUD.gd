extends Control
class_name AdvancedHUD

## Advanced HUD system for Ashes of Reverie
## Features inventory slots, minimap, enhanced health display, and memory fragments

signal inventory_slot_clicked(slot_index: int)
signal minimap_clicked(world_position: Vector2)

# UI References
@onready var health_bar: ProgressBar = $HealthContainer/HealthBar
@onready var health_label: Label = $HealthContainer/HealthLabel
@onready var memory_label: Label = $MemoryContainer/MemoryLabel
@onready var memory_icon: TextureRect = $MemoryContainer/MemoryIcon
@onready var level_label: Label = $LevelContainer/LevelLabel

# Inventory System
@onready var inventory_container: HBoxContainer = $InventoryContainer/InventorySlots
var inventory_slots: Array[InventorySlot] = []
var inventory_items: Array[String] = ["", "", "", "", ""]

# Minimap System
@onready var minimap_container: Control = $MinimapContainer
@onready var minimap_background: ColorRect = $MinimapContainer/MinimapBackground
@onready var minimap_player_dot: ColorRect = $MinimapContainer/PlayerDot
@onready var minimap_enemies: Node2D = $MinimapContainer/EnemyDots
@onready var minimap_rooms: Node2D = $MinimapContainer/RoomOutlines

# Minimap properties
@export var minimap_size: Vector2 = Vector2(200, 150)
@export var world_to_minimap_scale: float = 0.05

var game_manager: GameManager
var current_room_size: Vector2 = Vector2(1920, 1080)

func _ready():
	_setup_inventory_slots()
	_setup_minimap()
	_setup_ui_styling()
	
	# Find game manager
	game_manager = get_tree().get_first_node_in_group("game_manager")

func _setup_inventory_slots():
	"""Initialize the 5 inventory slots"""
	# Clear existing slots
	for child in inventory_container.get_children():
		child.queue_free()
	
	inventory_slots.clear()
	
	# Create 5 inventory slots
	for i in range(5):
		var slot = _create_inventory_slot(i)
		inventory_container.add_child(slot)
		inventory_slots.append(slot)

func _create_inventory_slot(index: int) -> InventorySlot:
	"""Create an individual inventory slot"""
	var slot = InventorySlot.new()
	slot.slot_index = index
	slot.custom_minimum_size = Vector2(64, 64)
	slot.slot_clicked.connect(_on_inventory_slot_clicked)
	return slot

func _setup_minimap():
	"""Initialize minimap system"""
	minimap_background.size = minimap_size
	minimap_background.color = Color(0.1, 0.1, 0.2, 0.8)
	
	# Setup player dot
	minimap_player_dot.size = Vector2(4, 4)
	minimap_player_dot.color = Color.CYAN
	minimap_player_dot.position = minimap_size / 2

func _setup_ui_styling():
	"""Setup visual styling for UI elements"""
	# Health bar styling
	health_bar.modulate = Color.GREEN
	
	# Memory fragment styling
	memory_icon.modulate = Color.CYAN

func update_health(current: int, maximum: int):
	"""Update health display with animations"""
	if health_bar:
		var old_value = health_bar.value
		health_bar.max_value = maximum
		
		# Animate health change
		var tween = create_tween()
		tween.tween_property(health_bar, "value", current, 0.3)
		
		# Color coding
		var health_percent = float(current) / float(maximum)
		if health_percent <= 0.25:
			health_bar.modulate = Color.RED
		elif health_percent <= 0.5:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.GREEN
	
	if health_label:
		health_label.text = str(current) + " / " + str(maximum)

func update_memory_fragments(amount: int):
	"""Update memory fragments display with animation"""
	if memory_label:
		var old_text = memory_label.text
		memory_label.text = str(amount)
		
		# Animate memory collection
		if memory_icon:
			var tween = create_tween()
			tween.tween_property(memory_icon, "scale", Vector2(1.2, 1.2), 0.1)
			tween.tween_property(memory_icon, "scale", Vector2.ONE, 0.1)

func update_level_name(level_name: String):
	"""Update level display"""
	if level_label:
		level_label.text = level_name

func update_minimap():
	"""Update minimap with current game state"""
	if not game_manager:
		return
	
	_update_player_position_on_minimap()
	_update_enemies_on_minimap()
	_update_room_outline()

func _update_player_position_on_minimap():
	"""Update player dot position on minimap"""
	if not game_manager.player:
		return
	
	var player_pos = game_manager.player.global_position
	var minimap_pos = _world_to_minimap_position(player_pos)
	minimap_player_dot.position = minimap_pos

func _update_enemies_on_minimap():
	"""Update enemy dots on minimap"""
	# Clear existing enemy dots
	for child in minimap_enemies.get_children():
		child.queue_free()
	
	# Add new enemy dots
	if game_manager.current_room:
		for enemy in game_manager.current_room.enemies:
			if enemy and is_instance_valid(enemy):
				var enemy_dot = ColorRect.new()
				enemy_dot.size = Vector2(3, 3)
				enemy_dot.color = Color.RED
				enemy_dot.position = _world_to_minimap_position(enemy.global_position)
				minimap_enemies.add_child(enemy_dot)

func _update_room_outline():
	"""Update room boundaries on minimap"""
	# This could be expanded to show multiple connected rooms
	pass

func _world_to_minimap_position(world_pos: Vector2) -> Vector2:
	"""Convert world position to minimap position"""
	var relative_pos = world_pos / current_room_size
	return relative_pos * minimap_size

func add_item_to_slot(slot_index: int, item_name: String):
	"""Add an item to a specific inventory slot"""
	if slot_index >= 0 and slot_index < inventory_slots.size():
		inventory_items[slot_index] = item_name
		inventory_slots[slot_index].set_item(item_name)

func remove_item_from_slot(slot_index: int):
	"""Remove item from a specific slot"""
	if slot_index >= 0 and slot_index < inventory_slots.size():
		inventory_items[slot_index] = ""
		inventory_slots[slot_index].clear_item()

func _on_inventory_slot_clicked(slot_index: int):
	"""Handle inventory slot clicks"""
	inventory_slot_clicked.emit(slot_index)
	print("Inventory slot ", slot_index, " clicked")

func _process(delta):
	"""Update minimap every frame"""
	update_minimap()

# Inventory Slot Class
class_name InventorySlot
extends Control

signal slot_clicked(slot_index: int)

var slot_index: int = 0
var item_name: String = ""
var background: ColorRect
var item_icon: TextureRect
var item_label: Label

func _init():
	# Setup slot background
	background = ColorRect.new()
	background.color = Color(0.2, 0.2, 0.3, 0.8)
	background.size = Vector2(64, 64)
	add_child(background)
	
	# Setup item icon
	item_icon = TextureRect.new()
	item_icon.size = Vector2(48, 48)
	item_icon.position = Vector2(8, 8)
	item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	add_child(item_icon)
	
	# Setup item label
	item_label = Label.new()
	item_label.size = Vector2(64, 20)
	item_label.position = Vector2(0, 44)
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_label.theme_override_font_sizes["font_size"] = 10
	add_child(item_label)
	
	# Connect click signal
	gui_input.connect(_on_gui_input)

func _on_gui_input(event):
	"""Handle input events for the slot"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(slot_index)

func set_item(new_item_name: String):
	"""Set the item in this slot"""
	item_name = new_item_name
	item_label.text = new_item_name
	
	# Create simple colored icon based on item name
	var color = _get_item_color(new_item_name)
	_create_item_icon(color)

func clear_item():
	"""Clear the item from this slot"""
	item_name = ""
	item_label.text = ""
	item_icon.texture = null

func _create_item_icon(color: Color):
	"""Create a simple colored icon for the item"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	item_icon.texture = texture

func _get_item_color(item_name: String) -> Color:
	"""Get color based on item name"""
	match item_name.to_lower():
		"sword": return Color.SILVER
		"potion": return Color.RED
		"key": return Color.GOLD
		"gem": return Color.BLUE
		_: return Color.WHITE