extends Node

@onready var hole_in_one_sound: AudioStreamPlayer = $HoleInOneSound

func _on_hole_in_one():
	hole_in_one_sound.play()
