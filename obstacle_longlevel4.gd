extends Node2D

@export var amplitude: float = 50.0   # How far up/down to move (pixels)
@export var speed: float = 0.5       # How fast to oscillate (cycles per second)

var start_y: float
var time: float = 0.0

func _ready():
	start_y = global_position.y

func _process(delta: float) -> void:
	time += delta * speed
	# Smooth sine oscillation
	global_position.y = start_y + sin(time * TAU) * amplitude
