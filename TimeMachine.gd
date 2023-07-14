extends KinematicBody2D

signal game_win

var inventory

func _process(_delta):
	# Update the sprite when the player collects all of the parts.
	$AnimatedSprite.animation = "Full" if inventory.complete else "Broken"

# To check if the player has collected all of the parts, we need to pass in a reference to the inventory.
func inventory_reference(reference):
	inventory = reference

func _on_Area2D_body_entered(body):
	# Any object (player, camera, guard or wall) can collide with the time machine.
	# So check if the body is a player specifically.
	if body.get_filename() == "res://Character.tscn":
		
		# If the player has collected all of the parts, then end the game.
		# Otherwise, display an error message from the time machine.
		if inventory.complete:
			emit_signal("game_win")
		else:
			$Label.visible = true

func _on_Area2D_body_exited(body):
	# Any object (player, camera, guard or wall) can collide with the time machine.
	# So check if the body is a player specifically.
	if body.get_filename() == "res://Character.tscn":
		
		# Hide the error message when the player leaves.
		$Label.visible = false
