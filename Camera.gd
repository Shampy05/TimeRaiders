extends Node2D

# Positive means clockwise rotation
var degrees_per_second = 360/5

func _process(delta):
	rotate(delta * deg2rad(degrees_per_second))
