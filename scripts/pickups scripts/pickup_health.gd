extends PickupBase

@export var heal_amount := 5

func _ready():
	pickup_name = "vida"
	super._ready()

func collect(body):
	if body.has_method("heal"):
		body.heal(heal_amount)
	super.collect(body)

func pickup_effect():
	print("Curado!")
