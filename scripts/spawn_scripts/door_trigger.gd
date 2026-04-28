extends Area3D
class_name DoorTrigger

signal room_cleared

@export var enemies: Array[EnemyEntry] = []
@export var spawn_points: Array[SpawnPoint] = []
@export var respawns: bool = false

var active_enemies: Array[Node3D] = []
var _spawn_count := 0

func _ready():
	collision_layer = 0
	collision_mask = 2
	$EntryIndicator.hide()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if not body.is_in_group("player"):
		return
	var to_player = body.global_position - global_position
	if to_player.dot(global_transform.basis.z) > 0:
		return  # player viene del interior, está saliendo
	if not respawns and _spawn_count > 0:
		return
	if not active_enemies.is_empty():
		return
	_spawn_enemies()

func _spawn_enemies():
	var to_spawn: Array
	if _spawn_count == 0:
		to_spawn = enemies.duplicate()
	else:
		to_spawn = enemies.filter(func(e: EnemyEntry): return e.respawns)

	if to_spawn.is_empty() or spawn_points.is_empty():
		print("DoorTrigger '", name, "': nada para spawnear")
		return

	var points: Array = spawn_points.duplicate()
	points.shuffle()
	to_spawn.shuffle()

	var count := mini(to_spawn.size(), points.size())
	print("DoorTrigger '", name, "': spawneando ", count, " enemigos")
	for i in count:
		var entry: EnemyEntry = to_spawn[i]
		var enemy := entry.scene.instantiate() as Node3D
		enemy.global_position = points[i].global_position
		get_tree().current_scene.add_child(enemy)
		active_enemies.append(enemy)
		enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))

	_spawn_count += 1

func _on_enemy_removed(enemy: Node3D):
	active_enemies.erase(enemy)
	if active_enemies.is_empty():
		print("DoorTrigger '", name, "': cuarto limpio")
		room_cleared.emit()
