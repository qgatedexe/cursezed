# Ashes of Reverie - Roguelike Foundation

A complete, playable roguelike foundation built in Godot 4.4.1. This project provides all the core systems needed to build upon for a full roguelike game inspired by Dead Cells and Hades.

## 🎮 Current Features

### Player Mechanics (The Wanderer)
- **Movement**: WASD/Arrow keys for movement, Space/W for jump, double jump
- **Dash**: Shift key for quick dash movement with cooldown
- **Melee Combat**: Left mouse button for close-range slash attacks
- **Ranged Combat**: Right mouse button for dream-bolt projectiles (aim with mouse)
- **Health System**: 100 HP with damage feedback and death/respawn

### Procedural Room System
- **Room Templates**: 3 different Ashen Courtyard room layouts
- **Random Generation**: Each run randomizes room selection and enemy placement
- **Room Connections**: Rooms are connected via a simple door system (expandable)
- **Biome Support**: Framework ready for multiple biomes

### Enemy AI
- **Basic Enemies**: Red placeholder enemies with patrol/chase/attack AI
- **Detection System**: 300px detection radius, enemies chase when player spotted
- **Contact Damage**: Enemies deal damage on touch with attack cooldown
- **Health System**: Enemies take damage and drop memory fragments on death

### UI System
- **Health Bar**: Visual health display with color coding (green/yellow/red)
- **Memory Fragments**: Currency counter in top-right
- **Level Info**: Current biome and level display
- **Damage Feedback**: Screen flash effects when taking damage

### Core Systems
- **Game Manager**: Handles game state, level progression, and system coordination
- **Camera System**: Smooth following camera with screen shake support
- **Signal-based Communication**: Clean event system between all components

## 🎯 Controls

- **Movement**: WASD or Arrow Keys
- **Jump**: Space or W (double jump available)
- **Dash**: Shift (cooldown applies)
- **Melee Attack**: Left Mouse Button
- **Ranged Attack**: Right Mouse Button (aim with mouse)

## 📁 Project Structure

```
/scenes/
  /player/        - Player character and abilities
  /enemies/       - Enemy types and AI
  /rooms/         - Room templates and generation
  /main/          - Main game scene
  /ui/            - User interface elements
  /pickups/       - Collectible items

/scripts/
  /core/          - Core game classes (Player, Enemy, Room, etc.)
  /systems/       - Game systems (RoomGenerator, UIManager, etc.)

/assets/
  /placeholder/   - Placeholder art assets (colored rectangles)
```

## 🔧 How to Expand

### Adding New Enemies
1. Create new enemy script extending `Enemy` class
2. Override AI behavior methods as needed
3. Create new enemy scene in `/scenes/enemies/`
4. Add to room generation system

### Adding New Biomes
1. Create new room templates in `/scenes/rooms/`
2. Add biome to `RoomGenerator.room_templates` dictionary
3. Update `GameManager.starting_biome` or add biome progression

### Adding New Abilities
1. Add input actions to `project.godot`
2. Implement ability logic in `Player.gd`
3. Create projectile/effect scenes as needed
4. Add UI elements for cooldowns/resources

### Adding New Room Elements
1. Create new platform/obstacle scenes
2. Add to room templates or procedural generation
3. Update collision layers as needed

## 🎨 Visual Style

Currently using placeholder colored rectangles:
- **Player**: Cyan rectangle (40x60px)
- **Enemies**: Red rectangles (32x48px) 
- **Platforms**: Gray rectangles
- **Projectiles**: Magenta rectangles
- **Memory Fragments**: Cyan squares with floating animation

Replace these with actual sprites by updating the respective scene files.

## 🚀 Next Steps

This foundation is ready for expansion. Consider adding:

1. **More Biomes**: Luminous Abyss, Whispering Halls, Oblivion Root
2. **Weapon System**: Different weapon types with unique attacks
3. **Upgrade System**: Permanent progression between runs
4. **Boss Enemies**: Challenging encounters with multiple phases
5. **Environmental Hazards**: Spikes, moving platforms, etc.
6. **Audio System**: Sound effects and atmospheric music
7. **Particle Effects**: Visual polish for attacks and abilities
8. **Save System**: Progress persistence between sessions

## 🐛 Known Issues

- Collision shapes in room templates needed manual fixes (completed)
- Camera smoothing could use fine-tuning for different screen sizes
- Enemy AI could be more sophisticated (basic patrol/chase currently)

## 🔗 Technical Notes

- Built for Godot 4.4.1
- Uses GDScript throughout
- Collision layers are properly configured
- Signal-based architecture for clean separation
- Modular design allows easy expansion
- All scripts are well-commented for maintainability

The game is fully playable - run the Main.tscn scene to start exploring the Ashen Courtyard!