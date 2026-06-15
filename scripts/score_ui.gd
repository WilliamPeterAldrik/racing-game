extends CanvasLayer

@onready var score_label: Label = $ScoreLabel

# Kita ubah dari NodePath jadi Node langsung, jauh lebih kebal error!
@export var checkpoints: Node

func _ready() -> void:
	if checkpoints:
		# Menyambungkan sinyal dari node lap_system ke fungsi update skor
		checkpoints.score_updated.connect(_on_score_updated)
		print("MANTAP: ScoreHUD berhasil nyambung ke Checkpoint!")
	else:
		print("WADUH: Node Checkpoint belum di-assign di Inspector ScoreHUD!")

# Fungsi ini yang bakal ngubah teks di layar
func _on_score_updated(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score
