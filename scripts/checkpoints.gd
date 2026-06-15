extends Node

signal lap_completed(lap_number: int, lap_time: float)
signal race_finished(lap_times: Array)

var current_lap = 1
var max_laps = 3 
# Balapan selesai di 3 lap
var next_checkpoint_index = 0
var lap_times = []
var start_time = 0.0
var lap_start_time = 0.0

@onready var checkpoints = self # Path ke folder penyimpan Area3D

func _ready():
	start_time = Time.get_ticks_msec() / 1000.0
	lap_start_time = start_time
	
	# Menghubungkan semua checkpoint secara otomatis
	var index = 0
	for cp in checkpoints.get_children():
		if cp is Area3D:
			cp.body_entered.connect(_on_checkpoint_entered.bind(index))
			index += 1

func _on_checkpoint_entered(body: Node3D, cp_index: int):
	# Pastikan yang menabrak adalah mobil (ganti "kart_1" dengan nama node mobilmu)
	if body.name == "kart_1": 
		# Cek apakah checkpoint dilewati secara urut
		if cp_index == next_checkpoint_index:
			next_checkpoint_index += 1
			print("Lewat checkpoint: ", cp_index)
			
			# Jika ini checkpoint terakhir (Garis Finish)
			if next_checkpoint_index >= checkpoints.get_child_count():
				_lap_selesai()

func _lap_selesai():
	# Hitung waktu putaran
	var now = Time.get_ticks_msec() / 1000.0
	var lap_time = now - lap_start_time
	lap_times.append(lap_time)
	
	if current_lap >= max_laps:
		print("Balapan Selesai! Kamu Hebat!")
		RaceResult.record_race(lap_times)
		race_finished.emit(lap_times)
		# Nanti di sini kamu bisa panggil UI buat nunjukin skor akhir
	else:
		lap_completed.emit(current_lap, lap_time)
		current_lap += 1
		next_checkpoint_index = 0
		lap_start_time = now  # 

func get_elapsed_time() -> float:
	return (Time.get_ticks_msec() / 1000.0) - start_time
