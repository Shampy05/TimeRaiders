extends RigidBody2D

var size
var min_dist_too_close
var size_small_room

func make_room(_pos, _size, _too_close, _small_room):
	position = _pos
	size = _size
	var s = RectangleShape2D.new()
	s.custom_solver_bias = 0.75
	s.extents = size
	$CollisionShape2D.shape = s
	min_dist_too_close = _too_close
	size_small_room = _small_room

func rand_pos():
	return Vector2(position.x + rand_range(-size.x+min_dist_too_close, size.x-min_dist_too_close),
		position.y + rand_range(-size.y+min_dist_too_close, size.y-min_dist_too_close))

func is_small_room():
	return size.x <= size_small_room and size.y <= size_small_room
