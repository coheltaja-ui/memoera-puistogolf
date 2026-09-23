extends Area2D

var level_complete = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if level_complete:
		return

	if body.name == "golfball" or body.name == "Ballbody2d":
		level_complete = true

		# Hide everything in the current level
		for child in get_tree().current_scene.get_children():
			if child != self:
				child.hide()

		# Create a CanvasLayer for the message
		var canvas_layer = CanvasLayer.new()
		get_tree().current_scene.add_child(canvas_layer)

		# Create the message
		var label = Label.new()
		label.text = "Mahtavaa!"
		label.position = Vector2(400, 300)
		label.add_theme_font_size_override("font_size", 40)
		canvas_layer.add_child(label)

		# Wait 2 seconds
		await get_tree().create_timer(2.0).timeout

		# Go to level 3
		get_tree().change_scene_to_file("res://level3.tscn")
