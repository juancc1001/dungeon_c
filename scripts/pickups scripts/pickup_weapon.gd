extends PickupBase

func collect(body):
	if item_data and item_data.weapon_scene and body.has_method("equip_weapon"):
		body.equip_weapon(item_data)
	super.collect(body)

func pickup_effect():
	print("Arma recogida!")
