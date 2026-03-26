# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**dungeon_carmesi** is a first-person 3D dungeon crawler built with Godot 4.4 using GDScript and the GL Compatibility renderer. The player navigates a dungeon, attacks enemies via raycast, and enemies chase and damage the player on contact.

## Running the Project

Open in Godot 4.4+ and run. The main scene is `scenes/levels/dungeon_test.tscn`.

## Architecture

### Entity pattern
Entities (player, enemies) use a wrapper Node3D containing a CharacterBody3D with the script attached. Both player and enemies implement `take_damage(amount)` and `die()` as their damage interface — any node calling damage checks `has_method("take_damage")` before calling it.

### Scripts
- `scripts/player_controler.gd` — First-person CharacterBody3D controller. WASD/arrow movement, mouse look, left-click raycast attack (10 damage, range ~3.5 units). Health system with scene reload on death.
- `scripts/enemy_ai.gd` — `EnemyBase` class. Uses Area3D (radius 10) for detection, chases and damages player on contact (distance < 1.0). Calls `queue_free()` on death.

### Dungeon pieces
Modular CSG-based building blocks in `scenes/dungeon_pieces/`: floor tiles (2x2), wall segments (2-wide, 3-tall), corner pieces (two perpendicular walls), door frames (empty placeholder). Levels are assembled by hand-placing these on a 2-unit grid.

### Input map
Movement: `ui_up/down/left/right` (WASD + arrows + gamepad). Attack: `attack` (left mouse button). Cancel: `ui_cancel` (releases mouse).

## GDScript conventions
- Use `@export` for tunable properties, `@onready` for node references
- Spanish-language debug prints (e.g., "Atacando...")
- Note: the player controller filename has a typo (`player_controler.gd`, one "l") — preserve this to avoid breaking references
