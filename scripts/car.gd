extends VehicleBody3D

# TIME TRIAL SIGNALS & VARIABLES
signal time_updated(time_string: String) # Broadcasts the formatted string to your UI scene
signal raw_time_updated(total_seconds: float) # Broadcasts the exact raw math decimal

var elapsed_time: float = 0.0
var timer_active: bool = true # Set to false if you want the clock to wait for a countdown

# OTHER ASSIST START
const MAX_STEER = 0.5
const ENGINE_POWER = 150
const MAX_SPEED = 30.0

# COASTING & DRAG CONFIGURATION
const ENGINE_BRAKING_FORCE = 2.0 # How fast the car slows down when you let go of gas
const AIR_RESISTANCE = 0.5        # Subtle deceleration drag that increases at high speeds

var look_at

# RESET STATE TRACKING VARIABLES
var wants_reset = false

# EXPORT LINK FOR THE SPAWN POINT MARKER
@export var spawn_point_marker: Marker3D

@onready var camera_pivot = $camera_base
@onready var camera_3d = $camera_base/Camera3D

# CAMERA STABILIZATION VARIABLES
var fixed_camera_height: float = 0.0

# AUDIO NODE REFERENCES
@onready var engine_on = $EngineOn
@onready var engine_off = $EngineOff

const MIN_PITCH = 0.6
const MAX_PITCH = 2.5

# DRIFT VARIABLES
var is_drifting = false
var rear_wheels = []
const NORMAL_FRICTION = 10.5
const DRIFT_FRICTION = 0.15 # Tuned up slightly from 0.05 to keep tires gripping flat ground

func _ready() -> void:
	look_at = global_position

	if spawn_point_marker:
		global_transform = spawn_point_marker.global_transform
	
	if camera_pivot:
		# FIXED: Modifying class variable instead of declaring a broken local one
		fixed_camera_height = camera_pivot.global_position.y
	
	if engine_on: engine_on.play()
	if engine_off: engine_off.play()
	
	# INITIALIZE DRIFT SYSTEM
	_setup_drift()
	
func _process(delta: float) -> void:
	# 1. INDEPENDENT TIMER CORE
	if timer_active:
		elapsed_time += delta
		calculate_and_send_time()

func _physics_process(delta):
	var speed = linear_velocity.length()

	var throttle_input = Input.get_axis("s", "w")
	var steer_input = Input.get_axis("d", "a")
	
	# 3. SPEED-SENSITIVE STEERING
	var speed_steer_modifier = clamp(1.0 - (speed / 80.0), 0.5, 1.0)
	var current_max_steer = MAX_STEER * speed_steer_modifier
	
	# 4. DRIFT LOGIC & ENGINE FORCE UNIFIED
	var current_power = ENGINE_POWER
	var current_max_speed = MAX_SPEED
	
	# ==========================================
	# DRIFT PERFORMANCE CONFIGURATION
	# ==========================================
	if is_drifting:
		current_max_steer = MAX_STEER * 1.3 
		current_max_speed = MAX_SPEED * 1.2 
		current_power = ENGINE_POWER * 1.05 # Tamed power output so tires don't flip the frame
		
		if steer_input != 0:
			if abs(angular_velocity.y) < 1.6: 
				# Scaled slip torque down to prevent rapid dynamic roll over
				var slip_torque = steer_input * clamp(speed, 5.0, 20.0) * 10.0
				apply_torque(Vector3(0, slip_torque, 0))

	steering = move_toward(steering, steer_input * current_max_steer, delta * 4.0)

	# ==========================================
	# DRIVE / REVERSE / COASTING ENGINE
	# ==========================================
	if throttle_input > 0:
		# DRIVING FORWARD
		brake = 0.0 
		if speed >= current_max_speed:
			engine_force = 0.0
		else:
			engine_force = throttle_input * current_power
			
	elif throttle_input < 0:
		# ACTIVE REVERSE / BACKWARDS
		brake = 0.0 
		engine_force = throttle_input * ENGINE_POWER 
		
	else:
		# PEDAL RELEASED (COASTING)
		engine_force = 0.0
		if speed > 0.1:
			brake = ENGINE_BRAKING_FORCE * (speed / MAX_SPEED)
		else:
			brake = 5.0

	# ==========================================
	# ANTI-FLIP GROUND MAGNETS
	# ==========================================
	# Base Downforce
	apply_central_force(Vector3.DOWN * speed * 8.0)
	
	# Extra grounding force to counter anti-centrifugal tipping while sliding
	if is_drifting:
		apply_central_force(Vector3.DOWN * speed * 15.0)
		
	if speed > 1.0:
		var drag_direction = -linear_velocity.normalized()
		apply_central_force(drag_direction * speed * AIR_RESISTANCE)

	# 6. UNFLIP / RESET CAR BUTTON
	if Input.is_action_just_pressed("reset_car") or Input.is_key_pressed(KEY_R):
		wants_reset = true 
		elapsed_time = 0.0
		timer_active = true
		
	# ==========================================
	# FIXED Y CAMERA BEHAVIOR
	# ==========================================
	camera_pivot.top_level = true
	var target_position = global_position
	target_position.y = fixed_camera_height
	camera_pivot.global_position = camera_pivot.global_position.lerp(target_position, delta * 20.0)
	
	camera_pivot.rotation.y = rotation.y + PI
	camera_pivot.rotation.x = move_toward(camera_pivot.rotation.x, rotation.x, delta * 5.0)
	camera_pivot.rotation.z = move_toward(camera_pivot.rotation.z, rotation.z, delta * 5.0)
	
	var static_look_at = global_position + transform.basis.z * 3.0 + Vector3.UP * 0.4
	look_at = look_at.lerp(static_look_at, delta * 10.0)
	camera_3d.look_at(look_at)
	
	# ==========================================
	# ENGINE AUDIO
	# ==========================================
	if engine_on and engine_off:
		var pitch_ratio = speed / MAX_SPEED
		var target_pitch = lerp(MIN_PITCH, MAX_PITCH, pitch_ratio)
		
		var current_pitch = move_toward(engine_on.pitch_scale, target_pitch, delta * 6.0)
		engine_on.pitch_scale = current_pitch
		engine_off.pitch_scale = current_pitch
		
		if throttle_input > 0:
			engine_on.volume_db = move_toward(engine_on.volume_db, -10.0, delta * 25.0)
			engine_off.volume_db = move_toward(engine_off.volume_db, -45.0, delta * 25.0)
		else:
			engine_on.volume_db = move_toward(engine_on.volume_db, -45.0, delta * 15.0)
			if speed < 1.0:
				engine_off.volume_db = move_toward(engine_off.volume_db, -22.0, delta * 15.0)
			else:
				engine_off.volume_db = move_toward(engine_off.volume_db, -12.0, delta * 15.0)

	# Run drift rules
	_process_drift()

