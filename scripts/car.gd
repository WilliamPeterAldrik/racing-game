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
	steering = move_toward(steering, Input.get_axis("d","a") * MAX_STEER,delta *2.5)
	engine_force = Input.get_axis("s","w") * ENGINE_POWER
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position,delta*20.0)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform,delta*5.0)
	look_at = look_at.lerp(global_position + linear_velocity, delta * 5.0)
	camera_3d.look_at(global_position + linear_velocity)
#OTHER ASSIST END
