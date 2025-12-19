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
- [ ] Platform surface markings
- [ ] Marble rolling sounds
- [ ] Marble wall collision sounds
- [ ] Win detection and feedback
- [ ] Timer integration
- [ ] Windows (x86_64) build
- [ ] ARM64 build (for Raspberry Pi)

**Nice to haves:**
- [ ] Improved level geometry (outer frame and knobs, beveled edges, etc.)
- [ ] Music
- [ ] Mobile app build
- [ ] Web build