# ==========================================
# SAFE JOLT-SPECIFIC RESET ENGINE
# ==========================================
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not wants_reset:
		return
		
	sleeping = false
	engine_force = 0.0
	brake = 0.0
	steering = 0.0
	
	state.linear_velocity = Vector3.ZERO
	state.angular_velocity = Vector3.ZERO
	
	if spawn_point_marker:
		state.transform = spawn_point_marker.global_transform
	else:
		var current_y_rotation = state.transform.basis.get_euler().y
		var flat_basis = Basis.from_euler(Vector3(0, current_y_rotation, 0))
		state.transform = Transform3D(flat_basis, state.transform.origin)
	
	wants_reset = false
	
	if engine_on and engine_off:
		engine_on.pitch_scale = MIN_PITCH
		engine_off.pitch_scale = MIN_PITCH
		engine_on.volume_db = -40.0
		engine_off.volume_db = -10.0

func calculate_and_send_time() -> void:
	var minutes: int = int(elapsed_time / 60.0)
	var seconds: int = int(elapsed_time) % 60
	var milliseconds: int = int((elapsed_time - int(elapsed_time)) * 1000.0)
	var time_string = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	
	time_updated.emit(time_string)
	raw_time_updated.emit(elapsed_time)
	
# ==========================================
# DRIFT UTILITY MODULES
# ==========================================
func _setup_drift():
	rear_wheels.clear()
	for child in get_children():
		if child is VehicleWheel3D and not child.use_as_steering:
			rear_wheels.append(child)
			
	print("Jumlah ban belakang yang ngesot: ", rear_wheels.size())

func _process_drift():
	if Input.is_action_pressed("drift") and linear_velocity.length() > 5.0:
		if not is_drifting:
			_start_drift()
	else:
		if is_drifting:
			_stop_drift()

func _start_drift():
	is_drifting = true
	center_of_mass.y = -0.6 # Shifts mass down low to mechanically prevent rollovers
	
	for wheel in rear_wheels:
		wheel.wheel_friction_slip = DRIFT_FRICTION
		
	if has_node("MeshInstance3D"):
		var tween_hop = create_tween()
		tween_hop.tween_property($MeshInstance3D, "position:y", 0.15, 0.05) 
		tween_hop.tween_property($MeshInstance3D, "position:y", 0.0, 0.05)
		
	if camera_3d:
		var tween_cam = create_tween()
		tween_cam.tween_property(camera_3d, "fov", 85.0, 0.3)

func _stop_drift():
	is_drifting = false
	center_of_mass.y = 0.0 # Return center of mass to regular structural height
	
	for wheel in rear_wheels:
		wheel.wheel_friction_slip = NORMAL_FRICTION
		
	if camera_3d:
		var tween_cam = create_tween()
		tween_cam.tween_property(camera_3d, "fov", 75.0, 0.3)
