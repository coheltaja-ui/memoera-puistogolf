extends RigidBody2D
## Player block.
##
## The real block on the table moves this block: the camera tracker (track.exe)
## sends the block's position and rotation, and this body follows it with
## physics, so it can hit and push the ball.
## When no real block is detected, the block can still be dragged and thrown
## with the mouse for testing.

@export var throw_strength := 10.0
@export var max_throw_speed := 800.0

@export_group("Table tracking")
## Letter of the physical block that controls this one ("a" to "h").
@export var track_block := "a"
## Turn the in-game block when the real block is turned.
@export var follow_rotation := true
## 0 = follow the camera exactly, closer to 1 = smoother but slower to react.
@export_range(0.0, 0.95) var smoothing := 0.4
## Ignores tiny camera jitter (pixels) so the block doesn't shake while resting.
@export var jitter_deadzone := 1.5
## Highest speed the block can hit the ball with.
@export var max_follow_speed := 2500.0
## How long (seconds) to wait before treating a flickering marker as lifted.
@export var lost_grace_time := 0.25

var dragging := false
var drag_offset := Vector2.ZERO
var last_mouse_position := Vector2.ZERO
var throw_velocity := Vector2.ZERO

## True while the real block is visible to the camera.
var tracked := false

var _tracker: Node = null
var _target_position := Vector2.ZERO
var _target_rotation := 0.0
var _lost_time := 0.0


func _ready() -> void:
	gravity_scale = 0
	linear_damp = 0.8
	# Stops the block from passing through the ball when moved quickly.
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	# A sleeping body ignores new velocities, so keep it awake for the tracker.
	can_sleep = false
	_tracker = get_node_or_null("/root/TableTrack")
	if _tracker == null:
		push_warning("Player block: TableTrack autoload missing, only mouse control works.")


func _input(event: InputEvent) -> void:
	if tracked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var sprite := get_node_or_null("Sprite2D") as Sprite2D
			if sprite and sprite.get_rect().has_point(sprite.to_local(event.global_position)):
				dragging = true
				drag_offset = global_position - get_global_mouse_position()
				last_mouse_position = get_global_mouse_position()
				throw_velocity = Vector2.ZERO
		elif dragging:
			dragging = false
			linear_velocity = (throw_velocity * throw_strength).limit_length(max_throw_speed)


func _physics_process(delta: float) -> void:
	_update_tracking(delta)
	if tracked:
		_follow_table_block(delta)
	elif dragging:
		var mouse_position := get_global_mouse_position()
		linear_velocity = (mouse_position + drag_offset - global_position) * 10.0
		throw_velocity = (mouse_position - last_mouse_position) / delta
		last_mouse_position = mouse_position


func _update_tracking(delta: float) -> void:
	var marker := _find_marker()
	if marker.is_empty():
		if tracked:
			_lost_time += delta
			if _lost_time > lost_grace_time:
				# Real block was lifted or covered: let the in-game block stop.
				tracked = false
				linear_velocity = Vector2.ZERO
				angular_velocity = 0.0
		return

	_lost_time = 0.0
	var position_now := _marker_to_world(marker)
	var rotation_now := deg_to_rad(float(marker.get("rotation_deg", 0.0)))
	if not tracked:
		tracked = true
		dragging = false
		_target_position = position_now
		_target_rotation = rotation_now
		return

	# Frame-rate independent smoothing of the camera pose.
	var weight := 1.0 - pow(smoothing, delta * 60.0)
	if _target_position.distance_to(position_now) > jitter_deadzone:
		_target_position = _target_position.lerp(position_now, weight)
	_target_rotation = lerp_angle(_target_rotation, rotation_now, weight)


func _follow_table_block(delta: float) -> void:
	# Drive the body with velocity (not by teleporting) so collisions with the
	# ball give it a real push in the direction the player moved the block.
	linear_velocity = ((_target_position - global_position) / delta).limit_length(max_follow_speed)
	if follow_rotation:
		angular_velocity = clampf(wrapf(_target_rotation - rotation, -PI, PI) / delta, -40.0, 40.0)
	else:
		angular_velocity = 0.0


func _find_marker() -> Dictionary:
	if _tracker == null:
		return {}
	var frame: Dictionary = _tracker.pose_frame()
	for raw in frame.get("markers", []):
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("block", "")) == track_block:
			return raw
	return {}


## Tracker gives 0-1 coordinates across the table; map them onto the game view.
func _marker_to_world(marker: Dictionary) -> Vector2:
	var view := get_viewport().get_visible_rect().size
	var screen := TableTrackClient.marker_position(marker, view)
	return get_viewport().get_canvas_transform().affine_inverse() * screen
