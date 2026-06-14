extends VehicleBody3D

# OTHER ASSIST START  
const MAX_STEER = 0.5 
const ENGINE_POWER = 150
const MAX_SPEED = 30.0 
var look_at

# RESET STATE TRACKING VARIABLES
var wants_reset = false

@onready var camera_pivot = $camera_base
@onready var camera_3d = $camera_base/Camera3D

func _ready() -> void:
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	look_at = global_position
	
func _physics_process(delta):
	# 1. GET CURRENT SPEED
	var speed = linear_velocity.length()
	
	# 2. SPEED-SENSITIVE STEERING
	var speed_steer_modifier = clamp(1.0 - (speed / 80.0), 0.5, 1.0)
	var current_max_steer = MAX_STEER * speed_steer_modifier
	
	steering = move_toward(steering, Input.get_axis("d", "a") * current_max_steer, delta * 3.5)
	
	# 3. ENGINE FORCE & MAX SPEED LIMITER
	var throttle_input = Input.get_axis("s", "w")
	
	if speed >= MAX_SPEED and throttle_input > 0:
		engine_force = 0.0
	else:
		engine_force = throttle_input * ENGINE_POWER
	
	# 4. FAKE DOWNFORCE
	apply_central_force(Vector3.DOWN * speed * 8.0)
	
	# 5. UNFLIP / RESET CAR BUTTON
	if Input.is_action_just_pressed("reset_car") or Input.is_key_pressed(KEY_R):
		wants_reset = true # Trigger the safe reset block below

	# ==========================================
	# CAMERA BEHAVIOR (COMPENSATED FOR 180 FLIP)
	# ==========================================
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20.0)
	camera_pivot.rotation.y = rotation.y + PI
	camera_pivot.rotation.x = move_toward(camera_pivot.rotation.x, rotation.x, delta * 5.0)
	camera_pivot.rotation.z = move_toward(camera_pivot.rotation.z, rotation.z, delta * 5.0)
	
	var static_look_at = global_position + transform.basis.z * 3.0 + Vector3.UP * 0.4
	look_at = look_at.lerp(static_look_at, delta * 10.0)
	
	camera_3d.look_at(look_at)
# OTHER ASSIST END

# This handles the structural physics changes safely so the car doesn't freeze or lock up
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# If we are NOT pressing reset, let Godot process normal driving behaviors!
	if not wants_reset:
		return
		
	# 1. Zero out all tumbling momentum instantly
	state.linear_velocity = Vector3.ZERO
	state.angular_velocity = Vector3.ZERO
	
	# 2. Extract ONLY the horizontal direction (Yaw) the car was facing
	var current_y_rotation = state.transform.basis.get_euler().y
	
	# 3. Rebuild a clean, perfectly flat orientation matrix (clears pitch and roll)
	var clean_basis = Basis.from_euler(Vector3(0, current_y_rotation, 0))
	
	# 4. Apply the flat rotation and lift the chassis up slightly to avoid clipping the ground
	var target_transform = Transform3D(clean_basis, state.transform.origin)
	target_transform.origin.y += 0.3
	
	state.transform = target_transform
	
	# 5. Prevent the vehicle from dropping into a sleep state
	sleeping = false
	wants_reset = false
