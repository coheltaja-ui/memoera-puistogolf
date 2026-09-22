extends RigidBody2D

func _ready():
	# Set gravity scale for the ball if you want it to fall naturally
	gravity_scale = 0  # Adjust as necessary to match your game's gravity
	
	# Makes the ball gradually lose momentum
	linear_damp = 0.5
	
func _on_Ball_body_entered(body):
	# Check if the body it collides with is the block
	if body.is_in_group("block"):  # Make sure to add the block to the "block" group in the editor
		# Handle collision event (e.g., change color or play a sound)
		print("Ball hit the block!")

func _on_Ball_area_entered(area):
	# You can also handle areas if necessary
	print("Ball entered area")
