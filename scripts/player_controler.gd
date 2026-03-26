extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.002
@export var max_health := 100
var health: int

@onready var camera := $Camera3D
@onready var raycast := $Camera3D/RayCast3D
@onready var health_bar := $CanvasLayer/Control/ProgressBar
@onready var anim_player := $AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health = max_health
	raycast.add_exception(self)
	health_bar.value = health

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
	
	if Input.is_action_pressed("ui_up"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("ui_down"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("ui_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("ui_right"):
		input_dir += transform.basis.x
	
	input_dir = input_dir.normalized()
	velocity.x = input_dir.x * speed
	velocity.z = input_dir.z * speed
	
	move_and_slide()

func attack():
	if anim_player.is_playing():
		return
	anim_player.play("attack")
	if raycast.is_colliding():
		var target = raycast.get_collider()
		print("Hit: ", target.name)
		if target.has_method("take_damage"):
			target.take_damage(10)
			print("Daño aplicado")
	else:
		print("No hit")

func take_damage(amount):
	health -= amount
	health_bar.value = health
	if health <= 0:
		die()

func die():
	print("Game Over")
	get_tree().reload_current_scene()
