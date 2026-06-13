extends  VehicleBody3D
#OTHER ASSIST START 
const MAX_STEER = 0.8
const ENGINE_POWER = 300
var look_at

@onready var camera_pivot = $camera_base
@onready var camera_3d = $camera_base/Camera3D

func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	look_at = global_position
	
func _physics_process(delta):
	steering = move_toward(steering, Input.get_axis("d","a") * MAX_STEER,delta *2.5)
	engine_force = Input.get_axis("s","w") * ENGINE_POWER
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position,delta*20.0)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform,delta*5.0)
	look_at = look_at.lerp(global_position + linear_velocity, delta * 5.0)
	camera_3d.look_at(global_position + linear_velocity)
	
#AI help
var is_drifting = false
var rear_wheels = []
const NORMAL_FRICTION = 10.5
const DRIFT_FRICTION = 2.0

func _setup_drift():
	# Mengambil node ban belakang secara otomatis dengan mengecek settingannya
	for child in get_children():
		if child is VehicleWheel3D and not child.use_as_steering:
			rear_wheels.append(child)

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
	
#OTHER ASSIST END
