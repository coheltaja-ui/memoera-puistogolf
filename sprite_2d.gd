extends Sprite2D

var dragging: bool = false
var drag_offset: Vector2

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check if mouse is inside the sprite's rectangle
				if get_rect().has_point(to_local(event.position)):
					dragging = true
					drag_offset = global_position - get_global_mouse_position()
			else:
				dragging = false

	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + drag_offset
