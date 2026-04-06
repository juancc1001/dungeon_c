extends Area3D
class_name Projectile

var speed := 20.0
var damage := 15
var max_distance := 50.0
var distance_traveled := 0.0

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
	
