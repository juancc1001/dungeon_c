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
- `scripts/player_controler.gd` — First-person CharacterBody3D controller. WASD/arrow movement, mouse look, left-click raycast attack. Health system with scene reload on death. Manages inventory and equipped weapon via `equip_weapon(ItemData)`.
- `scripts/enemy_ai.gd` — `EnemyBase` class. Uses Area3D (radius 10) for detection, chases and damages player on contact (distance < 1.0). Calls `queue_free()` on death.

### Weapon system

Weapons follow a chain: **ItemData resource → weapon scene → weapon script**.

```
resources/weapons/stick.tres   (ItemData)
  └─ weapon_scene → scenes/entities/weapon_node.tscn
                      └─ script: scripts/weapon_base.gd  (WeaponBase)

resources/weapons/gun.tres     (ItemData)
  └─ weapon_scene → scenes/entities/gun_node.tscn
                      └─ script: scripts/weapons/gun.gd  (Gun extends WeaponBase)
                           └─ projectile_scene → scenes/entities/projectile.tscn
                                                   └─ script: scripts/projectile.gd
```

- `scripts/item_data.gd` — `ItemData` resource. Fields: `item_name`, `icon`, `description`, `max_stack`, `weapon_scene (PackedScene)`.
- `scripts/weapon_base.gd` — `WeaponBase` base class. Exports: `damage`, `attack_duration`, `is_ranged`. Provides swing animation via tween. Player checks `is_attacking` before calling `attack()`.
- `scripts/weapons/gun.gd` — `Gun extends WeaponBase`. Sets `is_ranged = true`. On `attack()`: plays recoil tween, instantiates `projectile_scene` at camera position/rotation and adds it to root so it doesn't follow the camera.
- `scripts/projectile.gd` — `Projectile` (Area3D). Moves forward each physics frame, calls `take_damage()` on first body hit, then frees itself. Max range: 50 units.

**Equip flow:** player calls `equip_weapon(item: ItemData)` → instantiates `item.weapon_scene` → adds as child of `Camera3D`.

**Attack flow (melee):** `player_controler.gd` calls `current_weapon.attack()` then checks `RayCast3D` for a hit and calls `take_damage()` directly.

**Attack flow (ranged):** `player_controler.gd` calls `current_weapon.attack()`. Because `current_weapon.is_ranged == true`, the raycast is skipped — damage is handled by the projectile on collision.

### Pickup system

```
scenes/pickups/pickup_base.tscn   (Area3D, PickupBase script)
  ├─ pickup_weapon.tscn  → script: scripts/pickups scripts/pickup_weapon.gd
  └─ pickup_health.tscn  → script: scripts/pickups scripts/pickup_health.gd
```

- `scripts/pickup_base.gd` — `PickupBase` (Area3D). Detects player entry, waits for `interact` action, calls `collect(body)`. Base `collect()` calls `body.add_item(item_data, quantity)` then `queue_free()`.
- `scripts/pickups scripts/pickup_weapon.gd` — Overrides `collect()` to also call `body.equip_weapon(item_data)` before chaining to super.
- `scripts/pickups scripts/pickup_health.gd` — Overrides `collect()` to call `body.heal(heal_amount)`. Export: `heal_amount` (default 5).

### Dungeon pieces
Modular CSG-based building blocks in `scenes/dungeon_pieces/`: floor tiles (2x2), wall segments (2-wide, 3-tall), corner pieces (two perpendicular walls), door frames (empty placeholder). Levels are assembled by hand-placing these on a 2-unit grid.

### Input map
Movement: `ui_up/down/left/right` (WASD + arrows + gamepad). Attack: `attack` (left mouse button). Cancel: `ui_cancel` (releases mouse).

## GDScript conventions
- Use `@export` for tunable properties, `@onready` for node references
- Spanish-language debug prints (e.g., "Atacando...")
- Note: the player controller filename has a typo (`player_controler.gd`, one "l") — preserve this to avoid breaking references
