# Table kit

Godot side of the pose stream. Copy this folder into a Godot 4 project as `res://tablekit/`.

```text
tablekit/tracker_boot.gd         starts track.exe when the port is free
tablekit/table_track_client.gd   connects and parses the stream
tablekit/example.tscn            block A moves one node (open this and press Play)
```

`track.exe` sends one JSON line per camera frame on TCP. The client keeps the newest line. A game reads that dictionary and moves its own nodes.

## Track.exe

The tracker folder stays whole. `track.exe`, `_internal/`, and `data/` sit together. The exe reads calibration from beside itself.

**Godot starts it.** Add one autoload (Project → Project Settings → Autoload, or `project.godot`):

```ini
[autoload]

TrackerBoot="*res://tablekit/tracker_boot.gd"
```

On launch it checks `127.0.0.1:8765`. If nothing is listening, it starts the first binary it finds, with `--port 8765 --tcp-only`. On Windows the names are `track.exe`, `tabletrack-track.exe`, and `tabletrack.exe`.

Put `track/` in one of these places.

Playing from the editor:

```text
your-project/track/track.exe
your-project/tablekit/
```

```text
track/track.exe
your-project/tablekit/
```

Exported game:

```text
game.exe
track/track.exe
track/_internal/
track/data/
```

`track.exe` may also sit in the same folder as `game.exe`.

If the exe lives somewhere else and Godot should start that file, set `TABLETRACK_TRACKER` to its full path before launching the game.

**Godot only listens.** Start `track.exe` yourself (any folder) so it is already serving `127.0.0.1:8765`. Leave the autoload out. The client connects to that process and does not launch another one.

If the running tracker uses another address, select the `TableTrackClient` node and set its `host` and `port`.

## Wire a scene

Add a child node. Attach `table_track_client.gd`. Name it `TableTrackClient`.

`auto_connect` is on, so the node opens `127.0.0.1:8765` by itself and tries again about once a second if the socket drops.

## Example

Open `res://tablekit/example.tscn` and run that scene. Show block A. The colored shape follows it and turns with it. Cover the block and the shape hides.

The scene script is the whole pattern:

```gdscript
extends Node2D

@onready var client: TableTrackClient = $TableTrackClient
@onready var block: Node2D = $Block

func _process(_delta: float) -> void:
	var frame := client.pose_frame()
	var view := get_viewport_rect().size
	block.visible = false
	if frame.is_empty():
		return
	for raw in frame.get("markers", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var marker: Dictionary = raw
		if str(marker.get("block", "")) != "a":
			continue
		block.visible = true
		block.position = TableTrackClient.marker_position(marker, view)
		block.rotation_degrees = float(marker.get("rotation_deg", 0.0))
		return
```

Change `"a"` to `"b"` … `"h"` to follow a different block. Use the same loop for several nodes, one letter each.

A frame looks like this. `nx` and `ny` are 0–1 across the view. `rotation_deg` 0 points right. The tracker window is 960×640.

```json
{
  "type": "frame",
  "window": [960, 640],
  "markers": [{ "block": "a", "nx": 0.42, "ny": 0.31, "rotation_deg": 8.0 }]
}
```

The same messages are signals on the client: `hello_received`, `frame_received`, `error_received`, `connection_changed`.

Without a camera, keys `1`–`8` place blocks A–H, the mouse moves the selected one, and Backspace removes it.
