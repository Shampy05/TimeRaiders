extends KinematicBody2D

signal part_collected(part_type)

var number_sprites = 4
var part_type

# Called when the node enters the scene tree for the first time.
# By default, we choose a random sprite for each part.
func _ready():
	set_type(randi()%number_sprites, false)

# Set the machine part to use a specific sprite.
func set_type(type, as_inventory_icon):
	part_type = type+1
	$AnimatedSprite.animation = "Part"+str(part_type)
	
	if as_inventory_icon:
		# When using it as a sprite in the inventory, we want to use the default orientation for consistency.
		$AnimatedSprite.flip_h = false
		$AnimatedSprite.flip_v = false
		$AnimatedSprite.rotation_degrees = 0
		# And we want to disable the collision for safety.
		# (The player shouldn't ever be able to collide with the inventory, but just in case.)
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		
	else:
		# When using it as a collectable item, we want to include flipping and rotating for variety.
		$AnimatedSprite.flip_h = randf() < 0.5
		$AnimatedSprite.flip_v = randf() < 0.5
		$AnimatedSprite.rotation_degrees = (randi()%4)*90

func _on_Area2D_body_entered(body):
	# Any object (player, camera, guard or wall) can collide with the machine part.
	# So check if the body is a player specifically.
	if body.get_filename() == "res://Character.tscn":
		
		# Emit a signal to say that the part is collected, then delete the part object.
		emit_signal("part_collected", part_type)
		queue_free()
