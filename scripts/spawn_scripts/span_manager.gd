extends Node
class_name  SpawnManager

@export var enemy_scenes: Array[PackedScene] = []
@export var pickup_scenes: Array[PackedScene] = []
@export var weapon_scenes: Array[PackedScene] = []
@export var max_enemies := 5
@export var max_pickups := 3
@export var max_weapons := 2

var enemy_spawn_points: Array[SpawnPoint] = []
var pickup_spawn_points: Array[SpawnPoint] = []
var weapon_spawn_points: Array[SpawnPoint] = []

func _ready():
	print("SpawnManager _ready")
	var enemy_nodes = get_tree().get_nodes_in_group("enemy_spawn")
	print("enemy_spawn nodes encontrados: ", enemy_nodes.size())
	for point in enemy_nodes:
		print("  - ", point.name, " tipo: ", point.get_class(), " es SpawnPoint: ", point is SpawnPoint)
		if point is SpawnPoint:
			enemy_spawn_points.append(point)
	var pickup_nodes = get_tree().get_nodes_in_group("pickup_spawn")
	print("pickup_spawn nodes encontrados: ", pickup_nodes.size())
	for point in pickup_nodes:
		print("  - ", point.name, " tipo: ", point.get_class(), " es SpawnPoint: ", point is SpawnPoint)
		if point is SpawnPoint:
			pickup_spawn_points.append(point)

	var weapon_nodes = get_tree().get_nodes_in_group("weapon_spawn")
	print("weapon_spawn nodes encontrados: ", weapon_nodes.size())
	for point in weapon_nodes:
		if point is SpawnPoint:
			weapon_spawn_points.append(point)

	print("Enemy spawn points validos: ", enemy_spawn_points.size())
	print("Pickup spawn points validos: ", pickup_spawn_points.size())
	print("Weapon spawn points validos: ", weapon_spawn_points.size())
	spawn_initial.call_deferred()
		
func spawn_initial():
	spawn_enemies(max_enemies)
	spawn_pickups(max_pickups)
	spawn_weapons(max_weapons)

func spawn_enemies(count: int):
	var available = enemy_spawn_points.filter(func(p): return not p.used)
	available.shuffle()
	
	for i in min(count, available.size()):
		print("spawned enemy")
		var point = available[i]
		var enemy_scene = enemy_scenes.pick_random()
		var enemy = enemy_scene.instantiate()
		enemy.position = point.global_position
		get_tree().current_scene.add_child(enemy)
		point.used = true

func spawn_pickups(count: int):
	var available = pickup_spawn_points.filter(func(p): return not p.used)
	available.shuffle()

	for i in min(count, available.size()):
		var point = available[i]
		var pickup_scene = pickup_scenes.pick_random()
		var pickup = pickup_scene.instantiate()
		pickup.position = point.global_position
		get_tree().current_scene.add_child(pickup)
		point.used = true

func spawn_weapons(count: int):
	var available = weapon_spawn_points.filter(func(p): return not p.used)
	available.shuffle()

	for i in min(count, available.size()):
		var point = available[i]
		var weapon_scene = weapon_scenes.pick_random()
		var weapon = weapon_scene.instantiate()
		weapon.position = point.global_position
		get_tree().current_scene.add_child(weapon)
		point.used = true
