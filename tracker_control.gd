extends Node

const BLOCK_LETTER := "a"    # letter of your physical block
const FOLLOW_SPEED := 12.0   # higher = the block catches up faster
const MAX_SPEED := 1800.0    # pixels per second, limits how hard it can hit

@onready var client: TableTrackClient = $"../TableTrackClient"
var body: RigidBody2D
var wanted: Vector2
var has_target := false
var printed_target := false

func _ready() -> void:
	var holder := get_tree().current_scene.find_child("PlayerBlock", true, false)
	if holder == null:
		push_warning("TrackerControl: no node named PlayerBlock found")
		return
	body = holder as RigidBody2D
	if body == null:
		body = holder.find_child("RigidBody2D", true, false) as RigidBody2D
	if body == null:
		push_warning("TrackerControl: no RigidBody2D inside PlayerBlock")
		return
	body.gravity_scale = 0.0
	body.lock_rotation = true
	body.can_sleep = false
	body.linear_damp = 0.0
	print("TrackerControl ready, body = ", body)

func _process(_delta: float) -> void:
	has_target = false
	if body == null:
		return
	var frame := client.pose_frame()
	if frame.is_empty():
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	for raw in frame.get("markers", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var marker: Dictionary = raw
		if str(marker.get("block", "")) != BLOCK_LETTER:
			continue
		wanted = TableTrackClient.marker_position(marker, view)
		has_target = true
		if not printed_target:
			print("TrackerControl: block A seen at ", wanted)
			printed_target = true
		return

func _physics_process(_delta: float) -> void:
	if body == null:
		return
	if not has_target:
		body.linear_velocity = Vector2.ZERO
		return
	var velocity := (wanted - body.global_position) * FOLLOW_SPEED
	body.linear_velocity = velocity.limit_length(MAX_SPEED)
