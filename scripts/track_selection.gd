extends Control

#AI ASSITED START
@onready var carousel: CarouselContainer = $CarouselContainer
@onready var left_button: Button = $Panel/HBoxContainer/left_button
@onready var right_button: Button = $Panel/HBoxContainer/right_button

func _ready() -> void:
	left_button.pressed.connect(carousel._left)
	right_button.pressed.connect(carousel._right)
#AI ASSITED END
