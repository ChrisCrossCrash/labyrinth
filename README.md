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

**Must haves:**
- [x] Platform surface markings
- [x] Marble rolling sounds
- [x] Marble falling through sound
- [x] Marble wall collision sounds
- [x] Win detection and feedback
- [x] Timer integration
- [x] Windows (x86_64) build
- [x] ARM64 build (for Raspberry Pi)
- [x] Add checkpoints (cheat protection)

**Polish steps:**
- [ ] Improve confetti geometry
- [ ] Split platform visible and collision meshes
- [ ] Fix mismatched textures
- [ ] Darken platform interior
- [ ] Animate win label

**Nice to haves:**
- [x] Improved level geometry (outer frame and knobs, beveled edges, etc.)
- [ ] Music
- [ ] Mobile app build
- [ ] Web build
