extends KinematicBody2D

var stats = PlayerStats #PlayerStats is a global scene which can be called in anywhere

export var id = 0
export var speed = 250
var enable_cam_zoom = false
var velocity = Vector2()
var dir_anim = "Down"
var state_anim = "Stand"

func _input(event):
	if enable_cam_zoom:
		if event.is_action_pressed('plus'):
			$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
		if event.is_action_pressed('minus'):
			$Camera2D.zoom = $Camera2D.zoom + Vector2(0.1, 0.1)

func get_input():
	velocity = Vector2.ZERO
	if Input.is_action_pressed('ui_right'):
		velocity.x += 1
		dir_anim = "Right"
	if Input.is_action_pressed('ui_left'):
		velocity.x -= 1
		dir_anim = "Left"
	if Input.is_action_pressed('ui_up'):
		velocity.y -= 1
		dir_anim = "Up"
	if Input.is_action_pressed('ui_down'):
		velocity.y += 1
		dir_anim = "Down"
	velocity = velocity.normalized() * speed
	
	if velocity.length() > 0:
		state_anim = "Walk"
	else:
		state_anim = "Stand"
	$AnimatedSprite.animation = dir_anim+state_anim

func _physics_process(_delta):
	get_input()
	velocity = move_and_slide(velocity)

# When player enters a search light, their health will reduce
func _on_Hurtbox_area_entered(area):
	if area.get_filename() == "res://Hitbox.tscn":
		stats.health -= area.damage
