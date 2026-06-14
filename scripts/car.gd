extends VehicleBody3D

# OTHER ASSIST START  
const MAX_STEER = 0.5 
const ENGINE_POWER = 150
const MAX_SPEED = 50.0 
var look_at

# RESET STATE TRACKING VARIABLES
var wants_reset = false

@onready var camera_pivot = $camera_base
@onready var camera_3d = $camera_base/Camera3D

# VIDEO IMPLEMENTATION NODE REFERENCES
@onready var engine_on = $EngineOn
@onready var engine_off = $EngineOff

# TUNING CONSTANTS (From the video's logic)
const MIN_PITCH = 0.6
const MAX_PITCH = 2.5

func _ready() -> void:
	look_at = global_position
	
	# Start both players immediately so they stay seamlessly synchronized
	if engine_on: engine_on.play()
	if engine_off: engine_off.play()
	
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
		wants_reset = true 

	# ==========================================
	# CAMERA BEHAVIOR
	# ==========================================
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20.0)
	camera_pivot.rotation.y = rotation.y + PI
	camera_pivot.rotation.x = move_toward(camera_pivot.rotation.x, rotation.x, delta * 5.0)
	camera_pivot.rotation.z = move_toward(camera_pivot.rotation.z, rotation.z, delta * 5.0)
	
	var static_look_at = global_position + transform.basis.z * 3.0 + Vector3.UP * 0.4
	look_at = look_at.lerp(static_look_at, delta * 10.0)
	camera_3d.look_at(look_at)
	
	# ==========================================
	# VIDEO ENGINE AUDIO IMPLEMENTATION
	# ==========================================
	if engine_on and engine_off:
		# Calculate pitch based on current vehicle velocity
		var pitch_ratio = speed / MAX_SPEED
		var target_pitch = lerp(MIN_PITCH, MAX_PITCH, pitch_ratio)
		
		# Smoothly slide the real pitch to prevent audio snapping
		var current_pitch = move_toward(engine_on.pitch_scale, target_pitch, delta * 6.0)
		engine_on.pitch_scale = current_pitch
		engine_off.pitch_scale = current_pitch
		
		# CORE MECHANIC: Is the player actively pressing the gas? (W key)
		if throttle_input > 0:
			# Crossfade to 'On' sound (Player hears the engine pulling under load)
			engine_on.volume_db = move_toward(engine_on.volume_db, 0.0, delta * 25.0)
			engine_off.volume_db = move_toward(engine_off.volume_db, -40.0, delta * 25.0)
		else:
			# Crossfade to 'Off' sound (Player hears engine braking or idling)
			engine_on.volume_db = move_toward(engine_on.volume_db, -40.0, delta * 15.0)
			
			# If completely stopped, make the idle volume a tiny bit quieter
			if speed < 1.0:
				engine_off.volume_db = move_toward(engine_off.volume_db, -10.0, delta * 5.0)
			else:
				engine_off.volume_db = move_toward(engine_off.volume_db, 0.0, delta * 5.0)

# OTHER ASSIST END

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not wants_reset:
		return
		
	state.linear_velocity = Vector3.ZERO
	state.angular_velocity = Vector3.ZERO
	
	var current_y_rotation = state.transform.basis.get_euler().y
	var clean_basis = Basis.from_euler(Vector3(0, current_y_rotation, 0))
	
	var target_transform = Transform3D(clean_basis, state.transform.origin)
	target_transform.origin.y += 0.3
	
	state.transform = target_transform
	
	# Reset audio nodes immediately on car unflip
	if engine_on and engine_off:
		engine_on.pitch_scale = MIN_PITCH
		engine_off.pitch_scale = MIN_PITCH
		engine_on.volume_db = -40.0
		engine_off.volume_db = -10.0
	
	sleeping = false
	wants_reset = false
