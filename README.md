# Labyrinth (Godot 4)

A tiny remake of the classic Labyrinth tilt-and-roll game built with Godot. You tilt a platform to guide the ball, trying not to fall off.

![Screenshot](docs/screenshot.jpg)

## Features
- Simple tilt-based platform using exported variables for quick tuning
- Smooth interpolation toward target tilt
- Auto-reset when the ball falls off the board
- Clean, minimal scene setup

## Controls
- Tilt: WASD, arrow keys, or gamepad stick
- Reset: Spacebar or gamepad button 0 (Xbox A)
- Quit: Escape or gamepad button 6 (Xbox start)

## Roadmap

**Must-haves:**
- [x] Platform surface markings
- [x] Marble rolling sounds
- [x] Marble falling through sound
- [x] Marble wall collision sounds
- [x] Win detection and feedback
- [x] Timer integration
- [x] Windows (x86_64) build
- [x] ARM64 build (for Raspberry Pi)
- [x] Add checkpoints (cheat protection)
- [x] Improved level geometry (outer frame and knobs, beveled edges, etc.)
- [ ] Replace board/layout/visual identity with an original design
  - [ ] Design new board layout on paper (1 h)
  - [ ] 3D model new board in Blender (2 h)
  - [ ] Create new textures / materials (2 h)
  - [ ] Import new board into Godot (1 h)
- [ ] Rename the game (30 min)
- [ ] Design title logo (2 h)
- [ ] Add a basic title screen (2 h)
  - [ ] Title logo
  - [ ] Start
  - [ ] Settings
  - [ ] Quit
- [x] Add basic settings menu (2 h)
  - [x] Fullscreen toggle
  - [x] SSAO toggle
  - [x] SSR toggle
  - [ ] Master volume
- [ ] Add pause menu (2 h)
  - [ ] Best time display (session and all-time)
  - [x] Resume
  - [x] Settings
  - [x] Quit game
- [x] Add help overlay with keybindings (1 h)
- [ ] Separate all-time best and session best times (2 h)
- [ ] In-game timer with visibility toggle (1 h)
- [ ] Improve confetti geometry (1 h)
- [ ] GUI animations (2 h)
  - [ ] Title screen fade-out
  - [ ] Win/cheat feedback animations

**Ideas for the future:**
- [ ] Multiple levels
- [ ] Procedural level generation
- [ ] Level selection menu
- [ ] Leaderboards (local and online)
- [ ] Music
- [ ] Tabletop settings (outdoors, living room, etc. It would affect environmental lighting, sounds, and objects around the table)