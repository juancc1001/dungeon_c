extends Node3D
class_name WeaponBase

@export var damage := 10
@export var attack_duration := 0.25
@export var is_ranged := false
@export var crosshair_gap: float = 10.0
@export var crosshair_spread: float = 8.0
@export var crosshair_spread_duration: float = 0.25

var is_attacking := false
var _swing_tween: Tween = null
var _start_rot := Vector3.ZERO

func _ready():
	pass

func attack():
	if is_attacking:
		return
	is_attacking = true
	_start_rot = rotation
	_swing_tween = create_tween()
	_swing_tween.tween_property(self, "rotation:x", _start_rot.x + deg_to_rad(-50), attack_duration * 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(self, "rotation:z", _start_rot.z + deg_to_rad(30), attack_duration * 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_property(self, "rotation:x", _start_rot.x, attack_duration * 0.7)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_swing_tween.parallel().tween_property(self, "rotation:z", _start_rot.z, attack_duration * 0.7)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_swing_tween.finished.connect(func(): is_attacking = false)

# Llamado cuando el golpe conecta: deja que el swing llegue al pico y hace snap-back rápido
func hit_impact():
	await get_tree().create_timer(attack_duration * 0.3).timeout
	if not is_attacking:
		return
	if _swing_tween:
		_swing_tween.kill()
		_swing_tween = null
	var recoil := create_tween()
	recoil.tween_property(self, "rotation", _start_rot, attack_duration * 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil.finished.connect(func(): is_attacking = false)
