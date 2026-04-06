extends CharacterBody3D

@export var speed := 8.5
@export var sprint_speed := 5.0
@export var mouse_sensitivity := 0.002
@export var max_health := 100
@export var max_stamina := 100.0
@export var stamina_drain := 30.0
@export var stamina_regen := 30.0
@export var starting_weapon: ItemData = null
@export var jump_force := 5.0

var health: int
var stamina: float
var is_sprinting := false
var inventory := {}
var has_weapon := false
var current_weapon: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera := $Camera3D
@onready var raycast := $Camera3D/RayCast3D
@onready var health_bar := $CanvasLayer/Control_Health/NinePatchRect/ProgressBar
@onready var stamina_bar := $CanvasLayer/Control_Stamina/NinePatchRect/ProgressBar
@onready var inventory_ui := $CanvasLayer/VBoxContainer_Inventory

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health = max_health
	stamina = max_stamina
	raycast.add_exception(self)
	health_bar.value = health
	if starting_weapon and starting_weapon.weapon_scene:
		equip_weapon(starting_weapon)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("attack"):
		attack()

func _physics_process(delta):
	var input_dir := Vector3.ZERO
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	
	if Input.is_action_pressed("ui_up"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("ui_down"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("ui_left"):
		input_dir += transform.basis.x
	if Input.is_action_pressed("ui_right"):
		input_dir -= transform.basis.x
	
	input_dir = input_dir.normalized()
	var moving = input_dir.length() > 0
	is_sprinting = Input.is_action_pressed("sprint") and moving and stamina > 0

	if is_sprinting:
		stamina = max(stamina - stamina_drain * delta, 0.0)
	else:
		stamina = min(stamina + stamina_regen * delta, max_stamina)
	stamina_bar.value = (stamina / max_stamina) * 100.0

	var current_speed = sprint_speed if is_sprinting else speed
	velocity.x = input_dir.x * current_speed
	velocity.z = input_dir.z * current_speed

	move_and_slide()

func equip_weapon(item: ItemData):
	if not item.weapon_scene:
		return
	if current_weapon:
		current_weapon.queue_free()

	current_weapon = item.weapon_scene.instantiate()
	camera.add_child(current_weapon)
	has_weapon = true

	if not inventory.has(item):
		add_item(item)
	print("Arma equipada")

func attack():
	if not has_weapon:
		print("No tenés arma")
		return
	if current_weapon.is_attacking:
		return
	current_weapon.attack()
	if current_weapon.is_ranged:
		return
	if raycast.is_colliding():
		var target = raycast.get_collider()
		if target.has_method("take_damage"):
			target.take_damage(current_weapon.damage)
	else:
		print("no hit")

func take_damage(amount):
	health -= amount
	health_bar.value = health
	if health <= 0:
		die()

func add_item(item: ItemData, amount: int = 1):
	if inventory.has(item):
		inventory[item] = min(inventory[item] + amount, item.max_stack)
	else:
		inventory[item] = amount
	print("Recogido: ", item.item_name, " x", amount)
	update_inventory_ui()

func remove_item(item: ItemData, amount: int = 1):
	if not inventory.has(item):
		return
	inventory[item] -= amount
	if inventory[item] <= 0:
		inventory.erase(item)
	update_inventory_ui()

func update_inventory_ui():
	for child in inventory_ui.get_children():
		child.queue_free()

	for item in inventory:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)

		if item.icon:
			var tex_rect = TextureRect.new()
			tex_rect.texture = item.icon
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(24, 24)
			hbox.add_child(tex_rect)

		var label = Label.new()
		label.text = item.item_name + ": " + str(inventory[item])
		hbox.add_child(label)

		inventory_ui.add_child(hbox)

func heal(amount: int):
	health = min(health + amount, max_health)
	health_bar.value = health
	print("Vida: ", health)

func die():
	print("Game Over")
	get_tree().reload_current_scene()
