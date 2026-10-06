extends Node
## Starts track.exe once for the whole app.

var started := false
var path := ""
var skipped := false


func _ready() -> void:
	if _should_skip():
		skipped = true
		return
	_boot()


func _boot() -> void:
	if await _port_open():
		started = true
		path = "(already listening)"
		return
	path = TableTrackClient.find_tracker_binary()
	if path.is_empty():
		push_warning("TrackerBoot: no tracker binary. Put track/ next to the game (with data/calibration).")
		return
	var pid := TableTrackClient.start_shared_tracker()
	started = pid > 0
	if started:
		print("TrackerBoot: started %s pid=%s" % [path, pid])


func _exit_tree() -> void:
	_stop()


func _stop() -> void:
	if skipped:
		return
	TableTrackClient.stop_shared_tracker()
	started = false


func _should_skip() -> bool:
	if OS.get_environment("TABLETRACK_SCREENSHOT") == "1":
		return true
	if OS.get_environment("TABLETRACK_NO_TRACKER") == "1":
		return true
	if OS.get_environment("TABLETRACK_SMOKE") == "1":
		return true
	return false


func _port_open() -> bool:
	var peer := StreamPeerTCP.new()
	if peer.connect_to_host("127.0.0.1", TableTrackClient.DEFAULT_PORT) != OK:
		return false
	for _i in 12:
		peer.poll()
		match peer.get_status():
			StreamPeerTCP.STATUS_CONNECTED:
				peer.disconnect_from_host()
				return true
			StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE:
				peer.disconnect_from_host()
				return false
			_:
				await get_tree().create_timer(0.04).timeout
	peer.disconnect_from_host()
	return false
