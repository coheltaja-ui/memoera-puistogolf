extends RigidBody2D

var dragging = false
var drag_offset = Vector2.ZERO
var last_mouse_position = Vector2.ZERO
var throw_velocity = Vector2.ZERO

@export var throw_strength := 10
@export var max_throw_speed := 800

func _ready():
	gravity_scale = 0
	linear_damp = 0.8

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
					last_mouse_position = get_global_mouse_position()
					throw_velocity = Vector2.ZERO

		else:
			if dragging:
				dragging = false

				linear_velocity = (
					throw_velocity * throw_strength
				).limit_length(max_throw_speed)

func _physics_process(delta):
	if dragging:
		var mouse_position = get_global_mouse_position()
		var target = mouse_position + drag_offset

		linear_velocity = (target - global_position) * 10.0

		throw_velocity = (mouse_position - last_mouse_position) / delta
		last_mouse_position = mouse_position
