extends StaticBody2D

var dragging = false
var drag_offset = Vector2.ZERO


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var sprite = $Sprite2D
			if sprite:
				var local_mouse = sprite.to_local(event.global_position)
				var sprite_rect = sprite.get_rect()
				if sprite_rect.has_point(local_mouse):
					dragging = true
					drag_offset = global_position - get_global_mouse_position()
		else:
			dragging = false

func _physics_process(delta):
	if dragging:
		var target = get_global_mouse_position() + drag_offset
		linear_velocity = (target - global_position) * 10.0
	else:
		linear_velocity = Vector2.ZERO
