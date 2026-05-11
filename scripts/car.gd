extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 40

# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

var target_velocity = Vector3.ZERO
var camera: Camera3D

func _ready():
	# Get the camera reference
	camera = get_node("Camera3D")

func _physics_process(delta):
	var input_dir = Vector3.ZERO

	# Get input direction
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()
		
		# Transform the input direction relative to camera orientation
		var camera_basis = camera.get_global_transform().basis
		var direction = camera_basis * input_dir
		direction.y = 0  # Keep movement horizontal
		direction = direction.normalized()
		
		# Rotate the character to face movement direction
		if $Pivot:
			$Pivot.basis = Basis.looking_at(direction)
		
		# Ground Velocity
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed
	else:
		# No input - decelerate
		target_velocity.x = move_toward(target_velocity.x, 0, speed * 2 * delta)
		target_velocity.z = move_toward(target_velocity.z, 0, speed * 2 * delta)

	# Vertical Velocity
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	else:
		target_velocity.y = 0  # Reset vertical velocity when on ground

	# Moving the Character
	velocity = target_velocity
	move_and_slide()
