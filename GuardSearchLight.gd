extends Node2D

# Negative means anticlockwise rotation
var degrees_per_second = -360/15

func _process(delta):
	rotate(delta * deg2rad(degrees_per_second))
