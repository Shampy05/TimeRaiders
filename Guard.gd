extends KinematicBody2D

export var speed = 50
export var direction = -1
var velocity = Vector2.ZERO
var move_vertical

func _ready():
	move_vertical = randf()<0.5
	
func _physics_process(_delta):
	if is_on_wall():
		direction *= -1
	
	var vel = speed * direction
	velocity = Vector2(0 if move_vertical else vel, vel if move_vertical else 0)
	velocity = move_and_slide(velocity)
	
	if move_vertical:
		$Sprite.animation = ("Down" if direction == 1 else "Up")+"Walk"
	else:
		$Sprite.animation = ("Right" if direction == 1 else "Left")+"Walk"
