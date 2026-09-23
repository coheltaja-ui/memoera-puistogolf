extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "golfball" or body.name == "Ballbody2d":
		
		# Remove everything in the current scene
		for child in get_tree().current_scene.get_children():
			if child != self:
				child.queue_free()

		# Show message
		var label = Label.new()
		label.text = "Hyvin menee! :)"
		label.position = Vector2(400, 300)
		label.add_theme_font_size_override("font_size", 40)
		get_tree().current_scene.add_child(label)

		# Wait 2 seconds
		await get_tree().create_timer(2.0).timeout

		# Go to level 2
		get_tree().change_scene_to_file("res://level2.tscn")
