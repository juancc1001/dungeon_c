extends EnemyBase
class_name EnemyTurret

@export var projectile_scene: PackedScene
@export var projectile_speed := 6.0
@export var projectile_damage := 12
@export var projectile_max_distance := 30.0
@export var fire_interval := 2.0
@export var muzzle_offset := Vector3(0, 1.0, -0.6)

var _fire_timer := 0.0

func _physics_process(delta):
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 9.0)
	if knockback_velocity.length() < 0.05:
		knockback_velocity = Vector3.ZERO

	if knockback_velocity.length() > 0.1:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		move_and_slide()
		return

	velocity.x = 0
	velocity.z = 0

	if target:
		var look_pos := target.global_position
		look_pos.y = global_position.y
		if global_position.distance_to(look_pos) > 0.01:
			look_at(look_pos)
			rotation.x = 0

		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire()
			_fire_timer = fire_interval
	else:
		_fire_timer = fire_interval * 0.5

	move_and_slide()

func _fire():
	if not projectile_scene or not target or not is_instance_valid(target):
		return
	var p = projectile_scene.instantiate()
	p.speed = projectile_speed
	p.damage = projectile_damage
	p.max_distance = projectile_max_distance
	get_tree().root.add_child(p)
	p.global_position = global_position + global_transform.basis * muzzle_offset
	var aim := target.global_position + Vector3(0, 1.0, 0)
	p.look_at(aim)
	print("EnemyTurret disparando")
