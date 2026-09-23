extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	#if body is RigidBody2D:
		#var label = Label.new()
		#label.text = "Congratulations!"
		#label.position = Vector2(400, 300)
		#get_tree().current_scene.add_child(label)

		if body.name == "golfball":
			get_tree().change_scene_to_file("res://level4.tscn")
		if body.name == "Ballbody2d":
			get_tree().change_scene_to_file("res://level4.tscn")
