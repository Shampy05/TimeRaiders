extends Node2D

var Room = preload("res://Room.tscn")
var Part = preload("res://MachinePart.tscn")
var Player = preload("res://Character.tscn")
var Guard = preload("res://Guard.tscn")
var Inventory = preload("res://Inventory.tscn")
var Machine = preload("res://TimeMachine.tscn")
var Camera = preload("res://Camera.tscn")
var GameOverScreen = preload("res://GameOverScreen.tscn")
var EndingScreen = preload("res://EndingScreen.tscn")
var PauseScreen = preload("res://PauseScreen.tscn")
var font = preload("res://assets/RobotoBold120.tres")
onready var Map = $TileMap
var stats = PlayerStats

var tile_size = 16  # size of a tile in the TileMap
var num_rooms = 50  # number of rooms to generate
var min_size = 6  # minimum room size (in tiles)
var max_size = 15  # maximum room size (in tiles)
var hspread = 400  # horizontal spread (in pixels)
var cull = 0.75  # chance to cull room
var number_part_sprites = 4 # Amount of machine part sprites
var number_parts = 20 # Number of machine parts
var size_small_room = 8*tile_size # Rooms of this size have fewer guards and cameras
var spawn_attempts = 10 # How many attempts made to spawn an object before giving up
var show_generation = false # Show the dungeon generation over the loading screen
var min_dist_too_close = 2.5*tile_size # Minimum distance between objects

var path  # AStar pathfinding object
var start_room = null
var end_room = null
var play_mode = false  
var player = null
var guards = null
onready var screen_size = get_viewport().get_visible_rect().size
var spawnlocs = []

func _ready():
	randomize()
	stats.connect("no_health",self,"handle_player_loss")
	generate_dungeon()

func _draw():
	$HealthLayer.visible = play_mode
	$LoadingLayer.visible = !play_mode
	if show_generation and !play_mode:
		for room in $Rooms.get_children():
			draw_rect(Rect2(room.position - room.size, room.size * 2),
				Color(0, 1, 0), false)
		if path:
			for p in path.get_points():
				for c in path.get_point_connections(p):
					var pp = path.get_point_position(p)
					var cp = path.get_point_position(c)
					draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y),
						Color(1, 1, 0), 15, true)

func _process(_delta):
	update()

func generate_dungeon():
	# Start by clearing any previous data
	if play_mode:
		player.queue_free()
		play_mode = false
	for n in $Rooms.get_children():
		n.queue_free()
	path = null
	start_room = null
	end_room = null
	
	# Spawn the rooms (with a delay after, to match the delay within the generate_rooms function)
	generate_rooms()
	yield(get_tree().create_timer(1.2), "timeout")
	
	# Turn the rooms into a tilemap
	generate_map()
	
	# Add all of the objects to the dungeon
	generate_objects()
	
	# Start the game
	play_mode = true
	
func generate_rooms():
	for _i in range(num_rooms):
		var pos = Vector2(rand_range(-hspread, hspread), 0)
		var r = Room.instance()
		var w = min_size + randi() % (max_size - min_size)
		var h = min_size + randi() % (max_size - min_size)
		r.make_room(pos, Vector2(w, h) * tile_size, min_dist_too_close, size_small_room)
		$Rooms.add_child(r)
	# wait for movement to stop
	yield(get_tree().create_timer(1.1), 'timeout')
	# cull rooms
	var room_positions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			room_positions.append(Vector3(room.position.x,
										  room.position.y, 0))
	yield(get_tree(), 'idle_frame')
	# generate a minimum spanning tree connecting the rooms
	generate_rooms_find_mst(room_positions)

func generate_rooms_find_mst(nodes):
	# Prim's algorithm
	# Given an array of positions (nodes), generates a minimum
	# spanning tree
	# Returns an AStar object
	
	# Initialize the AStar and add the first point
	path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# Repeat until no more nodes remain
	while nodes:
		var min_dist = INF  # Minimum distance so far
		var min_p = null  # Position of that node
		var p = null  # Current position
		# Loop through points in path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			# Loop through the remaining nodes
			for p2 in nodes:
				# If the node is closer, make it the closest
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		# Insert the resulting node into the path and add
		# its connection
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		# Remove the node from the array so it isn't visited again
		nodes.erase(min_p)
		
