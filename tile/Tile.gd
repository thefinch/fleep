extends Node3D

var top
var bottom
var current_side = 'top'
var mouse_over = false
var selected = false

# keep track of how this tile can move
var draggable = true
var being_dragged = false
var original_position = null
var can_rotate = true
var flip_factor = 1

# Called when the node enters the scene tree for the first time.
func _ready():	
	# create the tile sides
	top = create_tile_side()
	bottom = create_tile_side()
	top = ['UL', 'R']
	bottom = ['UL', 'R']
	
	# show the arrows based on what we made
	show_arrows(top, 'Front')
	show_arrows(bottom, 'Back')
	
	test()
	
	bottom = change_matrix(bottom, 'vertical')

func test():
	top = ["UL", "R"]
	bottom = change_matrix(top, 'vertical')
	
	var movements = [
		{
			'func': self.down,
			'action': 'down',
			'expected': {
				'top' : ['DL', 'R'],
				'bottom' : ['UL', 'R'],
				'side': 'bottom'
			},
		},
		{
			'func': self.up_left,
			'action': 'up_left',
			'expected': {
				'top' : ['DL', 'U'],
				'bottom' : ['DR', 'U'],
				'side': 'top'
			},
		}
	]
	for movement in movements:
		prints('top before', top)
		prints('bottom before', bottom)
		prints('current side before', current_side)
		prints('action will be', movement['action'])
		movement['func'].call()
		prints('top after', top, 'should be', movement['expected']['top'])
		prints('bottom after', bottom, 'should be', movement['expected']['bottom'])
		prints('current side is', current_side, 'and should be', movement['expected']['side'])
		print('')
	
#	down()
#	print(top, bottom, current_side)
#	up_left()
#	print(top, bottom, current_side)
#	left()
#	print(top, bottom, current_side)
#	rotate_left()
#	print(top, bottom, current_side)
#	down_right()
#	print(top, bottom, current_side)
#	up()
#	print(top, bottom, current_side)
#	right()
#	print(top, bottom, current_side)
#	up_right()
#	print(top, bottom, current_side)
#	down_left()
#	print(top, bottom, current_side)
#	rotate_right()
#	print(top, bottom, current_side)

# shows all visible arrows on the given side
func show_arrows(directions, side):
	for direction in directions:
		get_node(side + '/' + direction).visible = true

# generates a random list of arrows for a side
func create_tile_side():	
	# set all the possible places an arrow can go
	var possible_directions = [
		'UL', 'U', 'UR',
		'L', 'R',
		'DL', 'D', 'DR',
	]
	
	# set which directions should be removed when a particular direction is added
	var removals = {
		'UL': ['L', 'U'],
		'U': ['UL', 'UR'],
		'UR': ['U', 'R'],
		'L': ['UL', 'DL'],
		'R': ['UR', 'DR'],
		'DL': ['L', 'D'],
		'D': ['DL', 'DR'],
		'DR': ['R', 'D'],
	}
	
	# add an arrow
	var arrows = []
	arrows.append(
		possible_directions[randi() % possible_directions.size()]
	)
	
	# remove impossible adjacent arrows
	for removal in removals[arrows[0]]:
		possible_directions.erase(removal)

	# remove the currently used arrow
	possible_directions.erase(arrows[0])

	# add a new arrow
	arrows.append(
		possible_directions[randi() % possible_directions.size()]
	)

	return arrows

# returns which side is currently visible
func get_current_side():
	return current_side

# spin the tile in 3D and rotate the matrixes appropriately
func spin(list):
	# rotate the matrices
	top = rotate_matrix(top, list)
	bottom = rotate_matrix(bottom, list)
	
	# spin the object
	rotate_tile(list)
	
	# update the side
	for axis in list:
		if axis == 'y' or axis == 'x':
			current_side = 'top' if current_side == 'bottom' else 'bottom'
			break

# rotates a tile a certain amount of degrees on the given axis
func rotate_tile(list):
	# don't try to rotate if we're already rotating
	if not can_rotate:
		return 
	can_rotate = false
	
	# create the tween
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# do all our work at once
	var duration = 0.3
	var radians
	var start_rotation
	var degrees
	for axis in list:
		# flip rotations if needed
		if axis == 'x' or axis == 'y':
			flip_factor = flip_factor * -1
		
		# figure out how much to rotate and how long the rotation should last
		degrees = list[axis]
		match axis:
			'x':
				start_rotation = self.rotation.x
			'y':
				start_rotation = self.rotation.y
			'z':
				degrees = degrees * flip_factor
				start_rotation = self.rotation.z
		radians = start_rotation + deg_to_rad(degrees)
				
		tween.tween_property(self, "rotation:" + axis, radians, duration)

	# allow rotation after this one is done
	await tween.finished
	can_rotate = true

