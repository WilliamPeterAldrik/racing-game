extends CanvasLayer

@onready var lap_label: Label = $LapLabel
@onready var time_label: Label = $TimeLabel

@export var checkpoints_node: NodePath
var checkpoints: Node

func _ready() -> void:
	checkpoints = get_node(checkpoints_node)
	checkpoints.lap_completed.connect(_on_lap_completed)
	checkpoints.race_finished.connect(_on_race_finished)
	_update_lap_label()

func _process(_delta: float) -> void:
	time_label.text = _format_time(checkpoints.get_elapsed_time())

func _on_lap_completed(_lap_number: int, _lap_time: float) -> void:
	_update_lap_label()

func _on_race_finished(_lap_times: Array) -> void:
	time_label.text = "FINISHED!"
	get_tree().change_scene_to_file("res://scenes/UI/time_attack_screen.tscn")

func _update_lap_label() -> void:
	lap_label.text = "Lap %d / %d" % [checkpoints.current_lap, checkpoints.max_laps]

func _format_time(t: float) -> String:
	var minutes = int(t) / 60
	var seconds = int(t) % 60
	var millis = int((t - int(t)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, millis]
