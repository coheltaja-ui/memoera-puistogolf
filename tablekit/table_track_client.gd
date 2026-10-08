class_name TableTrackClient
extends Node
## Reads tabletrack pose lines from track.exe over TCP.
## Protocol: NDJSON on 127.0.0.1:8765 (see TABLETRACK.md).

signal hello_received(message: Dictionary)
signal frame_received(message: Dictionary)
signal error_received(message: Dictionary)
signal connection_changed(connected: bool)

const DEFAULT_HOST := "127.0.0.1"
const DEFAULT_PORT := 8765
const PROTOCOL := 1

@export var host := DEFAULT_HOST
@export var port := DEFAULT_PORT
@export var auto_connect := true
@export var auto_reconnect := true
@export var reconnect_seconds := 1.0
@export var launch_tracker := false
@export var tracker_path := ""
@export var token_keys := true

var connected: bool = false
var last_hello: Dictionary = {}
var last_frame: Dictionary = {}
var window_size := Vector2i(960, 640)

var _peer: StreamPeerTCP
var _buffer := ""
var _reconnect_left := 0.0
var _hands: Dictionary = {}
var _held := ""

static var shared_pid := -1


func _ready() -> void:
	if tracker_path.is_empty():
		tracker_path = find_tracker_binary()
	if launch_tracker:
		start_tracker()
	if auto_connect:
		connect_to_tracker()


func _exit_tree() -> void:
	disconnect_from_tracker()


func _process(delta: float) -> void:
	if _peer == null:
		if auto_reconnect:
			_tick_reconnect(delta)
		return

	_peer.poll()
	match _peer.get_status():
		StreamPeerTCP.STATUS_CONNECTED:
			if not connected:
				_peer.set_no_delay(true)
				_set_connected(true)
			_read_available()
		StreamPeerTCP.STATUS_CONNECTING:
			pass
		_:
			_drop_peer()
			if auto_reconnect:
				_tick_reconnect(delta)


static func tracker_binary_names() -> PackedStringArray:
	if OS.get_name() == "Windows":
		return PackedStringArray(["track.exe", "tabletrack-track.exe", "tabletrack.exe"])
	return PackedStringArray(["track", "tabletrack-track", "track.bin"])


static func tracker_search_roots() -> PackedStringArray:
	var roots := PackedStringArray()
	var seen: Dictionary = {}
	var add := func(path: String) -> void:
		if path.is_empty() or seen.has(path):
			return
		seen[path] = true
		roots.append(path)
	var exe_dir := OS.get_executable_path().get_base_dir()
	var res_dir := ProjectSettings.globalize_path("res://").trim_suffix("/")
	add.call(exe_dir)
	add.call(exe_dir.path_join("track"))
	add.call(res_dir.path_join("track"))
	add.call(res_dir.get_base_dir().path_join("track"))
	return roots


static func find_tracker_binary() -> String:
	var override := OS.get_environment("TABLETRACK_TRACKER")
	if not override.is_empty() and FileAccess.file_exists(override):
		return override
	var names := tracker_binary_names()
	for root in tracker_search_roots():
		for name in names:
			var path := root.path_join(name)
			if FileAccess.file_exists(path):
				return path
	return ""


static func default_tracker_path() -> String:
	return find_tracker_binary()


static func start_shared_tracker(port: int = DEFAULT_PORT) -> int:
	if shared_pid > 0 and OS.is_process_running(shared_pid):
		return shared_pid
	var path := find_tracker_binary()
	if path.is_empty():
		push_warning("TableTrackClient: tracker not found (looked in track/ next to the game)")
		return -1
	var dir := path.get_base_dir()
	var flags: Array = ["--port", str(port), "--tcp-only"]
	if OS.get_name() != "Windows" and FileAccess.file_exists("/usr/bin/env"):
		var env_args: Array = ["--chdir=" + dir, path]
		env_args.append_array(flags)
		shared_pid = OS.create_process("/usr/bin/env", env_args)
	else:
		# track.exe itself chdirs next to the binary so data/ and _internal resolve.
		shared_pid = OS.create_process(path, flags)
	if shared_pid <= 0:
		push_warning("TableTrackClient: could not start %s" % path)
	return shared_pid


static func stop_shared_tracker() -> void:
	if shared_pid > 0 and OS.is_process_running(shared_pid):
		OS.kill(shared_pid)
	shared_pid = -1


func connect_to_tracker() -> void:
	_drop_peer()
	_peer = StreamPeerTCP.new()
	var err := _peer.connect_to_host(host, port)
	if err != OK:
		_drop_peer()


func disconnect_from_tracker() -> void:
	auto_reconnect = false
	_drop_peer()


func start_tracker() -> int:
	if tracker_path.is_empty():
		tracker_path = find_tracker_binary()
	return start_shared_tracker(port)


func markers() -> Array:
	return pose_frame().get("markers", [])


func has_poses() -> bool:
	return connected or not _hands.is_empty()


func mouse_mode() -> bool:
	return not _hands.is_empty()


func held_block() -> String:
	return _held


