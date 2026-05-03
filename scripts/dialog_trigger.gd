extends Area3D
class_name DialogTrigger

@export var dialog_id: String = ""
@export var dialog_lines: Array[String] = ["Texto del diálogo aquí."]
@export var speaker_name: String = ""
@export var one_shot: bool = true
@export var auto_trigger: bool = true

var _player_inside: bool = false
var _fired: bool = false

func _ready():
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
	if not body.is_in_group("player"):
		return
	_player_inside = true
	if auto_trigger:
		_trigger()

func _on_body_exited(body: Node3D):
	if not body.is_in_group("player"):
		return
	_player_inside = false

func _unhandled_input(event):
	if auto_trigger:
		return
	if not _player_inside:
		return
	if event.is_action_pressed("interact"):
		_trigger()
		get_viewport().set_input_as_handled()

func _trigger():
	if one_shot and _fired:
		return
	if DialogManager.is_active:
		return
	_fired = true
	if dialog_id != "":
		DialogManager.show_dialog_by_id(dialog_id)
	else:
		DialogManager.show_dialog(dialog_lines, speaker_name)

func reset():
	_fired = false
