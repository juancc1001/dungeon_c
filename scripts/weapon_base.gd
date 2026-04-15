extends Node3D
class_name WeaponBase

@export var damage := 10
@export var attack_duration := 0.25
@export var is_ranged := false
@export var crosshair_gap: float = 10.0
@export var crosshair_spread: float = 8.0
@export var crosshair_spread_duration: float = 0.25

func _ready():
	pass

var is_attacking := false

func attack():
	if is_attacking:
		return
	is_attacking = true

	var start_rot = rotation
	var tween = create_tween()
	
	tween.tween_property(self, "rotation:x", start_rot.x + deg_to_rad(-50), attack_duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation:z", start_rot.z + deg_to_rad(30), attack_duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "rotation:x", start_rot.x, attack_duration * 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "rotation:z", start_rot.z, attack_duration * 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func(): is_attacking = false)
