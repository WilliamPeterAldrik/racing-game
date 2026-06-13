extends Node

var current_lap = 1
#var max_laps = 3 # Balapan selesai di 3 lap
var next_checkpoint_index = 0
var lap_times = []
var start_time = 0.0

@onready var checkpoints = $Checkpoints # Path ke folder penyimpan Area3D

func _ready():
	start_time = Time.get_ticks_msec() / 1000.0
	
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
	var current_time = (Time.get_ticks_msec() / 1000.0) - start_time
	lap_times.append(current_time)
	print("Lap ", current_lap, " Selesai! Waktu: ", current_time, " detik")
	
	if current_lap >= max_laps:
		print("Balapan Selesai! Kamu Hebat!")
		# Nanti di sini kamu bisa panggil UI buat nunjukin skor akhir
	else:
		current_lap += 1
		next_checkpoint_index = 0
		start_time = Time.get_ticks_msec() / 1000.0 # Reset waktu buat lap selanjutnya
