extends EnemyBase
class_name EnemyBomber

@export var explode_distance := 2.0
@export var explosion_radius := 3.0
@export var explosion_damage := 15
@export var windup_time := 0.6

var _is_winding_up := false
var _windup_timer := 0.0

func _physics_process(delta):
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 9.0)
	if knockback_velocity.length() < 0.05:
		knockback_velocity = Vector3.ZERO

	if knockback_velocity.length() > 0.1:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		move_and_slide()
		return

	if _is_winding_up:
		velocity.x = 0
		velocity.z = 0
		_windup_timer -= delta
		if _windup_timer <= 0.0:
			_explode()
			return
		move_and_slide()
		return

	if target:
		var distance = global_position.distance_to(target.global_position)
		if distance <= explode_distance:
			_start_windup()
			move_and_slide()
			return

		nav_agent.target_position = target.global_position
		if not nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			var direction = (next_pos - global_position).normalized()
			direction.y = 0
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			look_at(next_pos)
			rotation.x = 0
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func _start_windup():
	_is_winding_up = true
	_windup_timer = windup_time
	velocity = Vector3.ZERO
	var mesh: MeshInstance3D = $MeshInstance3D
	var tween := create_tween().set_loops()
	tween.tween_property(mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
	tween.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func _explode():
	print("EnemyBomber explotando")
	for body in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(body):
			continue
		var dist = global_position.distance_to(body.global_position)
		if dist <= explosion_radius and body.has_method("take_damage"):
			body.take_damage(explosion_damage)
	die()
