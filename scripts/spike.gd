extends RigidBody2D

func _on_body_entered(body: Node) -> void:
	# Checks if the rigid body collided with your player node
	if body.name == "EpicPlayer":
		get_tree().call_deferred("reload_current_scene")
