extends CanvasLayer

var world_pos: Vector3

@onready var label: Label = $Label

func setup(amount: int, pos: Vector3):
	world_pos = pos
	label.text = str(amount)
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.finished.connect(queue_free)

func _process(_delta):
	var camera = get_viewport().get_camera_3d()
	if camera:
		label.position = camera.unproject_position(world_pos)
