extends Node3D

@onready var car = $"kart-oobi2" # Make sure this matches your car node's exact name!

func _on_finish_line_body_entered(body: Node3D) -> void:
	# Walk up the parent tree if a wheel or body mesh triggered it first
	var actual_vehicle = body
	while actual_vehicle and not actual_vehicle is VehicleBody3D:
		actual_vehicle = actual_vehicle.get_parent()
		
	# If we successfully found a vehicle script in the chain
	if actual_vehicle and "elapsed_time" in actual_vehicle:
		actual_vehicle.timer_active = false
		
		var minutes: int = int(actual_vehicle.elapsed_time / 60.0)
		var seconds: int = int(actual_vehicle.elapsed_time) % 60
		var milliseconds: int = int((actual_vehicle.elapsed_time - int(actual_vehicle.elapsed_time)) * 1000.0)
		var final_time_string = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
		
		print("--- RACE FINISHED! ---")
		print("Final Lap Time: ", final_time_string)
