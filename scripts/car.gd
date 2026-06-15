extends VehicleBody3D

# TIME TRIAL SIGNALS & VARIABLES
signal time_updated(time_string: String) 
signal raw_time_updated(total_seconds: float) 

var elapsed_time: float = 0.0
var timer_active: bool = true 

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

func _ready() -> void:
	look_at = global_position
	
	if spawn_point_marker:
		global_transform = spawn_point_marker.global_transform
	
	if camera_pivot:
		fixed_camera_height = camera_pivot.global_position.y
	
	if engine_on: engine_on.play()
	if engine_off: engine_off.play()
	
func _process(delta: float) -> void:
	if timer_active:
		elapsed_time += delta
		calculate_and_send_time()

func _physics_process(delta):
	var speed = linear_velocity.length()
	var speed_steer_modifier = clamp(1.0 - (speed / 80.0), 0.5, 1.0)
	var current_max_steer = MAX_STEER * speed_steer_modifier
	
	steering = move_toward(steering, Input.get_axis("d", "a") * current_max_steer, delta * 3.5)
	
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

# OTHER ASSIST END

func calculate_and_send_time() -> void:
	var minutes: int = int(elapsed_time / 60.0)
	var seconds: int = int(elapsed_time) % 60
	var milliseconds: int = int((elapsed_time - int(elapsed_time)) * 1000.0)
	var time_string = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	time_updated.emit(time_string)
	raw_time_updated.emit(elapsed_time)
