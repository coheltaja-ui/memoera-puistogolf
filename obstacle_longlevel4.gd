extends Node2D

@export var amplitude: float = 50.0
@export var speed: float = 0.5       
@export var slowdown_time: float = 300.0  

var start_y: float
var time: float = 0.0
var elapsed: float = 0.0

func _ready():
	start_y = global_position.y

func _process(delta: float) -> void:
	elapsed += delta
	
	
	var progress = clamp(elapsed / slowdown_time, 0.0, 1.0)
	
	
	var current_speed = speed * (1.0 - progress)
	
	
	time += delta * current_speed
	
	
	global_position.y = start_y + sin(time * TAU) * amplitude