func pose_frame() -> Dictionary:
	if _hands.is_empty():
		return last_frame
	var markers: Array = []
	var i := 0
	for block in ["a", "b", "c", "d", "e", "f", "g", "h"]:
		if not _hands.has(block):
			continue
		var hand: Dictionary = _hands[block]
		markers.append({
			"block": block,
			"value": i * 2,
			"nx": float(hand.get("nx", 0.5)),
			"ny": float(hand.get("ny", 0.5)),
			"rotation_deg": float(hand.get("rot", 0.0)),
			"held": block == _held,
		})
		i += 1
	return {
		"type": "frame",
		"protocol": PROTOCOL,
		"markers": markers,
		"window": [window_size.x, window_size.y],
	}


func _unhandled_input(event: InputEvent) -> void:
	if not token_keys:
		return
	if event is InputEventMouseMotion:
		_drag_held()
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var block := _block_for_key(event.physical_keycode)
	if block != "":
		_select_block(block)
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode == KEY_BACKSPACE or event.physical_keycode == KEY_DELETE:
		_drop_held()
		get_viewport().set_input_as_handled()


static func marker_key(marker: Dictionary) -> String:
	var block: Variant = marker.get("block")
	if block != null and str(block) != "":
		return "block:%s" % str(block)
	return "id:%s" % str(int(marker.get("value", -1)))


static func marker_position(marker: Dictionary, size: Vector2) -> Vector2:
	if marker.has("nx") and marker.has("ny"):
		return Vector2(float(marker["nx"]) * size.x, float(marker["ny"]) * size.y)
	return Vector2(float(marker.get("sx", 0.0)), float(marker.get("sy", 0.0)))


func _block_for_key(code: int) -> String:
	match code:
		KEY_1, KEY_KP_1:
			return "a"
		KEY_2, KEY_KP_2:
			return "b"
		KEY_3, KEY_KP_3:
			return "c"
		KEY_4, KEY_KP_4:
			return "d"
		KEY_5, KEY_KP_5:
			return "e"
		KEY_6, KEY_KP_6:
			return "f"
		KEY_7, KEY_KP_7:
			return "g"
		KEY_8, KEY_KP_8:
			return "h"
		_:
			return ""


func _select_block(block: String) -> void:
	_held = block
	if _hands.has(block):
		return
	var at := _mouse_nx_ny()
	_hands[block] = {"nx": at.x, "ny": at.y, "rot": 0.0}


func _drop_held() -> void:
	if _held == "":
		return
	_hands.erase(_held)
	_held = ""


func _drag_held() -> void:
	if _held == "" or not _hands.has(_held):
		return
	var at := _mouse_nx_ny()
	var hand: Dictionary = _hands[_held]
	hand["nx"] = at.x
	hand["ny"] = at.y
	_hands[_held] = hand


func _mouse_nx_ny() -> Vector2:
	var pos := get_viewport().get_mouse_position()
	# Use the game's own view size so the simulated block lands under the mouse.
	var size := get_viewport().get_visible_rect().size
	if size.x < 1.0 or size.y < 1.0:
		size = Vector2(960, 640)
	return Vector2(clampf(pos.x / size.x, 0.0, 1.0), clampf(pos.y / size.y, 0.0, 1.0))


func _tick_reconnect(delta: float) -> void:
	_reconnect_left -= delta
	if _reconnect_left > 0.0:
		return
	_reconnect_left = reconnect_seconds
	connect_to_tracker()


func _read_available() -> void:
	var available := _peer.get_available_bytes()
	if available <= 0:
		return
	var chunk := _peer.get_utf8_string(available)
	if chunk.is_empty():
		return
	_buffer += chunk
	# Drain the socket, but only emit the newest pose. Extra lines are stale
	# camera frames; a game should render the latest, not catch up.
	var latest_frame: Dictionary = {}
	var got_frame := false
	while true:
		var newline := _buffer.find("\n")
		if newline < 0:
			break
		var line := _buffer.substr(0, newline).strip_edges()
		_buffer = _buffer.substr(newline + 1)
		if line.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var message: Dictionary = parsed
		match str(message.get("type", "")):
			"hello":
				_apply_window(message)
				last_hello = message
				hello_received.emit(message)
			"frame":
				latest_frame = message
				got_frame = true
			"error":
				error_received.emit(message)
				push_warning("TableTrackClient: %s" % str(message.get("message", "unknown error")))
	if got_frame:
		_apply_window(latest_frame)
		last_frame = latest_frame
		frame_received.emit(latest_frame)


func _apply_window(message: Dictionary) -> void:
	var win: Variant = message.get("window")
	if win is Array and win.size() >= 2:
		window_size = Vector2i(int(win[0]), int(win[1]))


func _drop_peer() -> void:
	if _peer != null:
		_peer.disconnect_from_host()
	_peer = null
	_buffer = ""
	if connected:
		_set_connected(false)


func _set_connected(value: bool) -> void:
	if connected == value:
		return
	connected = value
	if not value:
		last_frame = {}
	connection_changed.emit(value)
