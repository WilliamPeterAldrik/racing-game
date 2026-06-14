extends Node

var lap_times: Array = []
var best_times: Array = []

func record_race(times: Array) -> void:
	lap_times = times
	var total_time = 0.0
	for t in times:
		total_time += t
	best_times.append(total_time)
	best_times.sort()
	if best_times.size() > 3:
		best_times = best_times.slice(0, 3)
