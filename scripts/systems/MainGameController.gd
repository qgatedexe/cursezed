extends Node2D
class_name MainGameController

## Main game controller that manages menu and game state transitions
## Handles the overall game flow

enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER }
var current_state: GameState = GameState.MAIN_MENU

@onready var main_menu: MainMenu = $MainMenu
@onready var game_manager: GameManager = $GameManager
@onready var camera_controller: Camera2D = $CameraController

func _ready():
	# Connect menu signals
	if main_menu:
		main_menu.start_game.connect(_on_start_game)
		main_menu.options_opened.connect(_on_options_opened)
		main_menu.quit_game.connect(_on_quit_game)
	
	# Start with main menu
	_show_main_menu()

func _show_main_menu():
	"""Show main menu and hide game elements"""
	current_state = GameState.MAIN_MENU
	
	if main_menu:
		main_menu.show_menu()
	
	# Hide game UI
	if game_manager and game_manager.ui_manager:
		game_manager.ui_manager.visible = false
	
	# Disable camera
	if camera_controller:
		camera_controller.enabled = false

func _start_gameplay():
	"""Start the actual gameplay"""
	current_state = GameState.PLAYING
	
	if main_menu:
		main_menu.hide_menu()
	
	# Show game UI
	if game_manager and game_manager.ui_manager:
		game_manager.ui_manager.visible = true
	
	# Enable camera
	if camera_controller:
		camera_controller.enabled = true
		camera_controller.make_current()
	
	# Initialize game
	if game_manager:
		game_manager._initialize_game()

func _on_start_game():
	"""Handle start game from main menu"""
	print("Starting game...")
	_start_gameplay()

func _on_options_opened():
	"""Handle options menu opening"""
	print("Options opened - not implemented yet")

func _on_quit_game():
	"""Handle quit game"""
	print("Quitting game...")
	get_tree().quit()

func _process(delta):
	"""Handle input for game state changes"""
	# ESC to return to main menu while playing
	if current_state == GameState.PLAYING and Input.is_action_just_pressed("ui_cancel"):
		_return_to_main_menu()

func _return_to_main_menu():
	"""Return to main menu from gameplay"""
	print("Returning to main menu...")
	_show_main_menu()
	
	# Clean up game state
	if game_manager:
		game_manager.current_level = 1
		game_manager.memory_fragments = 0
		game_manager.starting_biome = "Ashen Courtyard"