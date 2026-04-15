# Crear Armas y Pickups

## Estructura de archivos

```
resources/
  items/          -> ItemData (.tres) de items normales
  weapons/        -> ItemData (.tres) de armas + sus pickup scenes
assets/icons/     -> Iconos PNG para el inventario
scenes/entities/  -> Escenas de armas (weapon_node.tscn, gun_node.tscn, etc.)
```

## Crear una nueva arma

### 1. Escena del arma (lo que se ve en mano)

1. Crear nueva escena con nodo raiz `Node3D`
2. Asignar el script `scripts/weapon_base.gd` al nodo raiz
3. Agregar el mesh del arma como hijo (MeshInstance3D)
4. Opcionalmente agregar `StaticBody3D` + `CollisionShape3D` al mesh (collision_layer = 8, collision_mask = 1)
5. Ajustar posicion para que se vea bien en primera persona (offset X, Y, Z desde la camara)
6. Configurar `damage` y `attack_duration` en el Inspector
7. Guardar en `scenes/entities/` (ej: `gun_node.tscn`)

Para personalizar la animacion de ataque, crear un script que herede de `WeaponBase` y sobreescribir `attack()`.

### 2. ItemData (.tres)

1. Click derecho en `resources/weapons/` > **Create New > Resource**
2. Buscar **ItemData** en la lista de tipos
3. Rellenar en el Inspector:
   - **Item Name**: nombre del arma (ej: "Espada")
   - **Icon**: arrastrar el PNG desde `assets/icons/`
   - **Max Stack**: 1 (las armas no se apilan)
   - **Description**: descripcion del arma
   - **Weapon Scene**: arrastrar la escena del arma (ej: `gun_node.tscn`)
4. Guardar como `.tres` (ej: `gun.tres`)

### 3. Pickup scene (lo que se ve en el suelo)

1. Click derecho en `scenes/entities/pickup_base.tscn` > **New Inherited Scene**
2. En el nodo `Area3D`:
   - Cambiar el script a `scripts/pickups scripts/pickup_weapon.gd`
   - En el campo **Item Data**, arrastrar el `.tres` creado (ej: `gun.tres`)
3. Opcionalmente cambiar el mesh para que represente el arma en el suelo
4. Guardar (ej: `resources/weapons/pickup_gun.tscn`)

### 4. Agregar al SpawnManager

1. En la escena del nivel, seleccionar el nodo **SpawnManager**
2. En el Inspector, agregar la pickup scene al array **Weapon Scenes**
3. Configurar **Max Weapons** si es necesario
4. Asegurarse de tener SpawnPoints en el grupo **weapon_spawn** en el mapa

---

## Cómo se relacionan los archivos

Cuando el jugador recoge un arma, esta es la cadena completa:

```
pickup_gun.tscn          <- va en el suelo del nivel
  └─ item_data: gun.tres (ItemData)
	   ├─ item_name, icon, description, max_stack
	   └─ weapon_scene: gun_node.tscn
						  └─ script: gun.gd (Gun extends WeaponBase)
							   └─ projectile_scene: projectile.tscn
									└─ script: projectile.gd
```

**El ItemData es el nexo central.** El pickup lo usa para saber qué escena de arma instanciar. El arma lo usa para mostrarse en el inventario.

Para armas cuerpo a cuerpo la cadena es más corta:

```
pickup_stick.tscn
  └─ item_data: stick.tres
	   └─ weapon_scene: weapon_node.tscn
						  └─ script: weapon_base.gd (WeaponBase)
```

---

## Crear un arma a distancia (ranged)

En lugar de usar `weapon_base.gd`, crear un script que herede de `WeaponBase`:

```gdscript
extends WeaponBase
class_name MiArmaRanged

@export var projectile_scene: PackedScene
@export var projectile_damage := 15
@export var projectile_speed := 20.0

func _ready():
	is_ranged = true   # le dice al player que no use el raycast
	super._ready()

func attack():
	if is_attacking:
		return
	is_attacking = true
	# animación...
	var tween = create_tween()
	# ...
	tween.finished.connect(func(): is_attacking = false)

	var projectile = projectile_scene.instantiate()
	var camera = get_viewport().get_camera_3d()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	get_tree().root.add_child(projectile)   # importante: root, no camera
	projectile.global_position = camera.global_position
	projectile.global_rotation = camera.global_rotation
```

El proyectil (`projectile.tscn`) es un **Area3D** con:
- `MeshInstance3D` (esfera pequeña u otro mesh)
- `CollisionShape3D`
- señal `body_entered` conectada a `_on_body_entered`

```gdscript
# projectile.gd
extends Area3D

var speed := 20.0
var damage := 15
var max_distance := 50.0
var distance_traveled := 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var movement = -transform.basis.z * speed * delta
	position += movement
	distance_traveled += movement.length()
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
```

> **Importante:** el nodo raíz de `projectile.tscn` debe ser el `Area3D` directamente (no un `Node3D` contenedor), para que `projectile.speed` y `projectile.damage` funcionen al instanciar.

---

## Crear un nuevo pickup de item (no arma)

### 1. ItemData (.tres)

1. Click derecho en `resources/items/` > **Create New > Resource**
2. Buscar **ItemData**
3. Rellenar: nombre, icono, max stack, descripcion
4. Dejar **Weapon Scene** en null (no es un arma)
5. Guardar como `.tres`

### 2. Pickup scene

1. Click derecho en `scenes/entities/pickup_base.tscn` > **New Inherited Scene**
2. En el nodo `Area3D`:
   - Si necesita logica especial (ej: curar), crear un script que herede de `PickupBase` y sobreescribir `collect()`
   - Si solo agrega al inventario, dejar el script de `pickup_base.gd`
   - Asignar el `.tres` al campo **Item Data**
3. Cambiar el mesh si es necesario
4. Guardar en `scenes/entities/pickups/`

### 3. Agregar al SpawnManager

1. Agregar la pickup scene al array **Pickup Scenes** del SpawnManager
2. Asegurarse de tener SpawnPoints en el grupo **pickup_spawn**

---

## Ejemplo: pickup que cura (pickup_health)

`pickup_health.gd` hereda de `PickupBase` y sobreescribe `collect()`:

```gdscript
extends PickupBase

@export var heal_amount := 5

func collect(body):
	if body.has_method("heal"):
		body.heal(heal_amount)
	super.collect(body)
```

`super.collect(body)` llama al `collect()` de `PickupBase`, que agrega el item al inventario y hace `queue_free()`.

---

## Collision layers

| Layer | Uso            | Valor |
|-------|----------------|-------|
| 1     | Mundo (suelo, paredes) | 1  |
| 2     | Player         | 2     |
| 3     | Enemigos       | 4     |
| 4     | Armas (en mano)| 8     |

| Entidad  | Layer | Mask       | Colisiona con              |
|----------|-------|------------|----------------------------|
| Player   | 2     | 5 (1+4)   | Mundo + Enemigos           |
| Enemy    | 4     | 7 (1+2+4) | Mundo + Player + Enemigos  |
| Weapon   | 8     | 1          | Solo mundo                 |
| Pickups  | 0     | 2          | Solo detecta player        |

---

## Grupos de spawn

| Grupo          | Uso                     |
|----------------|-------------------------|
| enemy_spawn    | SpawnPoints de enemigos |
| pickup_spawn   | SpawnPoints de items    |
| weapon_spawn   | SpawnPoints de armas    |
