extends CharacterBody3D
class_name EnemyBase

@export var speed := 2.5
@export var health := 20
@export var damage := 5

var target: Node3D = null
var attack_timer := 0.0
var can_attack := true

@onready var detection_area := $Area3D
@onready var nav_agent := $NavigationAgent3D

func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody3D and body != self:
		target = body

func _on_body_exited(body):
	if body == target:
		target = null

func _physics_process(delta):
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

		# Daño al tocar
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

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	queue_free()
	
	
