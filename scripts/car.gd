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

# AUDIO NODE REFERENCES
@onready var engine_on = $EngineOn
@onready var engine_off = $EngineOff

const MIN_PITCH = 0.6
const MAX_PITCH = 2.5

func _ready() -> void:
	look_at = global_position
	
<<<<<<< HEAD
	if spawn_point_marker:
		global_transform = spawn_point_marker.global_transform
	
	if camera_pivot:
		fixed_camera_height = camera_pivot.global_position.y
	
=======
>>>>>>> f95d1783e91dffdd7e456e3bfc5a80185dc907c7
	if engine_on: engine_on.play()
	if engine_off: engine_off.play()
	
func _process(delta: float) -> void:
	# 1. INDEPENDENT TIMER CORE
	if timer_active:
		elapsed_time += delta
		calculate_and_send_time()

func _physics_process(delta):
	var speed = linear_velocity.length()
<<<<<<< HEAD
=======
	var throttle_input = Input.get_axis("s", "w")
	var steer_input = Input.get_axis("d", "a")
	
	# 3. SPEED-SENSITIVE STEERING
>>>>>>> f95d1783e91dffdd7e456e3bfc5a80185dc907c7
	var speed_steer_modifier = clamp(1.0 - (speed / 80.0), 0.5, 1.0)
	var current_max_steer = MAX_STEER * speed_steer_modifier
	
	# 4. DRIFT LOGIC & ENGINE FORCE UNIFIED
	var current_power = ENGINE_POWER
	var current_max_speed = MAX_SPEED
	
<<<<<<< HEAD
	# INPUT READ
	var throttle_input = Input.get_axis("s", "w")
	
	# ==========================================
	# FIXED DRIVE / REVERSE / COASTING ENGINE
	# ==========================================
	if throttle_input > 0:
		# 1. DRIVING FORWARD
		brake = 0.0 
		if speed >= MAX_SPEED:
			engine_force = 0.0
		else:
			engine_force = throttle_input * ENGINE_POWER
			
	elif throttle_input < 0:
		# 2. ACTIVE REVERSE / BACKWARDS
		brake = 0.0 
		# Give reverse ample power to reliably overcome tire grip friction
		engine_force = throttle_input * ENGINE_POWER 
		
	else:
		# 3. PEDAL RELEASED (COASTING)
		engine_force = 0.0
		
		if speed > 0.1:
			# Apply automatic light resistance relative to current speed
			brake = ENGINE_BRAKING_FORCE * (speed / MAX_SPEED)
		else:
			# Holding brake when fully stopped to prevent rolling away
			brake = 5.0

	# Apply ongoing dynamic aerodynamic drag force
	apply_central_force(Vector3.DOWN * speed * 8.0) # Downforce
	if speed > 1.0:
		var drag_direction = -linear_velocity.normalized()
		apply_central_force(drag_direction * speed * AIR_RESISTANCE)

	# TRIGGER RESET CHECK
=======
	if is_drifting:
		# Bikin setir lebih patah dari biasanya
		current_max_steer = MAX_STEER * 2.0 
		current_max_speed = MAX_SPEED * 1.5 
		current_power = ENGINE_POWER * 3.0 
		
		if steer_input != 0:
			# Batasi momentum putaran maksimal agar tidak menumpuk kalau ditahan lama
			if abs(angular_velocity.y) < 2.5: 
				var slip_torque = steer_input * speed * 40.0 # Angka 60 diturunkan ke 40 agar lebih halus
				apply_torque(Vector3(0, slip_torque, 0))

	steering = move_toward(steering, steer_input * current_max_steer, delta * 4.0)

	# Apply the engine force, respecting the current max speed limit
	if speed >= current_max_speed and throttle_input > 0:
		engine_force = 0.0
	else:
		engine_force = throttle_input * current_power
	
	# 5. FAKE DOWNFORCE
	apply_central_force(Vector3.DOWN * speed * 8.0)
	
	# 6. UNFLIP / RESET CAR BUTTON
>>>>>>> f95d1783e91dffdd7e456e3bfc5a80185dc907c7
	if Input.is_action_just_pressed("reset_car") or Input.is_key_pressed(KEY_R):
		wants_reset = true 
		elapsed_time = 0.0
		timer_active = true
	# ==========================================
<<<<<<< HEAD
	# FIXED Y CAMERA BEHAVIOR
	# ==========================================
	camera_pivot.top_level = true
	var target_position = global_position
	target_position.y = fixed_camera_height
	camera_pivot.global_position = camera_pivot.global_position.lerp(target_position, delta * 20.0)
	
=======
	# CAMERA BEHAVIOR
	# ==========================================
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20.0)
>>>>>>> f95d1783e91dffdd7e456e3bfc5a80185dc907c7
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
<<<<<<< HEAD

# ==========================================
# SAFE JOLT-SPECIFIC RESET ENGINE
# ==========================================
=======
				
	# ==========================================
	# RUN DRIFT DETECTION
	# ==========================================
	_process_drift()
	
# OTHER ASSIST END

>>>>>>> f95d1783e91dffdd7e456e3bfc5a80185dc907c7
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

# OTHER ASSIST END

func calculate_and_send_time() -> void:
	# 1. Break down elapsed time into racing units
	var minutes: int = int(elapsed_time / 60.0)
	var seconds: int = int(elapsed_time) % 60
	var milliseconds: int = int((elapsed_time - int(elapsed_time)) * 1000.0)
<<<<<<< HEAD
	var time_string = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
=======
	
	# 2. Format string (e.g., "01:24.005")
	var time_string = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	
	# 3. Shoot signals into the air for your UI scene to catch
>>>>>>> f95d1783e91dffdd7e456e3bfc5a80185dc907c7
	time_updated.emit(time_string)
	raw_time_updated.emit(elapsed_time)
	
#AI help
var is_drifting = false
var rear_wheels = []
const NORMAL_FRICTION = 10.5
const DRIFT_FRICTION = 0.05

func _setup_drift():
	for child in get_children():
		if child is VehicleWheel3D and not child.use_as_steering:
			rear_wheels.append(child)
			
	print("Jumlah ban belakang yang ngesot: ", rear_wheels.size())

func _process_drift():
	# Cek tombol drift (Shift) & pastikan mobil lagi jalan lumayan cepat
	if Input.is_action_pressed("drift") and linear_velocity.length() > 5.0:
		if not is_drifting:
			_start_drift()
	else:
		if is_drifting:
			_stop_drift()

func _start_drift():
	is_drifting = true
	# Bikin ban belakang ngesot
	for wheel in rear_wheels:
		wheel.wheel_friction_slip = DRIFT_FRICTION
		
	# Efek visual hop (lompat) ke MeshInstance3D
	if has_node("MeshInstance3D"):
		var tween_hop = create_tween()
		tween_hop.tween_property($MeshInstance3D, "position:y", 0.5, 0.1)
		tween_hop.tween_property($MeshInstance3D, "position:y", 0.0, 0.1)
		
	# Efek zoom out kamera
	var tween_cam = create_tween()
	tween_cam.tween_property(camera_3d, "fov", 90.0, 0.3)

func _stop_drift():
	is_drifting = false
	# Balikin grip ban
	for wheel in rear_wheels:
		wheel.wheel_friction_slip = NORMAL_FRICTION
		
	# Balikin zoom kamera
	var tween_cam = create_tween()
	tween_cam.tween_property(camera_3d, "fov", 75.0, 0.3)
#end of AI help
