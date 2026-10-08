extends RigidBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0  # ✅ Disable gravity so player doesn't fall

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass # Add your movement logic here
