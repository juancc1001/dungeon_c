extends WeaponBase
class_name Gun

@export var projectile_scene: PackedScene
@export var projectile_damage := 15
@export var projectile_speed := 50.0

func _ready():
	is_ranged = true
	crosshair_gap = 5
	super._ready()
	
func attack():
	if is_attacking:
		return
	is_attacking = true

	# Animación de retrocesos
	var start_rot = rotation
	var tween = create_tween()
	tween.tween_property(self, "rotation:x", start_rot.x + deg_to_rad(15), attack_duration * 0.3)
	tween.tween_property(self, "rotation:x", start_rot.x, attack_duration * 0.7)
	tween.finished.connect(func(): is_attacking = false)

	# Disparar proyectil
	var projectile = projectile_scene.instantiate()
	var camera = get_viewport().get_camera_3d()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	get_tree().root.add_child(projectile)
	projectile.global_position = camera.global_position
	projectile.global_rotation = camera.global_rotation
