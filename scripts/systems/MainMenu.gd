extends Control
class_name MainMenu

## Advanced animated main menu for Ashes of Reverie
## Features particle effects, smooth transitions, and atmospheric elements

signal start_game
signal options_opened
signal quit_game

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var menu_buttons: VBoxContainer = $VBoxContainer/MenuButtons
@onready var start_button: Button = $VBoxContainer/MenuButtons/StartButton
@onready var options_button: Button = $VBoxContainer/MenuButtons/OptionsButton
@onready var quit_button: Button = $VBoxContainer/MenuButtons/QuitButton
@onready var background_particles: CPUParticles2D = $BackgroundParticles
@onready var title_particles: CPUParticles2D = $VBoxContainer/TitleParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer = $AudioPlayer

var tween: Tween
var is_transitioning: bool = false

func _ready():
	# Setup initial state
	_setup_ui()
	_setup_particles()
	_connect_signals()
	
	# Start entrance animation
	_play_entrance_animation()

func _setup_ui():
	"""Setup UI elements with initial properties"""
	# Title setup
	title_label.text = "ASHES OF REVERIE"
	title_label.modulate = Color.TRANSPARENT
	
	subtitle_label.text = "Embrace the Dream, Defy the Nightmare"
	subtitle_label.modulate = Color.TRANSPARENT
	
	# Button setup
	start_button.text = "Begin Journey"
	options_button.text = "Settings"
	quit_button.text = "Abandon Hope"
	
	# Make buttons initially invisible
	for button in menu_buttons.get_children():
		button.modulate = Color.TRANSPARENT
		button.scale = Vector2(0.8, 0.8)

func _setup_particles():
	"""Setup particle systems for atmospheric effects"""
	# Background particles (floating ash/embers)
	background_particles.emitting = true
	background_particles.amount = 100
	background_particles.lifetime = 8.0
	background_particles.emission_rate = 12.0
	
	# Configure background particle appearance
	background_particles.texture = _create_particle_texture(Color.GRAY, 4)
	background_particles.direction = Vector3(0, -1, 0)
	background_particles.initial_velocity_min = 20.0
	background_particles.initial_velocity_max = 50.0
	background_particles.gravity = Vector3(0, 30, 0)
	background_particles.scale_amount_min = 0.5
	background_particles.scale_amount_max = 1.5
	
	# Title particles (magical sparkles)
	title_particles.emitting = false
	title_particles.amount = 50
	title_particles.lifetime = 3.0
	title_particles.emission_rate = 15.0
	title_particles.texture = _create_particle_texture(Color.CYAN, 2)

func _create_particle_texture(color: Color, size: int) -> ImageTexture:
	"""Create a simple colored texture for particles"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _connect_signals():
	"""Connect button signals"""
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Button hover effects
	start_button.mouse_entered.connect(_on_button_hover.bind(start_button))
	options_button.mouse_entered.connect(_on_button_hover.bind(options_button))
	quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))
	
	start_button.mouse_exited.connect(_on_button_unhover.bind(start_button))
	options_button.mouse_exited.connect(_on_button_unhover.bind(options_button))
	quit_button.mouse_exited.connect(_on_button_unhover.bind(quit_button))

func _play_entrance_animation():
	"""Play the entrance animation sequence"""
	if tween:
		tween.kill()
	tween = create_tween()
	
	# Animate title
	tween.tween_property(title_label, "modulate", Color.WHITE, 1.5)
	tween.tween_callback(_start_title_particles)
	
	# Animate subtitle
	tween.parallel().tween_property(subtitle_label, "modulate", Color(0.8, 0.8, 0.8, 1.0), 2.0)
	tween.tween_delay(0.5)
	
	# Animate buttons one by one
	for i in range(menu_buttons.get_child_count()):
		var button = menu_buttons.get_child(i)
		tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.8)
		tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.8)
		tween.tween_delay(0.3)

func _start_title_particles():
	"""Start title particle effects"""
	title_particles.emitting = true

func _on_button_hover(button: Button):
	"""Handle button hover effects"""
	if is_transitioning:
		return
	
	var hover_tween = create_tween()
	hover_tween.parallel().tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
	hover_tween.parallel().tween_property(button, "modulate", Color.CYAN, 0.2)

func _on_button_unhover(button: Button):
	"""Handle button unhover effects"""
	if is_transitioning:
		return
	
	var unhover_tween = create_tween()
	unhover_tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.2)
	unhover_tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.2)

func _on_start_pressed():
	"""Handle start game button"""
	if is_transitioning:
		return
	
	is_transitioning = true
	_play_exit_animation()
	await get_tree().create_timer(1.5).timeout
	start_game.emit()

func _on_options_pressed():
	"""Handle options button"""
	if is_transitioning:
		return
	
	options_opened.emit()

func _on_quit_pressed():
	"""Handle quit button"""
	if is_transitioning:
		return
	
	is_transitioning = true
	_play_quit_animation()
	await get_tree().create_timer(1.0).timeout
	quit_game.emit()

func _play_exit_animation():
	"""Play exit animation when starting game"""
	var exit_tween = create_tween()
	
	# Fade out all elements
	exit_tween.parallel().tween_property(title_label, "modulate", Color.TRANSPARENT, 1.0)
	exit_tween.parallel().tween_property(subtitle_label, "modulate", Color.TRANSPARENT, 1.0)
	
	for button in menu_buttons.get_children():
		exit_tween.parallel().tween_property(button, "modulate", Color.TRANSPARENT, 0.8)
		exit_tween.parallel().tween_property(button, "scale", Vector2(0.5, 0.5), 0.8)
	
	# Intensify particles
	title_particles.emission_rate = 50.0
	background_particles.emission_rate = 30.0

func _play_quit_animation():
	"""Play quit animation"""
	var quit_tween = create_tween()
	
	# Dramatic fade to black
	quit_tween.tween_property(self, "modulate", Color.BLACK, 1.0)

func show_menu():
	"""Show the menu (used when returning from game)"""
	visible = true
	is_transitioning = false
	_play_entrance_animation()

func hide_menu():
	"""Hide the menu"""
	visible = false