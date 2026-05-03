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
	for point in pickup_spawn_points:
		if point.forced_scene and not point.used:
			_spawn_at(point, point.forced_scene)

	var available = pickup_spawn_points.filter(func(p): return not p.used)
	available.shuffle()
	for i in min(count, available.size()):
		_spawn_at(available[i], pickup_scenes.pick_random())

func spawn_weapons(count: int):
	for point in weapon_spawn_points:
		if point.forced_scene and not point.used:
			_spawn_at(point, point.forced_scene)

	var available = weapon_spawn_points.filter(func(p): return not p.used)
	available.shuffle()
	for i in min(count, available.size()):
		_spawn_at(available[i], weapon_scenes.pick_random())

func _spawn_at(point: SpawnPoint, scene: PackedScene):
	var instance = scene.instantiate()
	instance.position = point.global_position
	get_tree().current_scene.add_child(instance)
	point.used = true
