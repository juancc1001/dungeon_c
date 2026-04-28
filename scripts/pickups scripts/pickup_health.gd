extends PickupBase

@export var heal_amount := 15

func collect(body):
	if body.has_method("heal"):
		body.heal(heal_amount)
	super.collect(body)

func pickup_effect():
	print("Curado!")
