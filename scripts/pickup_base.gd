extends Area3D
class_name PickupBase

@export var item_data: ItemData = null
@export var quantity := 1

var player_in_range := false
var player_ref: Node3D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		collect(player_ref)

func _on_body_entered(body):
	if body.has_method("add_item"):
		player_in_range = true
		player_ref = body
	
func collect(body):
	if body.has_method("add_item") and item_data:
		body.add_item(item_data, quantity)
	pickup_effect()
	queue_free()
	
func _on_body_exited(body):
	if body == player_ref:
		player_in_range = false
		player_ref = null

func pickup_effect():
	# Override en hijos para efectos custom
	pass
