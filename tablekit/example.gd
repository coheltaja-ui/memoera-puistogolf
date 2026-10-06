extends Node2D
## Block A on the table moves the Block node.

@onready var client: TableTrackClient = $TableTrackClient
@onready var block: Node2D = $Block


func _ready() -> void:
	block.visible = false


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