func generate_map():
	# Create a TileMap from the generated rooms and path
	Map.clear()
	generate_map_find_start()
	generate_map_find_end()
	
	# Fill TileMap with walls, then carve empty rooms
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var r = Rect2(room.position-room.size,
					room.get_node("CollisionShape2D").shape.extents*2)
		full_rect = full_rect.merge(r)
	var topleft = Map.world_to_map(full_rect.position)
	var bottomright = Map.world_to_map(full_rect.end)
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			Map.set_cell(x, y, 1)	
	
	# Carve rooms
	var corridors = []  # One corridor per connection
	for room in $Rooms.get_children():
		var s = (room.size / tile_size).floor()
		var _pos = Map.world_to_map(room.position)
		var ul = (room.position / tile_size).floor() - s
		for x in range(2, s.x * 2 - 1):
			for y in range(2, s.y * 2 - 1):
				Map.set_cell(ul.x + x, ul.y + y, 0)

		# Carve connecting corridor
		var p = path.get_closest_point(Vector3(room.position.x, 
											room.position.y, 0))
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = Map.world_to_map(Vector2(path.get_point_position(p).x,
													path.get_point_position(p).y))
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x,
													path.get_point_position(conn).y))									
				generate_map_carve_path(start, end)
		corridors.append(p)

	# The code above decides whether each tile should be a floor or a wall.
	# Now decide what type of wall sprite each wall tile should use.
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			if Map.get_cell(x, y) > 0: Map.set_cell(x, y, generate_map_walls(x, y))

func generate_map_find_start():
	var min_x = INF
	for room in $Rooms.get_children():
		if room.position.x < min_x:
			start_room = room
			min_x = room.position.x

func generate_map_find_end():
	var max_x = -INF
	for room in $Rooms.get_children():
		if room.position.x > max_x:
			end_room = room
			max_x = room.position.x

func generate_map_carve_path(pos1, pos2):
	# Carve a path between two points
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
	# choose either x/y or y/x
	var x_y = pos1
	var y_x = pos2
	if (randi() % 2) > 0:
		x_y = pos2
		y_x = pos1
	for x in range(pos1.x, pos2.x, x_diff):
		Map.set_cell(x, x_y.y, 0)
		Map.set_cell(x, x_y.y + y_diff, 0)  # widen the corridor
	for y in range(pos1.y, pos2.y, y_diff):
		Map.set_cell(y_x.x, y, 0)
		Map.set_cell(y_x.x + x_diff, y, 0)

func generate_map_walls(x, y):
	# Let (x, y) be the cell *, and label the cell's neighbours as follows:
	#   d n a
	#   w * e
	#   c s b
	# Let the value of each letter be 1 if the corresponding cell is any Boundary, or 0 if it is a Floor.
	# If * is a Boundary, then which tile to use for it depends on the values of the 8 neighbours.
	
	# Let n/e/s/w represent the calue of the north/east/south/west neighbour respectively.
	var n = 0 if (Map.get_cell(x, y-1) == 0) else 8
	var e = 0 if (Map.get_cell(x+1, y) == 0) else 4
	var s = 0 if (Map.get_cell(x, y+1) == 0) else 2
	var w = 0 if (Map.get_cell(x-1, y) == 0) else 1
	
	# Pack them into a 4-bit number "nesw", and consider the possible cases.
	match n+e+s+w:
		
		# If surrounded by 4 boundaries, then we need more information so jump to the end of this section.
		15:
			pass
			
		# If surrounded by 3 boundaries, then this is a wall so use the corresponding Wall tile.
		13:
			return 2 # WallNorth
		14:
			return 3 # WallEast
		7:
			return 4 # WallSouth
		11:
			return 5 # WallWest
			
		# If surrounded by 2 boundaries that are next to each other, then this is an outside corner so use the corresponding CornerOut tile.
		12:
			return 6 # CornerOutNorthEast
		6:
			return 7 # CornerOutSouthEast
		3:
			return 8 # CornerOutSouthWest
		9:
			return 9 # CornerOutNorthWest
		
		# If surrounded by 2 boundaries that are opposite each other, then this is a thin wall so use the corresponding WallThin tile.
		5:
			return 14 # WallThinHoriz
		10:
			return 15 # WallThinVert
		
		# If surrounded by 1 boundary, then this is a thin corner so use the corresponding CornerThin tile.
		2:
			return 16 # CornerThinNorth
		1:
			return 17 # CornerThinEast
		8:
			return 18 # CornerThinSouth
		4:
			return 19 # CornerThinWest
			
		# If surrounded by 0 boundaries (case 0), then this is an invalid case (it should not happen) so default to the basic Boundary tile if it does.
		_:
			return 1 # Boundary
			
	# If we reach this point, then we are surrounded by 4 boundaries in the cardinal directions so now consider the diagonals.
	# Let a/b/c/d represent the calue of the northeast/southeast/southwest/northwest neighbour respectively.
	var a = 0 if (Map.get_cell(x+1, y-1) == 0) else 8
	var b = 0 if (Map.get_cell(x+1, y+1) == 0) else 4
	var c = 0 if (Map.get_cell(x-1, y+1) == 0) else 2
	var d = 0 if (Map.get_cell(x-1, y-1) == 0) else 1
	
	# Pack them into a 4-bit number "abcd", and consider the possible cases.
	match a+b+c+d:
		
		# If surrounded by 4 boundaries, then this is outside the bounds of the dungeon so use the basic Boundary tile.
		15:
			return 1 # Boundary
		
		# If surrounded by 3 boundaries, then this is an inside corner so use the corresponding CornerIn tile.
		13:
			return 10 # CornerInNorthEast
		14:
			return 11 # CornerInSouthEast
		7:
			return 12 # CornerInSouthWest
		11:
			return 13 # CornerInNorthWest
		
		# If surrounded by any other combination, then this is an invalid case (it should not happen) so default to the basic Boundary tile if it does.
		_:
			return 1 # Boundary

