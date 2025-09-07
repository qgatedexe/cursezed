# 🌍 Ashes of Reverie - Biome System Documentation

## Overview

The biome system transforms Ashes of Reverie from a simple roguelike into a visually rich, atmospheric experience with 6 unique biomes, each featuring:

- **Parallax backgrounds** with multiple layers
- **GPU particle systems** for atmospheric effects
- **Custom shaders** for visual enhancement
- **Biome-specific mechanics** and interactions
- **32x32 pixel tile system** for consistent art style
- **Modular room scenes** connected via biome graphs

## 🏗️ Architecture

### Core Components

- **BiomeController**: Manages biome progression and transitions
- **ParallaxController**: Handles multi-layer scrolling backgrounds
- **RoomManager**: Manages individual room logic and performance
- **ParticlePool**: Optimizes particle system performance
- **Custom Shaders**: Provide visual effects for each biome

### File Structure

```
/scenes/biomes/
├── forgotten_forest/     # Biome 1 scenes
├── ruined_city/          # Biome 2 scenes  
├── drowned_cathedrals/   # Biome 3 scenes
├── endless_roads/        # Biome 4 scenes
├── infernal_depths/      # Biome 5 scenes
└── reverie_heart/        # Final biome scenes

/scripts/biomes/          # Biome-specific scripts
/scripts/systems/         # Core system scripts
/assets/shaders/          # Custom shader files
/assets/textures/         # Texture assets
```

## 🌲 Biome 1: Forgotten Forest

**Theme**: Dreamlike, alive forest with mystery and depth

### Features
- **Parallax Layers**: Sky gradient, distant trees, mid trees, foreground bushes
- **Particles**: Glowing spores (200), falling leaves (100)
- **Lighting**: Subtle green-tinted global light with flicker
- **Shaders**: Volumetric fog, tree swaying
- **Special Effects**: Spore bursts, wind gusts, light pulses

### Key Scripts
- `ForgottenForestRoom.gd` - Main room logic
- `volumetric_fog.gdshader` - Atmospheric fog effect
- `tree_sway.gdshader` - Animated tree movement

## 🏚️ Biome 2: Ruined City of Ash

**Theme**: Industrial post-apocalyptic with ash and collapsing structures

### Features
- **Parallax Layers**: Ash-laden sky, distant buildings, foreground ruins
- **Particles**: Falling ash (300), glowing embers (60)
- **Mechanics**: Collapsing floors with warning system
- **Lighting**: Flickering industrial lights
- **Shaders**: Smoke effects, neon flicker
- **Special Effects**: Ash storms, structural collapses

### Key Scripts
- `RuinedCityRoom.gd` - Room with collapse mechanics
- `smoke_shader.gdshader` - Tiling smoke effect

## 🌊 Biome 3: Drowned Cathedrals

**Theme**: Submerged sacred spaces with underwater mechanics

### Features
- **Parallax Layers**: Deep sky, sea surface light, drowned arches
- **Particles**: Rising bubbles (150), floating drift particles (80)
- **Mechanics**: Water volume physics, underwater movement
- **Lighting**: Submerged godrays with pulsing
- **Shaders**: Caustics lighting, underwater color filter
- **Special Effects**: Tidal waves, fish shadows

### Key Scripts
- `DrownedCathedralsRoom.gd` - Underwater physics system
- `caustics.gdshader` - Animated light ripples

## 🏜️ Biome 4: Endless Roads

**Theme**: Desert of memory with heat shimmer and mirages

### Features
- **Extended Size**: 6400x1920 px rooms for vast feel
- **Parallax Layers**: Distant horizon, mid ruins, road foreground
- **Particles**: Wind-blown dust (200)
- **Mechanics**: Mirage system with phantom objects
- **Shaders**: Heat shimmer distortion
- **Special Effects**: Sandstorms, secret mirage doors

### Key Scripts
- `EndlessRoadsRoom.gd` - Mirage and heat effects
- `heat_shimmer.gdshader` - Heat distortion effect

## 🔥 Biome 5: Infernal Depths

**Theme**: Lava-filled hellish environment with intense platforming

### Features
- **Parallax Layers**: Deep glow, lava ridges
- **Particles**: Intense embers (250), dense smoke (100)
- **Mechanics**: Lava damage areas, timed platform collapses
- **Lighting**: Pulsing lava glow with multiple Light2D nodes
- **Shaders**: Animated lava glow, scanline heat effects
- **Special Effects**: Magma bursts, eruptions

