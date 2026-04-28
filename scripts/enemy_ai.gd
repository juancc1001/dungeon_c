extends CharacterBody3D
class_name EnemyBase

@export var speed := 2.5
@export var health := 25
@export var damage := 5
@export var knockback_force := 1.5 #distancia de knockback
@export var damage_number_scene: PackedScene

var max_health: int
var target: Node3D = null
var attack_timer := 0.0
var can_attack := true
var knockback_velocity := Vector3.ZERO

@onready var detection_area := $Area3D
@onready var nav_agent := $NavigationAgent3D
@onready var health_bar_fill: MeshInstance3D = $HealthBarRoot/Fill

func _ready():
	max_health = health
	health_bar_fill.mesh = health_bar_fill.mesh.duplicate()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		target = body

func _on_body_exited(body):
	if body == target:
		target = null

func _physics_process(delta):
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 9.0)
	if knockback_velocity.length() < 0.05:
		knockback_velocity = Vector3.ZERO

	# ignora movimiento mientras haya knockback
	if knockback_velocity.length() > 0.1:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		move_and_slide()
		return

	if target:
		nav_agent.target_position = target.global_position
		if not nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			var direction = (next_pos - global_position).normalized()
			direction.y = 0
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

			look_at(next_pos)
			rotation.x = 0

		if not can_attack:
			attack_timer -= delta
			if attack_timer <= 0.0:
				can_attack = true

		var distance = global_position.distance_to(target.global_position)
		if distance < 1.0 and can_attack:
			if target.has_method("take_damage"):
				target.take_damage(damage)
				can_attack = false
				attack_timer = 1.0
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func _update_health_bar():
	var pct: float = clamp(float(health) / float(max_health), 0.0, 1.0)
	var fill_mesh := health_bar_fill.mesh as QuadMesh
	fill_mesh.size.x = pct
	fill_mesh.center_offset.x = pct / 2.0 - 0.5

func take_damage(amount: int, hit_pos: Vector3 = Vector3.ZERO):
	health -= amount
	_update_health_bar()

	if hit_pos != Vector3.ZERO:
		var knock_dir = global_position - hit_pos
		knock_dir.y = 0.0
		if knock_dir.length() > 0.01:
			knockback_velocity = knock_dir.normalized() * knockback_force

	if damage_number_scene:
		var dmg = damage_number_scene.instantiate()
		get_tree().root.add_child(dmg)
		var pos = hit_pos if hit_pos != Vector3.ZERO else global_position + Vector3(0, 1.0, 0)
		dmg.setup(amount, pos)

	if health <= 0:
		die()

func die():
	get_parent().queue_free()
