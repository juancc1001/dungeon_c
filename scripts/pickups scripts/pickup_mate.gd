extends PickupBase

@export var speed_multiplier = 0.15

func collect(body):
	if "speed" in body:
		body.speed = body.speed * (1.0 + speed_multiplier)
	super.collect(body)

func pickup_effect():
	print("puta que rico esta este mate")