### Key Scripts
- `InfernalDepthsRoom.gd` - Lava hazards and platforming
- `lava_glow.gdshader` - Animated lava surface

## 🏰 Biome 6: Reverie's Heart

**Theme**: Dream nexus with morphing geometry and surreal effects

### Features
- **Parallax Layers**: Starfield, shifting fragments
- **Particles**: Dream haze (350), memory echoes
- **Mechanics**: Morphing room geometry, floating fragments
- **Systems**: MultiMeshInstance2D for fragment rendering
- **Shaders**: Space warp effects, fragment shimmer
- **Special Effects**: Room morphing, memory shard collection

### Key Scripts
- `ReverieHeartRoom.gd` - Morphing geometry system
- `space_warp.gdshader` - Reality distortion effects

## 🎮 Implementation Guide

### Setting Up a New Biome Room

1. **Create Room Scene**:
   ```
   BiomeRoom (Node2D)
   ├─ ParallaxBackground
   ├─ TileMap nodes
   ├─ GPUParticles2D nodes  
   ├─ Light2D nodes
   ├─ Shader ColorRects
   └─ RoomManager
   ```

2. **Configure ParallaxController**:
   ```gdscript
   parallax_bg.set_biome_config("Your Biome Name")
   ```

3. **Setup Particle Systems**:
   ```gdscript
   var material = ParticleProcessMaterial.new()
   # Configure material properties
   particles.process_material = material
   ```

4. **Apply Custom Shaders**:
   ```gdscript
   var shader_material = ShaderMaterial.new()
   shader_material.shader = load("res://assets/shaders/your_shader.gdshader")
   node.material = shader_material
   ```

### Performance Considerations

- **Particle LOD**: Use `ParticlePool` for efficient particle management
- **Shader Optimization**: Keep shader complexity reasonable for target hardware
- **Visibility Culling**: Use `VisibilityEnabler2D` for off-screen optimization
- **Texture Atlasing**: Combine small textures into atlases

### Extending the System

1. **New Biome Types**: Add to `BiomeController.BiomeType` enum
2. **Room Templates**: Create scenes in appropriate biome folder
3. **Custom Mechanics**: Extend biome room scripts
4. **Shader Effects**: Create new `.gdshader` files
5. **Particle Types**: Add to `ParticlePool.ParticleType` enum

## 🎨 Visual Style Guidelines

- **Tile Size**: 32x32 pixels for all tile-based elements
- **Screen Target**: 1920x1080 resolution
- **Color Palettes**: Each biome has distinct color scheme
- **Particle Counts**: Balanced for 60fps performance
- **Shader Intensity**: Subtle effects that enhance atmosphere

## 🔧 Technical Specifications

### Parallax Configuration
- **Layer Count**: 3-4 layers per biome
- **Motion Scales**: 0.1 to 1.0 range
- **Mirroring**: Horizontal tiling for infinite scrolling

### Particle Systems
- **GPU Particles**: All systems use GPUParticles2D
- **Emission Shapes**: Box, Point, Sphere based on effect
- **Material Properties**: Configured per biome theme
- **Pooling**: Managed by ParticlePool system

### Shader Pipeline
- **Shader Types**: canvas_item for 2D effects
- **Uniforms**: Exposed for runtime adjustment
- **Performance**: Optimized for mobile and desktop

## 🎵 Audio Integration

Each biome supports:
- **Music Cues**: Triggered on room entry
- **Ambient Sounds**: Looping atmospheric audio
- **Effect Sounds**: Particle and shader effect audio
- **Audio Buses**: Biome-specific processing (e.g., underwater filter)

## 🐛 Debugging Tools

- **Biome Stats**: `BiomeController.get_biome_progress()`
- **Particle Stats**: `ParticlePool.get_pool_stats()`
- **Room State**: `RoomManager` debug output
- **Performance**: Built-in profiling for particle LOD

## 🚀 Future Enhancements

- **Dynamic Weather**: Weather systems per biome
- **Seasonal Changes**: Time-based biome variations
- **Procedural Elements**: Runtime generation of biome features
- **VR Support**: Adaptation for virtual reality
- **Mobile Optimization**: Reduced complexity variants

---

*This biome system transforms Ashes of Reverie into a visually stunning, atmospheric experience while maintaining the solid roguelike foundation. Each biome offers unique challenges, mechanics, and visual storytelling opportunities.*