extends Node
class_name SpawnManager

@export var pickup_scenes: Array[PackedScene] = []
@export var weapon_scenes: Array[PackedScene] = []
@export var max_pickups := 3
@export var max_weapons := 2

var pickup_spawn_points: Array[SpawnPoint] = []
var weapon_spawn_points: Array[SpawnPoint] = []

func _ready():
	var pickup_nodes = get_tree().get_nodes_in_group("pickup_spawn")
	for point in pickup_nodes:
		if point is SpawnPoint:
			pickup_spawn_points.append(point)

	var weapon_nodes = get_tree().get_nodes_in_group("weapon_spawn")
	for point in weapon_nodes:
		if point is SpawnPoint:
			weapon_spawn_points.append(point)

	print("SpawnManager: ", pickup_spawn_points.size(), " pickup points, ", weapon_spawn_points.size(), " weapon points")
	spawn_initial.call_deferred()

func spawn_initial():
	spawn_pickups(max_pickups)
	spawn_weapons(max_weapons)

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
