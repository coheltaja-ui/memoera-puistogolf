extends Area2D

@onready var sound = $goalsound
var level_complete = false # Estää koodin ajamisen kahdesti, jos pallo osuu uudestaan

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if level_complete:
		return

	if body.name == "golfball" or body.name == "Ballbody2d":
		level_complete = true
		sound.play()

		# Piilotetaan muut elementit, mutta EI tuhota niitä (estää kaatumisen)
		for child in get_tree().current_scene.get_children():
			if child != self:
				if child is CanvasItem: child.hide()

		# Luodaan CanvasLayer, jotta teksti näkyy varmasti kaiken päällä
		var canvas_layer = CanvasLayer.new()
		get_tree().current_scene.add_child(canvas_layer)

		# Luodaan onnitteluteksti
		var label = Label.new()
		label.text = "Hyvin menee!"
		label.position = Vector2(400, 300)
		label.add_theme_font_size_override("font_size", 40)
		canvas_layer.add_child(label)

		# Odotetaan 2 sekuntia
		await get_tree().create_timer(2.0).timeout

		# Siirrytään tasolle 2
		get_tree().change_scene_to_file("res://level2.tscn")
