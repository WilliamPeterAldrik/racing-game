extends Node

signal lap_completed(lap_number: int, lap_time: float)
signal race_finished(lap_times: Array)
signal score_updated(new_score: int) # Tambahan sinyal untuk HUD Score

var current_lap = 1
var max_laps = 3 
# Balapan selesai di 3 lap
var next_checkpoint_index = 0
var lap_times = []
var start_time = 0.0
var lap_start_time = 0.0

# --- VARIABEL SKOR ---
var current_score: int = 0
var score_timer: float = 0.0
var race_active: bool = false

@onready var checkpoints = self # Path ke folder penyimpan Area3D

func _ready():
	start_time = Time.get_ticks_msec() / 1000.0
	lap_start_time = start_time
	race_active = true
	
	# Menghubungkan semua checkpoint secara otomatis
	var index = 0
	for cp in checkpoints.get_children():
		if cp is Area3D:
			cp.body_entered.connect(_on_checkpoint_entered.bind(index))
			index += 1

func _process(delta):
	# Nambah skor terus menerus selama balapan masih berlangsung
	if race_active:
		score_timer += delta
		if score_timer >= 0.5: # Setiap 0.5 detik balapan, tambah 1 poin
			current_score += 1
			score_updated.emit(current_score)
			score_timer = 0.0

func _on_checkpoint_entered(body: Node3D, cp_index: int):
	# Pastikan yang menabrak adalah mobil (ganti "kart_1" dengan nama node mobilmu)
	if body.name == "kart_1" and race_active: 
		# Cek apakah checkpoint dilewati secara urut (jalan sesuai track)
		if cp_index == next_checkpoint_index:
			next_checkpoint_index += 1
			print("Lewat checkpoint: ", cp_index)
			
			# Tambah +20 point karena lewat checkpoint yang benar
			current_score += 20
			score_updated.emit(current_score)
			
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
		race_active = false # Stop nambah skor saat finish
		if has_node("/root/RaceResult"): # Amanin kalau Autoload RaceResult belum dipasang
			RaceResult.record_race(lap_times)
		race_finished.emit(lap_times)
	else:
		lap_completed.emit(current_lap, lap_time)
		current_lap += 1
		next_checkpoint_index = 0
		lap_start_time = now  

func get_elapsed_time() -> float:
	return (Time.get_ticks_msec() / 1000.0) - start_time
