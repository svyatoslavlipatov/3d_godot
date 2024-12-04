extends CharacterBody3D

var speed 
const walk_speed = 5.0
const run_speed = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const hit_shaking = 1000.0

const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0
var initial_camera_pos: Vector3

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var bullet = load("res://Scenes/bullet.tscn")
var instance 

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var gun_anim = $Head/Camera3D/Rifle_candy/AnimationPlayer
@onready var gun_barrel = $Head/Camera3D/Rifle_candy/RayCast3D


signal player_hit

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	initial_camera_pos = camera.transform.origin


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))



func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle run.
	if Input.is_action_pressed("sprint"):
		speed = run_speed
	else:
		speed = walk_speed

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
		
		
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, run_speed * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	if Input.is_action_pressed("shoot"):
		if !gun_anim.is_playing():
			gun_anim.play("Shoot")
			instance = bullet.instantiate()
			instance.position = gun_barrel.global_position
			instance.transform.basis = gun_barrel.global_transform.basis
			get_parent().add_child(instance)
	
	
	move_and_slide()

func _headbob(time: float) -> Vector3:
	var pos = initial_camera_pos
	pos.x += cos(time * BOB_FREQ / 2) * BOB_AMP
	pos.y += sin(time * BOB_FREQ) * BOB_AMP
	return pos

func hit(dir):
	emit_signal("player_hit")
	velocity += dir  * hit_shaking
	