func generate_objects():
	# Spawn the inventory HUD
	var inventory = Inventory.instance()
	add_child(inventory)
	
	# Create a list of spawnable rooms (i.e. all rooms except the start & end)
	var spawnable_rooms = $Rooms.get_children()
	spawnable_rooms.erase(start_room)
	spawnable_rooms.erase(end_room)
	
	# Spawn machine parts, in a fixed amount for the whole dungeon
	for _i in range(number_parts):
		var cur_room = spawnable_rooms[randi() % spawnable_rooms.size()]
		var part = generate_objects_spawn(Part, cur_room)
		if part != null:
			$MachineParts.add_child(part)
			part.connect("part_collected", inventory, "_on_MachinePart_part_collected")
	var parts = $MachineParts.get_children();
	for i in range(min(number_part_sprites, parts.size())):
		parts[i].set_type(i, false)
	inventory.register_parts(parts)
	
	# Spawn enemies, in a random amount per room (exactly 1 if small, 1 to 4 inclusive if big)
	for room in spawnable_rooms:
		# Spawn guards
		var number_guards = 1 if room.is_small_room() else (1 + (randi() % 4))
		for _i in range(number_guards):
			var guard = generate_objects_spawn(Guard, room)
			if guard != null:
				add_child(guard)
				
		# Spawn cameras
		var number_cams = 1 if room.is_small_room() else (1 + (randi() % 4))
		for _i in range(number_cams):
			var cam = generate_objects_spawn(Camera, room)
			if cam != null:
				add_child(cam)
				
	# Spawn the time machine
	var machine = Machine.instance()
	add_child(machine)
	machine.position = end_room.position
	machine.inventory_reference(inventory)
	machine.connect("game_win",self,"handle_game_win")
	
	# Spawn the player
	player = Player.instance()
	add_child(player)
	player.position = start_room.position

func generate_objects_spawn(Scene, room):
	for _i in range(spawn_attempts):
		var pos = room.rand_pos()
		if !generate_objects_distance_check(pos):
			spawnlocs.append(pos)
			var obj = Scene.instance()
			obj.position = pos
			return obj
	return null

func generate_objects_distance_check(pos):
	for loc in spawnlocs:
		if pos.distance_to(loc) < min_dist_too_close:
			return true
	return false

# creates a GameOverScreen instance and adds it to Main
func handle_player_loss():
	var game_over = GameOverScreen.instance()
	add_child(game_over)

# creates an EndingScreen instance and adds it to Main
func handle_game_win():
	var ending = EndingScreen.instance()
	add_child(ending)

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		var pause_menu = PauseScreen.instance()
		add_child(pause_menu)
