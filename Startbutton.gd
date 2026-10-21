extends TextureButton

func _ready():
	if texture_normal:
		custom_minimum_size = texture_normal.get_size()

func _pressed():
	print("Klikkaus toimii! Vaihdetaan skeneä...")
	get_tree().change_scene_to_file("res://level1.tscn")