func rotate_matrix(matrix, list):
	var degrees
	
	# rotate on each axis
	for axis in list:
		degrees = list[axis]

		if axis == 'z':
			if degrees == -90:
				matrix = change_matrix(matrix, 'left')
			elif degrees == 90:
				matrix = change_matrix(matrix, 'right')
		elif axis == 'y':
			matrix = change_matrix(matrix, 'horizontal')
		elif axis == 'x':
			matrix = change_matrix(matrix, 'vertical')
		
	return matrix

func change_matrix(arrows, change):
	var swap = {
		'horizontal': {
			'UL': 'UR',
			'UR': 'UL',
			'L': 'R',
			'R': 'L',
			'DL': 'DR',
			'DR': 'DL',
		},
		'vertical': {
			'UL': 'DL',
			'U': 'D',
			'UR': 'DR',
			'DL': 'UL',
			'D': 'U',
			'DR': 'UR',
		},
		'left': {
			'UR': 'UL',
			'R': 'U',
			'DR': 'UR',
			'D': 'R',
			'DL': 'DR',
			'L': 'D',
			'UL': 'DL',
			'U': 'L',
		},
		'right': {
			'UL': 'UR',
			'UR': 'DR',
			'DR': 'DL',
			'DL': 'UL',
			'R': 'D',
			'U': 'R',
			'D': 'L',
			'L': 'U',
		},
		'down-left': {
			'R': 'D',
			'L': 'U',
			'U': 'L',
			'D': 'R',
			'DL': 'UR',
			'UR': 'DL',
		},
		'up-left': {
			'UR': 'DL',
			'DL': 'UR',
			'L': 'U',
			'D': 'R',
			'R': 'D',
			'U': 'L'
		}
	}
	
	var new_arrows = []
	for arrow in arrows:
		new_arrows.append(
			swap[change][arrow] if arrow in swap[change] else arrow
		)

	return new_arrows
	
func turn(arrows, direction):
	var new_arrows = []

	var swap_right = {
		'UL': 'UR',
		'U': 'R',
		'UR': 'DR',
		'R': 'D',
		'DR': 'DL',
		'D': 'L',
		'DL': 'UL',
		'L': 'U',
	}
	var swap_left = {
		'UR': 'UL',
		'R': 'U',
		'DR': 'UR',
		'D': 'R',
		'DL': 'DR',
		'L': 'D',
		'UL': 'DL',
		'U': 'L',
	}

	var swap = swap_right if direction == 'right' else swap_left
	for arrow in arrows:
		new_arrows.append(
			swap[arrow] if arrow in swap else arrow
		)

	return new_arrows
	
# begin dragging the tile
func pick_up():
	original_position = self.global_position
	being_dragged = true

# moves the tile to wherever the mouse is
func drag(event):
	face_camera(event.position, 7)

# send back to original location
func revert_position():
	var duration = 0.2
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", original_position, duration)

# set this tile as being hovered over when the mouse enters its Area3D
func _on_area_3d_mouse_entered():
	mouse_over = true

# set this tile as not being hovered over when the mouse leaves its Area3D
func _on_area_3d_mouse_exited():
	mouse_over = false

# puts the tile at a position
func place_at(new_position):
	# make sure we can't drag this one again
	draggable = false
	
	# put the tile in the box
	var duration = 0.05
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", new_position, duration)
	await(tween.finished)
	
	# make it look at the camera
	var camera = get_viewport().get_camera_3d()
	var screen_position = camera.unproject_position(global_position)
	face_camera(screen_position, 8)

# makes the tile look at the camera
func face_camera(origin, distance_from_camera):
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(origin)
	var to = from + camera.project_ray_normal(origin) * distance_from_camera
	global_transform.origin = to

# spins this tile diagonally up and left
func up_left():
	spin({
		'y' : -180,
		'z' : -90
	})

# spins this tile diagonally up and right
func up_right():
	spin({
		'y' : 180,
		'z' : 90
	})

# spins this tile up
func up():
	spin({'x': -180})

# spins this tile down
func down():
	spin({'x': 180})

# spins this tile left
func left():
	spin({'y': -180})

# spins this tile left
func right():
	spin({'y': 180})

# spins this tile diagonally down and left
func down_left():
	spin({
		'y' : -180,
		'z' : 90
	})

# spins this tile diagonally down and right
func down_right():
	spin({
		'y' : 180,
		'z' : -90
	})

# rotates this tile left
func rotate_left():
	spin({'z' : -90})

# rotates this tile right
func rotate_right():
	spin({'z' : 90})
