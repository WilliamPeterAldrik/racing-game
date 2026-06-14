extends Control

@onready var latest_label: Label = $HBoxContainer/Latest
@onready var label1: Label = $VBoxContainer/Label
@onready var label2: Label = $VBoxContainer/Label2
@onready var label3: Label = $VBoxContainer/Label3

func _ready() -> void:
	var lap_times = RaceResult.lap_times
	if lap_times.size() > 0:
		var total_time = 0.0
		for t in lap_times:
			total_time += t
		latest_label.text = _format_time(total_time)
	else:
		latest_label.text = "--:--.---"

	var best = RaceResult.best_times
	var labels = [label1, label2, label3]
	for i in labels.size():
		if i < best.size():
			labels[i].text = "%d. %s" % [i + 1, _format_time(best[i])]
		else:
			labels[i].text = "%d. --:--.---" % [i + 1]

func _format_time(t: float) -> String:
	var minutes = int(t) / 60
	var seconds = int(t) % 60
	var millis = int((t - int(t)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, millis]


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Race_Track/italy_monza.tscn")


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
