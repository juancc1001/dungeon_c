extends CharacterBody3D

@export var speed := 4.25
@export var sprint_speed := 5.5
@export var mouse_sensitivity := 0.002
@export var max_health := 100
@export var max_stamina := 100.0
@export var stamina_drain := 30.0
@export var stamina_regen := 30.0
@export var starting_weapon: ItemData = null
@export var jump_force := 5.0
@export var weapon_slot_count := 3

var health: int
var stamina: float
var is_sprinting := false
var inventory := {}
var weapon_slots: Array = []
var active_slot: int = 0
var current_weapon: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var crosshair: Control = null
var slot_panels: Array = []

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

	weapon_slots.resize(weapon_slot_count)
	for i in weapon_slot_count:
		weapon_slots[i] = null

	var CrosshairScript = load("res://scripts/ui/crosshair.gd")
	crosshair = CrosshairScript.new()
	crosshair.anchor_left = 0.0
	crosshair.anchor_top = 0.0
	crosshair.anchor_right = 1.0
	crosshair.anchor_bottom = 1.0
	crosshair.offset_left = 0
	crosshair.offset_top = 0
	crosshair.offset_right = 0
	crosshair.offset_bottom = 0
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.hide()
	$CanvasLayer.add_child(crosshair)

	_build_weapon_slots_ui()

	if starting_weapon and starting_weapon.weapon_scene:
		add_weapon(starting_weapon)

func _build_weapon_slots_ui():
	var slot_size := 54
	var separation := 4
	var total_w := weapon_slot_count * slot_size + (weapon_slot_count - 1) * separation

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", separation)
	hbox.anchor_left = 0.5
	hbox.anchor_top = 1.0
	hbox.anchor_right = 0.5
	hbox.anchor_bottom = 1.0
	hbox.offset_left = -total_w / 2.0
	hbox.offset_right = total_w / 2.0
	hbox.offset_top = -64
	hbox.offset_bottom = -8
	$CanvasLayer.add_child(hbox)

	for i in weapon_slot_count:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(slot_size, slot_size)

		var num_label := Label.new()
		num_label.text = str(i + 1)
		num_label.add_theme_font_size_override("font_size", 10)
		num_label.anchor_left = 0.0
		num_label.anchor_top = 0.0
		num_label.offset_left = 3
		num_label.offset_top = 1
		num_label.offset_right = 16
		num_label.offset_bottom = 14
		panel.add_child(num_label)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.anchor_left = 0.0
		icon.anchor_top = 0.0
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.offset_left = 8
		icon.offset_top = 8
		icon.offset_right = -8
		icon.offset_bottom = -8
		panel.add_child(icon)

		hbox.add_child(panel)
		slot_panels.append(panel)

	update_weapon_slots_ui()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("attack"):
		if not DialogManager.is_active:
			attack()

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: switch_to_slot(0)
			KEY_2: switch_to_slot(1)
			KEY_3: switch_to_slot(2)
			KEY_H: drop_weapon()

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				switch_to_slot((active_slot - 1 + weapon_slot_count) % weapon_slot_count)
			MOUSE_BUTTON_WHEEL_DOWN:
				switch_to_slot((active_slot + 1) % weapon_slot_count)

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

func add_weapon(item: ItemData):
	if not item.weapon_scene:
		return
	var target_slot := -1
	for i in weapon_slot_count:
		if weapon_slots[i] == null:
			target_slot = i
			break
	if target_slot == -1:
		target_slot = active_slot
	weapon_slots[target_slot] = item
	switch_to_slot(target_slot)
	print("Arma en slot ", target_slot + 1, ": ", item.item_name)

func equip_weapon(item: ItemData):
	add_weapon(item)

func switch_to_slot(idx: int):
	if idx < 0 or idx >= weapon_slot_count:
		return
	active_slot = idx
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null
	var item = weapon_slots[active_slot]
	if item and item.weapon_scene:
		current_weapon = item.weapon_scene.instantiate()
		camera.add_child(current_weapon)
		if current_weapon.is_ranged:
			crosshair.update_gap(current_weapon.crosshair_gap)
			crosshair.show()
		else:
			crosshair.hide()
	else:
		crosshair.hide()
	update_weapon_slots_ui()

func update_weapon_slots_ui():
	for i in slot_panels.size():
		var panel: Panel = slot_panels[i]
		var icon_rect: TextureRect = panel.get_node("Icon")
		icon_rect.texture = weapon_slots[i].icon if weapon_slots[i] != null else null

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.75)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		if i == active_slot:
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_color = Color(1.0, 0.85, 0.0)
		else:
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_color = Color(0.5, 0.5, 0.5)
		panel.add_theme_stylebox_override("panel", style)

func attack():
	if not current_weapon:
		print("No tenés arma")
		return
	if current_weapon.is_attacking:
		return
	current_weapon.attack()
	if current_weapon.is_ranged:
		crosshair.animate_spread(current_weapon.crosshair_spread, current_weapon.crosshair_spread_duration)
		return
	if raycast.is_colliding():
		var target = raycast.get_collider()
		if target.has_method("take_damage"):
			target.take_damage(current_weapon.damage, raycast.get_collision_point())
			current_weapon.hit_impact()
	else:
		print("no hit")

func take_damage(amount, position = 0):
	health -= amount
	health_bar.value = health
	if health <= 0:
		die()

func add_item(item: ItemData, amount: int = 1):
	if item.weapon_scene:
		return
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
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(40, 40)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.75)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.5, 0.5, 0.5)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		panel.add_theme_stylebox_override("panel", style)

		if item.icon:
			var tex_rect := TextureRect.new()
			tex_rect.texture = item.icon
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.anchor_left = 0.0
			tex_rect.anchor_top = 0.0
			tex_rect.anchor_right = 1.0
			tex_rect.anchor_bottom = 1.0
			tex_rect.offset_left = 4
			tex_rect.offset_top = 4
			tex_rect.offset_right = -4
			tex_rect.offset_bottom = -4
			panel.add_child(tex_rect)

		var qty_label := Label.new()
		qty_label.text = str(inventory[item])
		qty_label.add_theme_font_size_override("font_size", 9)
		qty_label.anchor_left = 1.0
		qty_label.anchor_top = 1.0
		qty_label.anchor_right = 1.0
		qty_label.anchor_bottom = 1.0
		qty_label.offset_left = -14
		qty_label.offset_top = -13
		qty_label.offset_right = -2
		qty_label.offset_bottom = -2
		panel.add_child(qty_label)

		inventory_ui.add_child(panel)

func drop_weapon():
	var item = weapon_slots[active_slot]
	if not item:
		print("No hay arma en este slot")
		return
	weapon_slots[active_slot] = null
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null
	crosshair.hide()
	update_weapon_slots_ui()
	print("Soltaste: ", item.item_name)

func heal(amount: int):
	health = min(health + amount, max_health)
	health_bar.value = health
	print("Vida: ", health)

func die():
	print("Game Over")
	get_tree().reload_current_scene()
